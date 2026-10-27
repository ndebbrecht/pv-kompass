import Foundation
import CoreMotion
import CoreLocation
import UIKit

@MainActor final class SensorService: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    enum Phase: Equatable { case ready, preparing, measuring, finished, failed }
    @Published private(set) var phase: Phase = .ready
    @Published private(set) var status = "Bereit für deine erste Messung."
    @Published private(set) var progress: Double = 0
    @Published private(set) var latestTilt: Double?
    @Published private(set) var latestAzimuth: Double?
    @Published private(set) var result: PanelMeasurement?
    @Published private(set) var reference: NorthReference = .magnetic
    @Published private(set) var locationStatus = "Standort wird erst beim Start angefragt."
    @Published private(set) var error: String?
    private let motion = CMMotionManager()
    private let location = CLLocationManager()
    private var heading: CLHeading?
    private var position: CLLocation?
    private var window = SampleWindow()
    private var startedAt = Date()
    private var timer: Timer?
    private var lastAnnouncement = Date.distantPast
    private var lastPublished = Date.distantPast
    private var invalidSince: Date?
    private var onComplete: ((PanelMeasurement) -> Void)?
    private var totalSamples = 0
    private var usingDemo = false
    private var startGate = MeasurementStartGate()
    private var delayedStartAnnouncement: Task<Void, Never>?
    #if targetEnvironment(simulator)
    private var demoPermissionTimer: Timer?
    #endif

    override init() {
        super.init()
        location.delegate = self
        location.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        location.headingFilter = 1
    }
    func start(onComplete: @escaping (PanelMeasurement) -> Void) {
        stopSensors()
        result = nil; error = nil; progress = 0; latestTilt = nil; latestAzimuth = nil
        position = nil; heading = nil; reference = .magnetic
        window = SampleWindow(); totalSamples = 0; invalidSince = nil
        self.onComplete = onComplete; phase = .preparing
        status = "Messung wird vorbereitet."
        startGate.permission = .undecided
        UIApplication.shared.isIdleTimerDisabled = true
        #if targetEnvironment(simulator)
        // Explicit simulator-only fixtures, never enabled on a physical iPhone.
        usingDemo = ProcessInfo.processInfo.arguments.contains("--ui-testing-demo")
        if usingDemo {
            if ProcessInfo.processInfo.arguments.contains("--ui-testing-permission-delay") {
                locationStatus = "Bitte entscheide über den Standortzugriff. Die Messung wartet."
                status = "Warte auf Standortfreigabe. Noch keine Messung gestartet."
                demoPermissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        guard let self, self.phase == .preparing else { return }
                        self.startGate.permission = .allowed
                        self.beginWhenReady()
                    }
                }
            } else {
                startGate.permission = .allowed
                beginWhenReady()
            }
            return
        }
        #endif
        usingDemo = false
        guard motion.isDeviceMotionAvailable,
              CMMotionManager.availableAttitudeReferenceFrames().contains(.xMagneticNorthZVertical) else {
            fail("Die benötigten Bewegungs- und Kompasssensoren sind auf diesem Gerät nicht verfügbar.")
            return
        }
        updatePermission(location.authorizationStatus)
        if location.authorizationStatus == .notDetermined {
            status = "Warte auf Standortfreigabe. Noch keine Messung gestartet."
            announce("Bitte entscheide über den Standortzugriff. Die Messung startet erst danach.", force: true)
            location.requestWhenInUseAuthorization()
        } else { beginWhenReady() }
    }
    private func updatePermission(_ authorization: CLAuthorizationStatus) {
        switch authorization {
        case .authorizedAlways, .authorizedWhenInUse:
            startGate.permission = .allowed
            locationStatus = "Standort freigegeben. Suche GPS-Position."
        case .denied, .restricted:
            startGate.permission = .unavailable
            locationStatus = "Standort nicht freigegeben. GPS fehlt; Ausrichtung nur magnetisch."
            heading = nil; position = nil
        default:
            startGate.permission = .undecided
            locationStatus = "Bitte entscheide über den Standortzugriff. Die Messung wartet."
        }
    }
    private func beginWhenReady() {
        guard phase == .preparing, startGate.canBegin else { return }
        // Time spent in the system permission dialog is not measurement time.
        startedAt = Date(); phase = .measuring
        status = "Messung gestartet. iPhone ruhig liegen lassen."
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        delayedStartAnnouncement = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard !Task.isCancelled, let self, self.phase == .measuring, self.startGate.isAppActive else { return }
            self.announce("Messung gestartet. Das iPhone bitte ruhig auf der Fläche liegen lassen.", force: true)
        }
        #if targetEnvironment(simulator)
        if usingDemo {
            timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.demoTick() }
            }
            return
        }
        #endif
        if startGate.permission == .allowed { location.startUpdatingLocation() }
        if CLLocationManager.headingAvailable() { location.startUpdatingHeading() }
        motion.showsDeviceMovementDisplay = true
        motion.deviceMotionUpdateInterval = 1.0/20
        motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] data, error in
            guard let self else { return }
            if error != nil { self.fail("Sensordaten konnten nicht gelesen werden. Prüfe den Bewegungszugriff in den Einstellungen."); return }
            if let data { self.consume(data) }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkTimeout() }
        }
    }
    func cancel() {
        guard phase == .measuring || phase == .preparing else { return }
        stopSensors(); phase = .ready; progress = 0
        status = "Messung abgebrochen. Es wurde nichts gespeichert."
        announce(status, force: true)
    }
    func applicationActivityChanged(isActive: Bool, enteredBackground: Bool) {
        startGate.isAppActive = isActive
        if enteredBackground { interrupt() }
        else if isActive { beginWhenReady() }
    }
    func interrupt() {
        if phase == .measuring || phase == .preparing {
            stopSensors(); phase = .ready; progress = 0
            status = "Messung unterbrochen. Bitte im Vordergrund neu starten."
        }
    }
    func forgetResults(ids: Set<UUID>) {
        guard let result, ids.contains(result.id) else { return }
        self.result = nil; phase = .ready; progress = 0; error = nil
        status = "Messung aus dem Verlauf gelöscht. Bereit für eine neue Messung."
    }
    func reportSaveFailure() {
        error = "Das Ergebnis konnte nicht gespeichert werden. Du kannst die Werte weiterhin hier ablesen und die Messung erneut starten."
        announce(error!, force: true)
    }
    private var declination: Double? {
        guard let heading, heading.headingAccuracy >= 0, heading.headingAccuracy <= 20,
              heading.trueHeading >= 0, Date().timeIntervalSince(heading.timestamp) < 5,
              let position, position.horizontalAccuracy >= 0,
              Date().timeIntervalSince(position.timestamp) < 60 else { return nil }
        return heading.trueHeading - heading.magneticHeading
    }
    private func consume(_ data: CMDeviceMotion) {
        guard phase == .measuring, startGate.isAppActive else { return }
        let g = data.gravity; let f = data.magneticField.field
        let magnetic = Vector3(x: f.x,y: f.y,z: f.z)
        let correction = declination
        let newReference: NorthReference = correction == nil ? .magnetic : .geographic
        if newReference != reference { window = SampleWindow(); reference = newReference }
        guard let o = PanelGeometry.orientation(gravity: .init(x:g.x,y:g.y,z:g.z), magneticField: magnetic, declination: correction) else {
            window = SampleWindow()
            setStatus("Bitte die Rückseite auf das Modul legen. Der Bildschirm muss nach außen zeigen.")
            return
        }
        let acceleration = data.userAcceleration
        let moving = sqrt(acceleration.x*acceleration.x + acceleration.y*acceleration.y + acceleration.z*acceleration.z) > 0.035 ||
            sqrt(pow(data.rotationRate.x,2)+pow(data.rotationRate.y,2)+pow(data.rotationRate.z,2)) > 0.06
        let sample = SensorSample(timestamp: Date().timeIntervalSince1970, tilt:o.tilt, azimuth:o.azimuth,
                                  fieldStrength:magnetic.length, moving:moving,
                                  calibrated:data.magneticField.accuracy == .medium || data.magneticField.accuracy == .high)
        totalSamples += 1
        window.append(sample)
        if Date().timeIntervalSince(lastPublished) > 0.4 {
            latestTilt = window.tiltMean; latestAzimuth = window.azimuthMean
            progress = min(0.95, Double(window.samples.count)/100)
            lastPublished = Date()
        }
        if !sample.calibrated || !(20...80).contains(sample.fieldStrength) {
            progress = 0
            setStatus("Kompass unzuverlässig. iPhone aufnehmen, abseits von Metall und Magneten bewegen und anschließend erneut auflegen.")
        } else if moving || window.tiltSpread > 1.5 {
            setStatus("Bitte das iPhone ruhig liegen lassen. Die Messung stabilisiert sich.")
        } else if reference == .magnetic {
            setStatus("Warte auf geografisch Nord und Standort. Ohne Standort wird das Ergebnis als magnetisch gekennzeichnet.")
        } else {
            setStatus("Messung läuft. Bitte ruhig liegen lassen.")
        }
        let elapsed = Date().timeIntervalSince(startedAt)
        if window.isStable && elapsed >= 6 && (reference == .geographic || elapsed >= 18) { finish() }
    }
    private func checkTimeout() {
        guard phase == .measuring, startGate.isAppActive else { return }
        if Date().timeIntervalSince(startedAt) >= 40 {
            fail("Keine ausreichend stabile Messung möglich. Prüfe die Auflage und entferne magnetische Hüllen. Kalibriere den Kompass abseits der Halterung und starte erneut. Es wurde kein unsicheres Ergebnis gespeichert.")
        }
    }
    private func finish() {
        var warnings: [String] = []
        if reference == .magnetic { warnings.append("Nur magnetisch Nord verfügbar. Nicht unverändert als geografischen HA-Azimut übernehmen.") }
        if window.tiltMean < 3 { warnings.append("Modul nahezu waagerecht: Eine eindeutige Ausrichtung ist nicht bestimmbar.") }
        let coordinates: Coordinates? = position.flatMap {
            guard $0.horizontalAccuracy >= 0, Date().timeIntervalSince($0.timestamp) < 60 else { return nil }
            return Coordinates(latitude:$0.coordinate.latitude,longitude:$0.coordinate.longitude,horizontalAccuracy:$0.horizontalAccuracy,timestamp:$0.timestamp)
        }
        if coordinates == nil { warnings.append("Kein aktueller GPS-Standort verfügbar.") }
        if let coordinates, coordinates.horizontalAccuracy > 100 { warnings.append("Standortgenauigkeit schlechter als 100 Meter.") }
        warnings.append("Stabile Werte schließen örtliche magnetische Störungen nicht aus. Ausrichtung mit Abstand zu Metall gegenprüfen.")
        let date = Date()
        let name = "Messung " + date.formatted(date: .numeric, time: .shortened)
        let m = PanelMeasurement(name:name,timestamp:date,tilt:window.tiltMean,azimuth:window.azimuthMean,
                            northReference:reference,coordinates:coordinates,duration:date.timeIntervalSince(startedAt),
                            sampleCount:totalSamples,tiltSpread:window.tiltSpread,azimuthSpread:window.azimuthSpread,
                            headingAccuracy:heading.flatMap { $0.headingAccuracy >= 0 ? $0.headingAccuracy : nil },warnings:warnings)
        complete(m)
    }
    private func complete(_ m: PanelMeasurement) {
        stopSensors(); result = m; phase = .finished; progress = 1
        status = "Messung abgeschlossen."
        onComplete?(m)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        announce("Messung abgeschlossen. Neigung \(m.tilt.formatted(.number.precision(.fractionLength(1)))) Grad. " + (m.azimuthUnavailableReason ?? m.northReference.title) + " Ergebnis steht unten.", force:true)
    }
    private func demoTick() {
        progress += 0.12
        if progress >= 1 {
            var m = PanelMeasurement.example()
            #if targetEnvironment(simulator)
            if ProcessInfo.processInfo.arguments.contains("--ui-testing-flat") {
                m.tilt = 1.13; m.azimuth = nil; m.azimuthSpread = nil
            }
            #endif
            complete(m)
        }
    }
    private func fail(_ message: String) {
        stopSensors(); phase = .failed; error = message; status = "Messung nicht möglich."
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        announce(message, force:true)
    }
    private func stopSensors() {
        delayedStartAnnouncement?.cancel(); delayedStartAnnouncement = nil
        #if targetEnvironment(simulator)
        demoPermissionTimer?.invalidate(); demoPermissionTimer = nil
        #endif
        timer?.invalidate(); timer = nil
        motion.stopDeviceMotionUpdates(); location.stopUpdatingHeading(); location.stopUpdatingLocation()
        UIApplication.shared.isIdleTimerDisabled = false
    }
    private func setStatus(_ message: String) {
        if status != message { status = message; announce(message) }
    }
    private func announce(_ message: String, force: Bool = false) {
        guard force || Date().timeIntervalSince(lastAnnouncement) > 8 else { return }
        lastAnnouncement = Date()
        let speech = NSAttributedString(string: message, attributes: [.accessibilitySpeechQueueAnnouncement: true])
        UIAccessibility.post(notification: .announcement, argument: speech)
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard phase == .preparing || phase == .measuring else { return }
        updatePermission(manager.authorizationStatus)
        if phase == .preparing { beginWhenReady() }
        else if startGate.permission == .allowed { manager.startUpdatingLocation() }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard phase == .measuring, let latest = locations.last,
              latest.horizontalAccuracy >= 0, abs(latest.timestamp.timeIntervalSinceNow) < 60 else { return }
        position = latest
        locationStatus = "Standort verfügbar, Genauigkeit etwa \(Int(latest.horizontalAccuracy)) Meter."
    }
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard phase == .measuring else { return }
        heading = newHeading
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationStatus = "Standort derzeit nicht verfügbar. Messung wird entsprechend gekennzeichnet."
    }
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool { true }
}
