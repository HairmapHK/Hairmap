import XCTest

final class HairmapLaunchUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchesHairmapShell() {
        let app = XCUIApplication()
        app.launchArguments = ["--hairmap-local-mode"]
        app.launchEnvironment["HAIRMAP_DISABLE_SUPABASE"] = "1"
        app.launch()

        let hairmapTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Hairmap")).firstMatch
        XCTAssertTrue(hairmapTitle.waitForExistence(timeout: 8), "Hairmap title should be visible after launch.")
    }
}
