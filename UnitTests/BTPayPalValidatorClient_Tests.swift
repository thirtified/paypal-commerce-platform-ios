import XCTest

class BTPayPalValidatorClient_Tests: XCTestCase {

    let validatorClient = BTPayPalValidatorClient(accessToken: "header.payload.signature")
    let mockApplePayClient = MockApplePayClient(apiClient: BTAPIClient(authorization: "development_testing_integration_merchant_id")!)
    let mockPayPalAPIClient = MockPayPalAPIClient()
    let mockViewControllerPresentingDelegate = MockViewControllerPresentingDelegate()
    let paymentRequest = PKPaymentRequest()

    override func setUp() {
        validatorClient.applePayClient = mockApplePayClient
        validatorClient.payPalAPIClient = mockPayPalAPIClient

        let defaultPaymentRequest = PKPaymentRequest()
        defaultPaymentRequest.countryCode = "US"
        defaultPaymentRequest.currencyCode = "USD"
        defaultPaymentRequest.merchantIdentifier = "merchant-id"
        defaultPaymentRequest.supportedNetworks = [PKPaymentNetwork.visa]
        mockApplePayClient.paymentRequest = defaultPaymentRequest

        let applePayCardNonce = BTApplePayCardNonce(nonce: "apple-pay-nonce", localizedDescription: "a great nonce")
        mockApplePayClient.applePayCardNonce = applePayCardNonce

        paymentRequest.paymentSummaryItems = [PKPaymentSummaryItem(label: "item", amount: 1.00)]
        paymentRequest.merchantCapabilities = PKMerchantCapability.capabilityCredit
    }

    // MARK: - validatorClient init

    func testValidatorClientInitialization_withUAT_withOrderId_initializes() {
        XCTAssertNotNil(validatorClient)
    }

    func testValidatorClientInitialization_withInvalidUAT_returnsNil() {
        let validatorClient = BTPayPalValidatorClient(accessToken: "invalidUAT")
        XCTAssertNil(validatorClient)
    }
    
    // MARK: - checkoutWithApplePay
    
    func testCheckoutWithApplePay_whenDefaultPaymentRequestIsAvailable_requestsPresentationOfViewController() {
        let expectation = self.expectation(description: "passes Apple Pay view controller to merchant")
        
        mockViewControllerPresentingDelegate.requestsPresentationHandler = { driver, viewController in
            XCTAssertEqual(driver as? BTPayPalValidatorClient, self.validatorClient)
            XCTAssertNotNil(viewController)
            XCTAssertTrue(viewController is PKPaymentAuthorizationViewController)
            expectation.fulfill()
        }

        validatorClient.checkoutWithApplePay("my-order-id", paymentRequest: paymentRequest, presentingDelegate: mockViewControllerPresentingDelegate) { (_, _, _) in
            // not called
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCheckoutWithApplePay_whenDefaultPaymentRequestIsNotAvailable_returnsError() {
        self.mockApplePayClient.paymentRequestError = NSError(domain: "error", code: 0, userInfo: [NSLocalizedDescriptionKey: "error message"])
        self.mockApplePayClient.paymentRequest = nil

        let expectation = self.expectation(description: "returns Apple Pay error to merchant")

        validatorClient.checkoutWithApplePay("my-order-id", paymentRequest: PKPaymentRequest(), presentingDelegate: self.mockViewControllerPresentingDelegate) { (validatorResult, error, handler) in
            XCTAssertEqual(error?.localizedDescription, "error message")
            XCTAssertNil(validatorResult)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - paymentAuthorizationViewControllerDidAuthorizePayment (iOS 11+)

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_callsCompletionWithValidatorResult() {
        let expectation = self.expectation(description: "payment authorization delegate calls completion with validator result")

        mockPayPalAPIClient.validateResult = BTPayPalValidateResult()

        validatorClient.checkoutWithApplePay("fake-order", paymentRequest: paymentRequest, presentingDelegate: mockViewControllerPresentingDelegate) { (validatorResult, error, handler) in
            XCTAssertEqual(validatorResult?.orderID, "fake-order")
            XCTAssertEqual(validatorResult?.type, .applePay)
            XCTAssertNil(error)
            // TODO - test that handler is called correctly
            expectation.fulfill()
        }

        let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), handler: { _ in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenApplePayTokenizationFails_callsCompletionWithError() {
        let expectation = self.expectation(description: "payment authorization delegate calls completion with error")

        mockApplePayClient.applePayCardNonce = nil
        mockApplePayClient.tokenizeError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "error message"])

        validatorClient.checkoutWithApplePay("fake-order", paymentRequest: paymentRequest, presentingDelegate: mockViewControllerPresentingDelegate) { (validatorResult, error, handler) in
            XCTAssertNil(validatorResult)
            XCTAssertEqual(error?.localizedDescription, "error message")
            expectation.fulfill()
        }

        let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), handler: { _ in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenApplePayValidationFails_callsCompletionWithError() {
        let expectation = self.expectation(description: "payment authorization delegate calls completion with error")

        mockPayPalAPIClient.validateError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "error message"])
        mockPayPalAPIClient.validateResult = nil

        validatorClient.checkoutWithApplePay("fake-order", paymentRequest: paymentRequest, presentingDelegate: mockViewControllerPresentingDelegate) { (validatorResult, error, handler) in
            XCTAssertNil(validatorResult)
            XCTAssertEqual(error?.localizedDescription, "error message")
            expectation.fulfill()
        }

        let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), handler: { _ in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - paymentAuthorizationViewControllerDidAuthorizePayment (pre iOS 11)

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_callsCompletionWithValidatorResult_preiOS11() {
        let expectation = self.expectation(description: "payment authorization delegate calls completion with validator result")

        mockPayPalAPIClient.validateResult = BTPayPalValidateResult()

        validatorClient.checkoutWithApplePay("fake-order", paymentRequest: paymentRequest, presentingDelegate: mockViewControllerPresentingDelegate) { (validatorResult, error, handler) in
            XCTAssertEqual(validatorResult?.orderID, "fake-order")
            XCTAssertEqual(validatorResult?.type, .applePay)
            XCTAssertNil(error)
            // TODO - test that handler is called correctly
            expectation.fulfill()
        }

        let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), completion: { (_) in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenApplePayTokenizationFails_callsCompletionWithError_preiOS11() {
        let expectation = self.expectation(description: "payment authorization delegate calls completion with error")

        mockApplePayClient.applePayCardNonce = nil
        mockApplePayClient.tokenizeError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "error message"])

        validatorClient.checkoutWithApplePay("fake-order", paymentRequest: paymentRequest, presentingDelegate: mockViewControllerPresentingDelegate) { (validatorResult, error, handler) in
            XCTAssertNil(validatorResult)
            XCTAssertEqual(error?.localizedDescription, "error message")
            expectation.fulfill()
        }

        let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), completion: { (_) in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPaymentAuthorizationViewControllerDidAuthorizePayment_whenApplePayValidationFails_callsCompletionWithError_preiOS11() {
        let expectation = self.expectation(description: "payment authorization delegate calls completion with error")

        mockPayPalAPIClient.validateError = NSError(domain: "some-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "error message"])
        mockPayPalAPIClient.validateResult = nil

        validatorClient.checkoutWithApplePay("fake-order", paymentRequest: paymentRequest, presentingDelegate: mockViewControllerPresentingDelegate) { (validatorResult, error, handler) in
            XCTAssertNil(validatorResult)
            XCTAssertEqual(error?.localizedDescription, "error message")
            expectation.fulfill()
        }

        let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), completion: { (_) in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
