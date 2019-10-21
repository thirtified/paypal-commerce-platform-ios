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
    
    func testCheckoutWithApplePay_whenDefaultPaymentRequestIsNotAvailable_returnsError() {
        let mockApplePayClient = MockApplePayClient(apiClient: BTAPIClient(authorization: "development_testing_integration_merchant_id")!)
        mockApplePayClient.error = NSError(domain: "error", code: 0, userInfo: [NSLocalizedDescriptionKey: "error message"])
        
        let validatorClient = BTPayPalValidatorClient(accessToken: "header.payload.signature", orderId: "order123")
        let expectation = self.expectation(description: "returns Apple Pay error to merchant")
        
        let mockViewControllerPresentingDelegate = MockViewControllerPresentingDelegate()

        validatorClient.checkoutWithApplePay(PKPaymentRequest(), presentingDelegate: mockViewControllerPresentingDelegate) { (validatorResult, error, handler) in
            XCTAssertEqual(error?.localizedDescription, "error message")
            XCTAssertNil(validatorResult)
            XCTAssertNil(handler)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
