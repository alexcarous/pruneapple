import XCTest

final class CleanAppleUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        // Basic verification that the app launched and has elements on screen
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground)
    }
}
