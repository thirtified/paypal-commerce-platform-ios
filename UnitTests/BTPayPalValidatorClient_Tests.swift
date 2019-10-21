import XCTest

class BTPayPalValidatorClient_Tests: XCTestCase {

    func testValidatorClientInitialization_withUAT_withOrderId_initializes() {
        let validatorClient = BTPayPalValidatorClient.init(accessToken: "header.payload.signature", orderId: "order123")
        XCTAssertNotNil(validatorClient)
    }

    func testValidatorClientInitialization_withInvalidUAT_returnsNil() {
        let validatorClient = BTPayPalValidatorClient.init(accessToken: "invalidUAT", orderId: "order123")
        XCTAssertNotNil(validatorClient.applePayClient)
        XCTAssertNil(validatorClient)
    }
    
    // MARK - checkoutWithApplePay
    
    func testCheckoutWithApplePay_whenDefaultPaymentRequestIsAvailable_requestsPresentationOfViewController() {
        let mockApplePayClient = MockApplePayClient(apiClient: BTAPIClient(authorization: "development_testing_integration_merchant_id")!)
        mockApplePayClient.paymentRequest = PKPaymentRequest()
        
        let validatorClient = BTPayPalValidatorClient(accessToken: "header.payload.signature", orderId: "order123")
        let expectation = self.expectation(description: "passes Apple Pay view controller to merchant")
        
        let mockViewControllerPresentingDelegate = MockViewControllerPresentingDelegate()
        mockViewControllerPresentingDelegate.requestsPresentationHandler = { driver, viewController in
            XCTAssertEqual(driver as? BTPayPalValidatorClient, validatorClient)
            XCTAssertNotNil(viewController)
            XCTAssertTrue(viewController is PKPaymentAuthorizationViewController)
            expectation.fulfill()
        }
        
        validatorClient.checkoutWithApplePay(PKPaymentRequest(), presentingDelegate: mockViewControllerPresentingDelegate) { (_, _, _) in
            // not called
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
