import Foundation

@MainActor final class MeasurementStore: ObservableObject {
    @Published private(set) var measurements: [PanelMeasurement] = []
    @Published var errorMessage: String?
    private let fileURL: URL
    private var writable = true
    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PVKompass", isDirectory: true).appendingPathComponent("measurements.json")
        do {
            if FileManager.default.fileExists(atPath: self.fileURL.path) {
                measurements = try JSONDecoder().decode([PanelMeasurement].self, from: Data(contentsOf: self.fileURL))
            }
        } catch {
            writable = false
            errorMessage = "Der Messverlauf konnte nicht gelesen werden. Die vorhandene Datei wurde nicht überschrieben. Die Originaldatei bleibt für eine Wiederherstellung erhalten."
        }
    }
    func add(_ measurement: PanelMeasurement) throws {
        var next = measurements; next.insert(measurement, at: 0)
        try save(next)
    }
    func rename(id: UUID, to name: String) throws {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        var next = measurements
        guard let index = next.firstIndex(where: { $0.id == id }) else { return }
        next[index].name = String(cleaned.prefix(120))
        try save(next)
    }
    func delete(id: UUID) throws { try save(measurements.filter { $0.id != id }) }
    func deleteAll() throws { try save([]) }
    private func save(_ next: [PanelMeasurement]) throws {
        guard writable else { throw CocoaError(.fileWriteNoPermission) }
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(next).write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        measurements = next
    }
}

enum CSVExport {
    static func escape(_ value: String, protectFormula: Bool = true) -> String {
        // Neutralise spreadsheet formula injection in user-chosen names.
        let first = value.trimmingCharacters(in: .whitespacesAndNewlines).first
        let safe = protectFormula && first.map { "=+-@".contains($0) } == true ? "'" + value : value
        return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
    static func content(_ m: PanelMeasurement) -> String { content([m]) }
    static func content(_ measurements: [PanelMeasurement]) -> String {
        "\u{FEFF}" + header.joined(separator: ",") + "\r\n" + measurements.map(row).joined()
    }
    private static let header = ["id","name","timestamp_utc","timezone","tilt_deg_from_horizontal","azimuth_deg_clockwise_from_north","north_reference","latitude","longitude","gps_accuracy_m","gps_timestamp_utc","duration_s","samples","tilt_spread_deg","azimuth_spread_deg","heading_accuracy_deg","ha_forecast_solar_azimuth_deg","forecast_solar_api_aspect_deg","warnings","is_demo"]
    private static func row(_ m: PanelMeasurement) -> String {
        let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        func n(_ value: Double?) -> String { value.map { String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), $0) } ?? "" }
        let values = [m.id.uuidString,m.name,iso.string(from: m.timestamp),m.timeZoneIdentifier,n(m.tilt),n(m.azimuth),m.northReference.rawValue,n(m.coordinates?.latitude),n(m.coordinates?.longitude),n(m.coordinates?.horizontalAccuracy),m.coordinates.map { iso.string(from: $0.timestamp) } ?? "",n(m.duration),String(m.sampleCount),n(m.tiltSpread),n(m.azimuthSpread),n(m.headingAccuracy),n(m.isDemo ? nil : m.forecastAzimuth),n(m.isDemo ? nil : m.forecastAzimuth.map { $0 - 180 }),m.warnings.joined(separator: " | "),m.isDemo ? "true" : "false"]
        return values.enumerated().map { escape($0.element, protectFormula: $0.offset == 1) }.joined(separator: ",") + "\r\n"
    }
    static func write(_ m: PanelMeasurement) throws -> URL {
        try write(content(m), filename: "PV-Messung-\(m.id.uuidString.prefix(8)).csv")
    }
    static func write(_ measurements: [PanelMeasurement]) throws -> URL {
        try write(content(measurements), filename: "PV-Messverlauf-\(UUID().uuidString.prefix(8)).csv")
    }
    private static func write(_ csv: String, filename: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("PVKompass-Export", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(filename)
        try Data(csv.utf8).write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        return url
    }
}
