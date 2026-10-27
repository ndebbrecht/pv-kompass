import Foundation

struct Vector3: Equatable {
    var x: Double; var y: Double; var z: Double
    var length: Double { sqrt(x*x + y*y + z*z) }
    func dot(_ b: Self) -> Double { x*b.x + y*b.y + z*b.z }
    func cross(_ b: Self) -> Self { .init(x: y*b.z-z*b.y, y: z*b.x-x*b.z, z: x*b.y-y*b.x) }
    static func * (a: Self, b: Double) -> Self { .init(x: a.x*b, y: a.y*b, z: a.z*b) }
    static func - (a: Self, b: Self) -> Self { .init(x: a.x-b.x, y: a.y-b.y, z: a.z-b.z) }
    var normalized: Self? { length.isFinite && length > 0.000001 ? self * (1/length) : nil }
}

enum NorthReference: String, Codable {
    case geographic, magnetic
    var title: String { self == .geographic ? "Geografisch Nord" : "Magnetisch Nord" }
}
struct Coordinates: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var horizontalAccuracy: Double
    var timestamp: Date
}
struct PanelMeasurement: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var timestamp = Date()
    var timeZoneIdentifier = TimeZone.current.identifier
    var tilt: Double
    var azimuth: Double?
    var northReference: NorthReference
    var coordinates: Coordinates?
    var duration: Double
    var sampleCount: Int
    var tiltSpread: Double
    var azimuthSpread: Double?
    var headingAccuracy: Double?
    var warnings: [String]
    var isDemo = false
    var forecastAzimuth: Double? {
        guard northReference == .geographic else { return nil }
        // At near-horizontal angles bearing is undefined, not silently invented.
        return azimuth
    }
    var canCopyHA: Bool { !isDemo && forecastAzimuth != nil }
    var haText: String {
        guard let a = forecastAzimuth, !isDemo else {
            return "Keine geografische Ausrichtung verfügbar. Bitte Messhinweise beachten."
        }
        return String(format: "Forecast.Solar (Home Assistant)\nNeigung: %.1f°\nAzimut: %.1f°\n0° Nord · 90° Ost · 180° Süd · 270° West", locale: Locale(identifier: "de_DE"), tilt, a)
    }
    static func example() -> Self {
        .init(name: "Beispiel: Hauswand", tilt: 68.2, azimuth: 184.5, northReference: .geographic,
              coordinates: nil, duration: 8, sampleCount: 160, tiltSpread: 0.4, azimuthSpread: 1.8,
              headingAccuracy: 8, warnings: ["Demodaten – keine echte Sensormessung."], isDemo: true)
    }
}
struct SensorSample {
    var timestamp: TimeInterval
    var tilt: Double
    var azimuth: Double?
    var fieldStrength: Double
    var moving: Bool
    var calibrated: Bool
}

/// All vectors are in the same device frame. Device +Z points out of the screen.
/// Gravity supplies up; calibrated magnetic field supplies horizontal magnetic north.
/// This is invariant under rotating the handset within the module plane.
/// No Euler-angle / handset-top-edge heading is mistaken for panel facing direction.
struct PanelGeometry {
    static func normalizeDegrees(_ x: Double) -> Double { (x.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) }
    static func angularDistance(_ a: Double, _ b: Double) -> Double { abs((a-b+540).truncatingRemainder(dividingBy: 360)-180) }
    static func orientation(gravity: Vector3, magneticField: Vector3, declination: Double?) -> (tilt: Double, azimuth: Double?)? {
        guard let up = (gravity * -1).normalized else { return nil }
        let cosine = max(-1, min(1, up.z))
        // Screen must face away from the front of the module, not into it.
        guard cosine >= -0.035 else { return nil }
        let tilt = acos(max(0, cosine)) * 180 / .pi
        if tilt < 3 { return (tilt, nil) }
        guard let north = (magneticField - up * magneticField.dot(up)).normalized,
              let east = north.cross(up).normalized else { return nil }
        let magneticAzimuth = atan2(east.z, north.z) * 180 / .pi
        return (tilt, normalizeDegrees(magneticAzimuth + (declination ?? 0)))
    }
    static func circularMean(_ degrees: [Double]) -> Double? {
        guard !degrees.isEmpty else { return nil }
        let s = degrees.reduce(0) { $0 + sin($1 * .pi/180) }
        let c = degrees.reduce(0) { $0 + cos($1 * .pi/180) }
        guard hypot(s,c) / Double(degrees.count) > 0.5 else { return nil }
        return normalizeDegrees(atan2(s,c) * 180 / .pi)
    }
}

struct SampleWindow {
    var samples: [SensorSample] = []
    mutating func append(_ sample: SensorSample) {
        samples.append(sample)
        samples.removeAll { $0.timestamp < sample.timestamp - 5 }
    }
    var tiltMean: Double { samples.isEmpty ? 0 : samples.map(\.tilt).reduce(0,+) / Double(samples.count) }
    var tiltSpread: Double { (samples.map(\.tilt).max() ?? 0) - (samples.map(\.tilt).min() ?? 0) }
    var azimuthMean: Double? { PanelGeometry.circularMean(samples.compactMap(\.azimuth)) }
    var azimuthSpread: Double? {
        guard let mean = azimuthMean else { return nil }
        return samples.compactMap(\.azimuth).map { PanelGeometry.angularDistance($0, mean) }.max().map { $0*2 }
    }
    var isStable: Bool {
        guard samples.count >= 60, let first = samples.first, let last = samples.last,
              last.timestamp-first.timestamp >= 4, tiltSpread <= 1.5,
              samples.allSatisfy({ !$0.moving && $0.calibrated && (20...80).contains($0.fieldStrength) }) else { return false }
        return tiltMean < 3 || (azimuthSpread.map { $0 <= 6 } ?? false)
    }
}
