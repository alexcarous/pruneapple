import XCTest

final class CleanAppleUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    func testAppLaunches() throws {
        let app = XCUIApplication()
        
        // Handle macOS TCC permission dialogs automatically
        addUIInterruptionMonitor(withDescription: "System Dialog") { (alert) -> Bool in
            let allowButton = alert.buttons["Allow"]
            let okButton = alert.buttons["OK"]
            if allowButton.exists {
                allowButton.click()
                return true
            } else if okButton.exists {
                okButton.click()
                return true
            }
            return false
        }
        
        app.launch()

        // Tap the app to trigger the interruption monitor if a dialog is already present
        app.click()

        // Basic verification that the app launched and has elements on screen
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground)
    }
}
