import XCTest

final class CoverCraftUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsPrimaryControls() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["CoverCraft"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["covercraft.inputModePicker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["covercraft.startScanButton"].exists)

        let generateButton = app.buttons["covercraft.generatePatternButton"]
        scrollToElement(generateButton, in: app)
        XCTAssertTrue(generateButton.exists)
        XCTAssertFalse(generateButton.isEnabled)
    }

    @MainActor
    func testManualDimensionsRequireEntryBeforeGenerate() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_MANUAL_MODE"]
        app.launch()

        let generateButton = app.buttons["covercraft.generatePatternButton"]
        scrollToElement(generateButton, in: app)
        XCTAssertTrue(generateButton.exists)
        XCTAssertFalse(generateButton.isEnabled)
        XCTAssertTrue(app.staticTexts["covercraft.manualCalibrationNote"].exists)
    }

    @MainActor
    func testManualDimensionsWorkflowShowsExportView() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_MANUAL_MODE", "UITEST_MANUAL_READY"]
        app.launch()

        openExportViewFromManualMode(in: app)
        XCTAssertTrue(app.navigationBars["Export"].exists)
    }

    @MainActor
    func testManualDimensionsWorkflowExportsPattern() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_MANUAL_MODE", "UITEST_MANUAL_READY", "UITEST_RESET_EXPORTS", "UITEST_AUTO_EXPORT"]
        app.launch()

        openExportViewFromManualMode(in: app)

        let statusMessage = app.staticTexts["covercraft.exportStatusMessage"]
        XCTAssertTrue(statusMessage.waitForExistence(timeout: 15))
        XCTAssertTrue(statusMessage.label.contains("Saved to CoverCraft Patterns/"))
    }

    @MainActor
    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 6) {
        var swipes = 0

        while !element.exists && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }

        while !element.isHittable && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
    }

    @MainActor
    private func openExportViewFromManualMode(in app: XCUIApplication) {
        let generateButton = app.buttons["covercraft.generatePatternButton"]
        scrollToElement(generateButton, in: app)
        XCTAssertTrue(generateButton.exists)
        XCTAssertTrue(generateButton.isEnabled)
        XCTAssertTrue(app.staticTexts["covercraft.manualCalibrationNote"].exists)

        generateButton.tap()

        let exportButton = app.buttons["covercraft.exportPatternLink"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 10))
        exportButton.tap()
    }
}
