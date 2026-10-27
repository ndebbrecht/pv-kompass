import XCTest

final class PVKompassUITests: XCTestCase {
    @MainActor func testMeasurementHistoryRenameAndNativeCSVShare() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing-demo"]
        app.launch()
        XCTAssertTrue(app.buttons["startMeasurement"].waitForExistence(timeout:10))
        app.buttons["startMeasurement"].tap()
        XCTAssertTrue(app.buttons["showResult"].waitForExistence(timeout:12))
        app.buttons["showResult"].tap()
        app.buttons["renameMeasurement"].tap()
        let name = app.alerts.textFields.firstMatch
        XCTAssertTrue(name.waitForExistence(timeout:3))
        name.tap()
        let old = name.value as? String ?? ""
        name.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:old.count))
        name.typeText("Testmodul Süd")
        app.alerts.buttons["Speichern"].tap()
        XCTAssertTrue(app.staticTexts["Testmodul Süd"].waitForExistence(timeout:3))
        app.terminate()
        app.launch()
        app.tabBars.buttons["Verlauf"].tap()
        let saved = app.staticTexts["Testmodul Süd"].firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout:5))
        saved.tap()
        app.swipeUp(); app.swipeUp(); app.swipeUp()
        let export = app.buttons["exportCSV"]
        if !export.isHittable { app.swipeUp() }
        XCTAssertTrue(export.waitForExistence(timeout:3))
        export.tap()
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout:5) || app.buttons["Copy"].exists || app.buttons["Kopieren"].exists || app.buttons["Close"].exists || app.buttons["Schließen"].exists)
        let shot = XCTAttachment(screenshot:app.screenshot()); shot.name = "Native CSV share sheet"; shot.lifetime = .keepAlways; add(shot)
    }
    @MainActor func testStartScreenAccessibility() throws {
        let app = XCUIApplication(); app.launch()
        try app.performAccessibilityAudit(for:[.contrast,.elementDetection,.sufficientElementDescription,.trait,.hitRegion,.textClipped]) { issue in
            print("ACCESSIBILITY AUDIT: \(issue.compactDescription) | \(issue.detailedDescription) | \(String(describing:issue.element))")
            return false
        }
    }
    @MainActor func testLargestDynamicTypeKeepsMeasurementReachable() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        for _ in 0..<8 {
            let frame = app.buttons["startMeasurement"].frame
            if frame.minY > 110 && frame.maxY < app.frame.maxY - 110 { break }
            app.swipeUp()
        }
        XCTAssertTrue(app.buttons["startMeasurement"].isHittable)
        try app.performAccessibilityAudit(for:[.contrast,.textClipped,.sufficientElementDescription,.hitRegion]) { issue in
            print("LARGE TEXT AUDIT: \(issue.compactDescription) | \(issue.detailedDescription) | \(String(describing:issue.element))")
            // iOS 26's floating tab bar fades scroll-edge content. Contrast sampling
            // of a partially occluded paragraph is not its unobscured text contrast.
            // Keep all other checks, and all contrast checks on fully visible elements.
            if issue.auditType == .contrast, let element = issue.element,
               !app.frame.insetBy(dx:0,dy:110).contains(element.frame) {
                print("Ignoring only contrast sampled at an occluded scroll edge")
                return true
            }
            return false
        }
        let screenshot = XCTAttachment(screenshot:app.screenshot())
        screenshot.name = "Groesste barrierefreie Schrift"; screenshot.lifetime = .keepAlways; add(screenshot)
    }
    @MainActor func testSimulatorDoesNotInventSensorDataWithoutOptIn() {
        let app = XCUIApplication(); app.launch()
        app.buttons["startMeasurement"].tap()
        XCTAssertTrue(app.staticTexts["measurementError"].waitForExistence(timeout:5))
        XCTAssertFalse(app.buttons["showResult"].exists)
    }
}
