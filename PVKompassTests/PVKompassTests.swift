import XCTest
@testable import PVKompass

final class GeometryTests: XCTestCase {
    // Construct orthonormal north/east/up in DEVICE coordinates for known panels.
    // Phone rotated around its own normal must not change panel bearing.
    func vectors(tilt:Double, azimuth:Double, handsetRotation:Double = 0) -> (Vector3,Vector3) {
        let t = tilt * .pi/180; let a = azimuth * .pi/180; let r = handsetRotation * .pi/180
        // Physical right-handed world = E,N,U. Azimuth is clockwise from North.
        // Device X chosen sideways; device Y = normal cross X.
        let z = Vector3(x:sin(t)*sin(a),y:sin(t)*cos(a),z:cos(t))
        let x = Vector3(x:cos(a),y:-sin(a),z:0)
        let y = z.cross(x)
        let xr = Vector3(x:x.x*cos(r)+y.x*sin(r),y:x.y*cos(r)+y.y*sin(r),z:x.z*cos(r)+y.z*sin(r))
        let yr = Vector3(x:y.x*cos(r)-x.x*sin(r),y:y.y*cos(r)-x.y*sin(r),z:y.z*cos(r)-x.z*sin(r))
        let up = Vector3(x:xr.z,y:yr.z,z:z.z)
        // Real field has both horizontal north and vertical dip, not just north.
        let field = Vector3(x:25*xr.y-40*up.x,y:25*yr.y-40*up.y,z:25*z.y-40*up.z)
        return (up * -1, field)
    }
    func testCardinalDirectionsAndTilts() throws {
        for tilt in [10.0,35,68,90] {
            for a in [0.0,45,90,180,270,359] {
                let (g,f) = vectors(tilt:tilt,azimuth:a)
                let o = try XCTUnwrap(PanelGeometry.orientation(gravity:g,magneticField:f,declination:0))
                XCTAssertEqual(o.tilt,tilt,accuracy:0.00001)
                XCTAssertLessThan(PanelGeometry.angularDistance(try XCTUnwrap(o.azimuth),a),0.00001)
            }
        }
    }
    func testHandsetRotationDoesNotChangePanelBearing() throws {
        for rotation in [0.0,30,90,180,270] {
            let (g,f) = vectors(tilt:68,azimuth:184,handsetRotation:rotation)
            let o = try XCTUnwrap(PanelGeometry.orientation(gravity:g,magneticField:f,declination:0))
            XCTAssertEqual(o.tilt,68,accuracy:0.00001)
            XCTAssertEqual(try XCTUnwrap(o.azimuth),184,accuracy:0.00001)
        }
    }
    func testDeclinationCorrectionWrapsNorth() throws {
        let (g,f) = vectors(tilt:50,azimuth:358)
        let o = try XCTUnwrap(PanelGeometry.orientation(gravity:g,magneticField:f,declination:4))
        XCTAssertEqual(try XCTUnwrap(o.azimuth),2,accuracy:0.00001)
    }
    func testFlatHasNoAzimuth() throws {
        let (g,f) = vectors(tilt:0,azimuth:180)
        let o = try XCTUnwrap(PanelGeometry.orientation(gravity:g,magneticField:f,declination:0))
        XCTAssertNil(o.azimuth)
        XCTAssertEqual(o.tilt,0,accuracy:0.00001)
    }
    func testUpsideDownAndInvalidVectorsRejected() {
        XCTAssertNil(PanelGeometry.orientation(gravity:.init(x:0,y:0,z:1),magneticField:.init(x:20,y:0,z:40),declination:0))
        XCTAssertNil(PanelGeometry.orientation(gravity:.init(x:0,y:0,z:0),magneticField:.init(x:20,y:0,z:40),declination:0))
    }
    func testCircularMeanAcrossNorth() throws {
        let mean = try XCTUnwrap(PanelGeometry.circularMean([359,0,1]))
        XCTAssertLessThan(PanelGeometry.angularDistance(mean,0),0.001)
        XCTAssertNil(PanelGeometry.circularMean([0,180]))
    }
    func testStabilityRejectsMovementAndDisturbedField() {
        var window = SampleWindow()
        for i in 0..<101 { window.append(.init(timestamp:Double(i)*0.05,tilt:60,azimuth:i % 2 == 0 ? 359 : 1,fieldStrength:48,moving:false,calibrated:true)) }
        XCTAssertTrue(window.isStable)
        window.append(.init(timestamp:5.05,tilt:60,azimuth:0,fieldStrength:150,moving:false,calibrated:true))
        XCTAssertFalse(window.isStable)
        window = SampleWindow()
        for i in 0..<101 { window.append(.init(timestamp:Double(i)*0.05,tilt:60,azimuth:180,fieldStrength:48,moving:i==100,calibrated:true)) }
        XCTAssertFalse(window.isStable)
    }
}

final class ExportTests: XCTestCase {
    func testCSVQuotesNamesNewlinesAndUsesInvariantDecimals() {
        var m = PanelMeasurement.example(); m.name = "Panel, \"Süd\"\nHaus"; m.isDemo = false
        let csv = CSVExport.content(m)
        XCTAssertTrue(csv.contains("\"Panel, \"\"Süd\"\"\nHaus\""))
        XCTAssertTrue(csv.contains("68.200000"))
        XCTAssertTrue(csv.contains("4.500000")) // API aspect: 184.5 minus 180
        XCTAssertTrue(csv.contains("timestamp_utc"))
        XCTAssertTrue(csv.contains("gps_accuracy_m"))
    }
    func testSpreadsheetFormulaInjectionNeutralized() {
        XCTAssertEqual(CSVExport.escape("=1+2"),"\"'=1+2\"")
        XCTAssertEqual(CSVExport.escape("  @SUM(A1)"),"\"'  @SUM(A1)\"")
    }
    func testNegativeNumericCSVFieldsStayNumeric() {
        var m = PanelMeasurement.example(); m.isDemo = false; m.azimuth = 90
        m.coordinates = .init(latitude: -33, longitude: -70, horizontalAccuracy: 8, timestamp: Date())
        let csv = CSVExport.content(m)
        XCTAssertTrue(csv.contains("\"-90.000000\""))
        XCTAssertTrue(csv.contains("\"-33.000000\""))
        XCTAssertFalse(csv.contains("\"'-90"))
    }
    func testMagneticOrDemoNotOfferedAsHAValues() {
        var m = PanelMeasurement.example()
        XCTAssertFalse(m.canCopyHA)
        m.isDemo = false; m.northReference = .magnetic
        XCTAssertFalse(m.canCopyHA)
        XCTAssertNil(m.forecastAzimuth)
        m.northReference = .geographic
        XCTAssertTrue(m.canCopyHA)
    }
    func testGPSAndTimestampRoundTrip() throws {
        var m = PanelMeasurement.example()
        m.coordinates = .init(latitude:52.2,longitude:8.1,horizontalAccuracy:12,timestamp:Date(timeIntervalSince1970:1700000000))
        let copy = try JSONDecoder().decode(PanelMeasurement.self,from:JSONEncoder().encode(m))
        XCTAssertEqual(copy,m)
        XCTAssertTrue(CSVExport.content(m).contains("52.200000"))
    }
}

@MainActor final class StoreTests: XCTestCase {
    func testSaveRenameReloadAndDelete() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:dir) }
        let url = dir.appendingPathComponent("measurements.json")
        let store = MeasurementStore(fileURL:url)
        let m = PanelMeasurement.example(); try store.add(m)
        try store.rename(id:m.id,to:"  Hauswand links  ")
        XCTAssertEqual(MeasurementStore(fileURL:url).measurements.first?.name,"Hauswand links")
        try store.delete(id:m.id)
        XCTAssertTrue(MeasurementStore(fileURL:url).measurements.isEmpty)
    }
    func testCorruptHistoryIsNotOverwritten() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at:url) }
        let original = Data("broken archive".utf8); try original.write(to:url)
        let store = MeasurementStore(fileURL:url)
        XCTAssertNotNil(store.errorMessage)
        XCTAssertThrowsError(try store.add(.example()))
        XCTAssertEqual(try Data(contentsOf:url),original)
    }
}
