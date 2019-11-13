import XCTest

class CardCheckout_UITests: XCTestCase {
    var app: XCUIApplication!
    
    func testCapturePayment() {
        app = XCUIApplication()
        app.launchArguments.append("-Capture")
        app.launch()

        // wait for UAT
        let uatExistsPredicate = NSPredicate(format: "label LIKE 'Fetched UAT:*'")
        waitForElementToAppear(app.staticTexts.containing(uatExistsPredicate).element(boundBy: 0))

        // tap Create Order button
        app.buttons["Create Order"].tap()

        // wait for order ID
        let orderExistsPredicate = NSPredicate(format: "label LIKE 'Order ID:*'")
        waitForElementToAppear(app.staticTexts.containing(orderExistsPredicate).element(boundBy: 0))

        // fill out credit card fields
        let cardNumberTextField = app.textFields["Card Number"]
        cardNumberTextField.tap()
        cardNumberTextField.typeText("4000000000000051")

        let expiryTextField = app.textFields["MM/YY"]
        expiryTextField.tap()
        expiryTextField.typeText("01/22")

        let cvvTextField = app.textFields["CVV"]
        cvvTextField.tap()
        cvvTextField.typeText("123")

        // tap submit
        app.buttons["Submit"].tap()

        // TO DO: - the capture order button isn't actually being hit in this test

        // wait for "Capture" button to become enabled
        waitForElementToBeHittable(app.buttons["Capture Order"])
        app.buttons["Capture Order"].forceTapElement()

        // tap "Capture"
        app.buttons["Capture Order"].forceTapElement()

        // Check for success message
        let resultPredicate = NSPredicate(format: "label LIKE 'Fetched UAT:*'")
        XCTAssertTrue(app.staticTexts.containing(resultPredicate).element(boundBy: 0).exists);
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
