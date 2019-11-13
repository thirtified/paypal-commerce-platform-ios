import XCTest

class CardCheckout_UITests: XCTestCase {
    var app: XCUIApplication!
    
    func testCapturePayment() {
        app = XCUIApplication()
        app.launchArguments.append("-Capture")
        app.launch()
                
        waitForElementToAppear(app.textFields.containing(NSPredicate(format: "label LIKE 'Fetched UAT:*'")).element)
    
        
        // wait for UAT
        // tap Create Order button
        // wait for order ID
        // fill out credit card fields
        // tap submit
        // wait for "Capture" button to become enabled
        // tap "Capture"
        // Check for success message
    }
    
    func testAuthorizePayment() {
        app = XCUIApplication()
        app.launchArguments.append("-Authorize")
        self.app.launch()
        
        // wait for UAT
        // tap Create Order button
        // wait for order ID
        // fill out credit card fields
        // tap submit
        // wait for "Capture" button to become enabled
        // tap "Capture"
        // Check for success message
    }
}
