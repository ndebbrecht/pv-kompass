import SwiftUI
import UIKit

struct MeasurementView: View {
    @EnvironmentObject private var store: MeasurementStore
    @EnvironmentObject private var sensor: SensorService
    @State private var showGuide = false
    @State private var exportItem: ExportItem?
    @State private var exportError: String?
    @AccessibilityFocusState private var startFocused: Bool
    private var measuring: Bool { sensor.phase == .measuring || sensor.phase == .preparing }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Modul vermessen")
                    .font(.largeTitle.bold()).fixedSize(horizontal:false,vertical:true)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: 16) {
                    Text("iPhone auflegen")
                        .font(.headline).accessibilityAddTraits(.isHeader)
                    Text("Rückseite am Modul. Bildschirm nach außen. Ruhig halten.").fixedSize(horizontal:false,vertical:true)
                    Button { showGuide = true } label: { Label("Messanleitung",systemImage:"info.circle").fixedSize(horizontal:false,vertical:true) }.frame(minHeight:44)
                }
                .padding().background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))

                VStack(alignment: .leading, spacing: 12) {
                    Text(sensor.status).font(.headline).fixedSize(horizontal:false,vertical:true)
                        .accessibilityIdentifier("measurementStatus")
                    if measuring {
                        ProgressView(value: sensor.progress)
                            .accessibilityLabel("Messfortschritt")
                            .accessibilityValue("\(Int(sensor.progress*100)) Prozent; Abschluss nur bei stabilen Werten")
                        Text(sensor.locationStatus).font(.callout).foregroundStyle(Color.readableSecondary)
                        Button("Status vorlesen", systemImage: "speaker.wave.2") {
                            UIAccessibility.post(notification: .announcement, argument: sensor.status + " " + sensor.locationStatus)
                        }
                        Button("Messung abbrechen", role: .cancel) { sensor.cancel() }
                            .frame(minHeight: 44)
                    } else {
                        Button(action: start) {
                            Label(sensor.result == nil ? "Messung starten" : "Neue Messung", systemImage: "viewfinder")
                                .font(.headline).fixedSize(horizontal:false,vertical:true).frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("startMeasurement")
                        .accessibilityHint("Sammelt Sensorwerte, bis die Messung stabil ist. Speichert das Ergebnis automatisch im Verlauf.")
                        .accessibilityFocused($startFocused)
                    }
                    if let message = sensor.error {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.primary).fixedSize(horizontal:false,vertical:true)
                            .accessibilityIdentifier("measurementError")
                    }
                    if let error = store.errorMessage {
                        Text(error).foregroundStyle(.primary)
                    }
                }
                if let result = sensor.result {
                    ResultSummary(measurement: result)
                    NavigationLink("Ergebnis ansehen und teilen") { MeasurementDetail(measurementID: result.id, fallback: result) }
                        .buttonStyle(.bordered).frame(minHeight:44)
                        .accessibilityIdentifier("showResult")
                }

            }.padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("PV Kompass")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let result = sensor.result {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Als CSV teilen", systemImage: "square.and.arrow.up") {
                        do { exportItem = ExportItem(url: try CSVExport.write(result)) }
                        catch { exportError = "CSV konnte nicht erstellt werden." }
                    }.accessibilityIdentifier("shareCurrentMeasurement")
                }
            }
        }
        .sheet(isPresented: $showGuide) { GuideView() }
        .sheet(item: $exportItem) { item in ActivitySheet(url: item.url) }
        .alert("CSV-Export", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
            Button("OK") { exportError = nil }
        } message: { Text(exportError ?? "") }
    }
    private func start() {
        sensor.start { m in
            do { try store.add(m) }
            catch { store.errorMessage = "Messung konnte nicht gespeichert werden."; sensor.reportSaveFailure() }
        }
    }
}

struct ResultSummary: View {
    let measurement: PanelMeasurement
    var body: some View {
        VStack(alignment:.leading, spacing:16) {
            Text(measurement.isDemo ? "Demo-Ergebnis" : "Dein Messergebnis")
                .font(.title2.bold()).accessibilityAddTraits(.isHeader)
            value("Neigung", measurement.tilt.formatted(.number.precision(.fractionLength(1))) + "°", detail:"Gegenüber der Waagerechten")
            value("Ausrichtung", measurement.azimuth.map { $0.formatted(.number.precision(.fractionLength(1))) + "°" } ?? "Nicht bestimmbar", detail:measurement.azimuthUnavailableReason ?? measurement.northReference.title)
            if measurement.northReference == .magnetic {
                Label("Nicht direkt als geografischen HA-Azimut übernehmen.", systemImage:"exclamationmark.triangle")
            }
        }
        .padding(20)
        .frame(maxWidth:.infinity,alignment:.leading)
        .background(Color(.secondarySystemGroupedBackground),in:RoundedRectangle(cornerRadius:20))
    }
    private func value(_ title:String, _ value:String, detail:String) -> some View {
        VStack(alignment:.leading,spacing:4) {
            Text(title).font(.headline)
            Text(value).font(.system(.largeTitle,design:.rounded).weight(.semibold))
            Text(detail).font(.callout).foregroundStyle(Color.readableSecondary)
        }.accessibilityElement(children:.ignore)
            .accessibilityLabel(title)
            .accessibilityValue(value.replacingOccurrences(of:"°",with:" Grad") + ". " + detail)
    }
}

struct HistoryView: View {
    @EnvironmentObject private var store: MeasurementStore
    @State private var exportItem: ExportItem?
    @State private var message: String?
    @State private var deleteAll = false
    @State private var deleteMeasurement: PanelMeasurement?
    var body: some View {
        Group {
            if store.measurements.isEmpty {
                ContentUnavailableView("Noch keine Messungen", systemImage:"clock.arrow.circlepath", description:Text("Starte im Tab Messung. Abgeschlossene Messungen erscheinen hier automatisch mit Datum und Uhrzeit."))
                    .accessibilityIdentifier("emptyHistory")
            } else {
                List {
                    Section {
                        ForEach(store.measurements) { m in
                            NavigationLink { MeasurementDetail(measurementID:m.id,fallback:m) } label: {
                                VStack(alignment:.leading,spacing:6) {
                                    Text(m.name).font(.headline)
                                    Text(m.timestamp.formatted(date:.abbreviated,time:.shortened)).font(.subheadline)
                                    Text("\(m.tilt.formatted(.number.precision(.fractionLength(1))))° Neigung · \(m.azimuth.map { $0.formatted(.number.precision(.fractionLength(1))) + "°" } ?? "keine Richtung")")
                                        .font(.callout).foregroundStyle(Color.readableSecondary)
                                    if m.isDemo { Text("Demodaten").font(.caption.bold()) }
                                }.padding(.vertical,4)
                            }
                            .accessibilityIdentifier("history-\(m.id)")
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Löschen", systemImage: "trash", role: .destructive) { deleteMeasurement = m }
                            }
                            .accessibilityAction(named: Text("Messung löschen")) { deleteMeasurement = m }
                        }
                    } header: {
                        Text("\(store.measurements.count) Messungen")
                    }
                    Section {
                        Button("Alle Messungen löschen", systemImage: "trash", role: .destructive) { deleteAll = true }
                            .accessibilityIdentifier("deleteAllMeasurements")
                    } footer: {
                        Text("Löscht den gesamten lokalen Messverlauf. Du kannst ihn vorher oben rechts als CSV sichern.")
                    }
                }
            }
        }
        .navigationTitle("Messverlauf")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Alle Messungen als CSV teilen", systemImage: "square.and.arrow.up") {
                    do { exportItem = ExportItem(url: try CSVExport.write(store.measurements)) }
                    catch { message = "Der Messverlauf konnte nicht als CSV erstellt werden." }
                }
                .accessibilityIdentifier("exportAllCSV")
                .accessibilityHint("Teilt alle gespeicherten Messungen in einer CSV-Datei, einschließlich vorhandener GPS-Daten.")
                .disabled(store.measurements.isEmpty)
            }
        }
        .sheet(item: $exportItem) { item in ActivitySheet(url: item.url) }
        .alert("Alle \(store.measurements.count) Messungen dauerhaft löschen?", isPresented: $deleteAll) {
            Button("Alle Messungen endgültig löschen", role: .destructive) {
                do {
                    try store.deleteAll()
                    UIAccessibility.post(notification: .announcement, argument: "Alle Messungen wurden gelöscht.")
                } catch { message = "Die Messungen konnten nicht gelöscht werden. Der Verlauf bleibt erhalten." }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: { Text("Diese Aktion kann nicht rückgängig gemacht werden. Bereits geteilte CSV-Dateien werden nicht gelöscht.") }
        .alert("Messung löschen?", isPresented: Binding(get: { deleteMeasurement != nil }, set: { if !$0 { deleteMeasurement = nil } }), presenting: deleteMeasurement) { measurement in
            Button("Messung endgültig löschen", role: .destructive) {
                do {
                    try store.delete(id: measurement.id)
                    UIAccessibility.post(notification: .announcement, argument: "Messung gelöscht.")
                } catch { message = "Die Messung konnte nicht gelöscht werden." }
                deleteMeasurement = nil
            }
            Button("Abbrechen", role: .cancel) { deleteMeasurement = nil }
        } message: { measurement in Text(measurement.name) }
        .alert("Hinweis", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK") { message = nil }
        } message: { Text(message ?? "") }
        .overlay(alignment:.bottom) {
            if let error = store.errorMessage { Text(error).padding().background(.regularMaterial) }
        }
    }
}

struct MeasurementDetail: View {
    @EnvironmentObject private var store: MeasurementStore
    @Environment(\.dismiss) private var dismiss
    let measurementID: UUID
    let fallback: PanelMeasurement
    @State private var rename = false
    @State private var name = ""
    @State private var delete = false
    @State private var exportItem: ExportItem?
    @State private var message: String?
    private var measurement: PanelMeasurement { store.measurements.first { $0.id == measurementID } ?? fallback }
    var body: some View {
        List {
            Section {
                Text(measurement.name).font(.title2.bold()).accessibilityAddTraits(.isHeader)
                LabeledContent("Zeitpunkt",value:measurement.timestamp.formatted(date:.complete,time:.standard))
                LabeledContent("Zeitzone",value:measurement.timeZoneIdentifier)
                Button("Messung benennen",systemImage:"pencil") { name = measurement.name; rename = true }
                    .accessibilityIdentifier("renameMeasurement")
            }
            Section("Messergebnis") {
                LabeledContent("Neigung",value:"\(measurement.tilt.formatted(.number.precision(.fractionLength(1)))) Grad")
                LabeledContent("Azimut",value:measurement.azimuth.map { "\($0.formatted(.number.precision(.fractionLength(1)))) Grad" } ?? "Nicht bestimmbar")
                if let reason = measurement.azimuthUnavailableReason {
                    Text(reason).accessibilityIdentifier("azimuthUnavailableReason")
                }
                LabeledContent("Nordbezug",value:measurement.northReference.title)
                Text("Neigung: 0° waagerecht, 90° senkrecht. Azimut: 0° Nord, 90° Ost, 180° Süd, 270° West.")
                    .font(.footnote).foregroundStyle(Color.readableSecondary)
            }
            Section("GPS-Standort") {
                if let gps = measurement.coordinates {
                    LabeledContent("Breitengrad",value:gps.latitude.formatted(.number.precision(.fractionLength(6))))
                    LabeledContent("Längengrad",value:gps.longitude.formatted(.number.precision(.fractionLength(6))))
                    LabeledContent("Genauigkeit",value:"etwa \(gps.horizontalAccuracy.formatted(.number.precision(.fractionLength(0)))) Meter")
                    LabeledContent("Standortzeit",value:gps.timestamp.formatted(date:.abbreviated,time:.standard))
                } else { Text("Kein GPS-Standort gespeichert.") }
                Text("Standortdaten verlassen das iPhone nur, wenn du die CSV selbst teilst.")
                    .font(.footnote).foregroundStyle(Color.readableSecondary)
            }
            Section("Home Assistant") {
                Text(measurement.haText).textSelection(.enabled)
                if measurement.canCopyHA {
                    Button("HA-Werte kopieren",systemImage:"doc.on.doc") {
                        UIPasteboard.general.string = measurement.haText
                        UIAccessibility.post(notification:.announcement,argument:"Home-Assistant-Werte kopiert.")
                    }
                }
                Text("Diese Winkel gelten für die HA-Integration Forecast.Solar. Die direkte Forecast.Solar-API verwendet dagegen Süd = 0°, Ost = −90°, West = 90°. Beide Konventionen stehen getrennt in der CSV.")
                    .font(.footnote).foregroundStyle(Color.readableSecondary)
            }
            Section("Messqualität") {
                LabeledContent("Messdauer",value:"\(measurement.duration.formatted(.number.precision(.fractionLength(1)))) Sekunden")
                LabeledContent("Sensorwerte",value:String(measurement.sampleCount))
                LabeledContent("Neigungsschwankung",value:"\(measurement.tiltSpread.formatted(.number.precision(.fractionLength(1)))) Grad")
                if let spread = measurement.azimuthSpread {
                    LabeledContent("Richtungsschwankung",value:"\(spread.formatted(.number.precision(.fractionLength(1)))) Grad")
                }
                if let accuracy = measurement.headingAccuracy {
                    LabeledContent("Kompass-Schätzgenauigkeit",value:"±\(accuracy.formatted(.number.precision(.fractionLength(0)))) Grad")
                }
                Text("Schwankungsbreite ist keine Garantie für absolute Messgenauigkeit.")
                    .font(.footnote).foregroundStyle(Color.readableSecondary)
                ForEach(measurement.warnings,id:\.self) { Text($0) }
            }
            Section {
                Button("Messung löschen",systemImage:"trash",role:.destructive) { delete = true }
            }
        }
        .navigationTitle("Messung")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Als CSV teilen", systemImage: "square.and.arrow.up") {
                    do { exportItem = ExportItem(url: try CSVExport.write(measurement)) }
                    catch { message = "CSV konnte nicht erstellt werden: \(error.localizedDescription)" }
                }.accessibilityIdentifier("exportCSV")
            }
        }
        .alert("Messung benennen",isPresented:$rename) {
            TextField("Name",text:$name).accessibilityIdentifier("measurementName")
            Button("Speichern") {
                do { try store.rename(id:measurementID,to:name) }
                catch { message = "Name konnte nicht gespeichert werden." }
            }
            Button("Abbrechen",role:.cancel) {}
        } message: { Text("Zum Beispiel: Hauswand links") }
        .confirmationDialog("Diese Messung dauerhaft löschen?",isPresented:$delete,titleVisibility:.visible) {
            Button("Messung löschen",role:.destructive) {
                do { try store.delete(id:measurementID); dismiss() }
                catch { message = "Messung konnte nicht gelöscht werden." }
            }
            Button("Abbrechen",role:.cancel) {}
        }
        .alert("Hinweis",isPresented:Binding(get:{message != nil},set:{if !$0 { message = nil }})) {
            Button("OK") { message = nil }
        } message: { Text(message ?? "") }
        .sheet(item:$exportItem) { item in ActivitySheet(url:item.url) }
    }
}
struct ExportItem: Identifiable { var id = UUID(); var url: URL }
struct ActivitySheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context:Context) -> UIActivityViewController {
        UIActivityViewController(activityItems:[url],applicationActivities:nil)
    }
    func updateUIViewController(_ uiViewController:UIActivityViewController,context:Context) {}
}
struct GuideView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("1. Richtig auflegen") {
                    Text("Lege die Rückseite des iPhones parallel auf die Vorderseite des PV-Moduls. Der Bildschirm zeigt vom Modul weg. Eine bestimmte Drehung innerhalb der Modulfläche ist nicht erforderlich.")
                    Text("Kamerabuckel und Hülle können die Auflage verkippen. Nutze bei Bedarf zwei gleich hohe, nicht magnetische Abstandshalter. Halte das iPhone gegen Abrutschen fest. Keine heißen oder schwer erreichbaren Modulflächen verwenden.")
                }
                Section("2. Messung starten") {
                    Text("Tippe auf Messung starten. Lasse das Gerät ruhig liegen. Der Fortschritt zeigt die Sammlung von Sensorwerten; abgeschlossen wird erst bei einer stabilen Messung. Die Standortfreigabe wird vor dem Messbeginn abgefragt. Ein Signal und eine VoiceOver-Ansage melden Start und Abschluss.")
                    Text("Bei einem Kalibrierungshinweis: iPhone aufnehmen, abseits von Metall und magnetischem Zubehör bewegen und wieder auflegen. Nicht auf dem Glas hin- und herschieben.")
                }
                Section("3. Ergebnis prüfen") {
                    Text("Die Neigung wird gegenüber der Waagerechten ermittelt. Der Azimut beschreibt die Richtung der Modulvorderseite, nicht die Oberkante des iPhones.")
                    Text("Mit Standort und gültigem Kompassbezug wird geografisch Nord verwendet. Ohne diese Angaben wird die Ausrichtung ausdrücklich als magnetisch gekennzeichnet. Bei nahezu waagerechten Modulen ist der Azimut nicht bestimmbar.")
                    Text("Metallhalterungen und Stromleitungen können eine stabile, aber falsche Richtung verursachen. Die App erkennt nicht jede Störung. Prüfe die Richtung zusätzlich mit Abstand zur Anlage oder anhand eines Gebäudeplans.")
                }
                Section("4. Verlauf und Datenschutz") {
                    Text("Abgeschlossene Messungen werden lokal gespeichert. Im Verlauf kannst du sie benennen, löschen und einzeln über das Apple-Teilen-Menü als CSV exportieren. Die CSV enthält gegebenenfalls genaue GPS-Koordinaten.")
                    Text("Kein Konto, keine Werbung, kein Tracking und keine Cloud-Anbindung. Die App überträgt selbst keine Messdaten. iOS-Gerätesicherungen können den lokalen Verlauf enthalten.")
                }
            }
            .navigationTitle("Messanleitung")
            .toolbar { ToolbarItem(placement:.confirmationAction) { Button("Fertig") { dismiss() } } }
        }
    }
}

extension Color {
    static var readableSecondary: Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(white:0.78,alpha:1) : UIColor(white:0.32,alpha:1) })
    }
}
