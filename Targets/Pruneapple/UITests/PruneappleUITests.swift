import XCTest

final class PruneappleUITests: XCTestCase {
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

        // Wait up to 5 seconds for the app to reach the foreground state
        let isForeground = app.wait(for: .runningForeground, timeout: 5.0)
        XCTAssertTrue(isForeground, "The application failed to launch into the foreground.")
    }
}
