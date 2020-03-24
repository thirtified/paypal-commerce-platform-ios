import XCTest
import PayPalCommercePlatform

class PPCValidatorClient_IntegrationTests: XCTestCase {

    // MARK: - Properties

    let payPalAppSwitchSuccessURL = URL(string: PPCIntegrationTestsConstants.sandbox_paypal_app_switch_url)
    var validatorClient: PPCValidatorClient!

    override func setUp() {
        super.setUp()
        self.validatorClient = PPCValidatorClient(accessToken: PPCIntegrationTestsConstants.sandbox_universal_access_token)
    }

    // MARK: - Tests

    func testCheckoutWithCard_returnsSuccessResult() {
        let expectation = self.expectation(description: "Checkout with Card Complete")
        validatorClient.checkoutWithCard(orderID: PPCIntegrationTestsConstants.sandbox_orderId, card: validCard(), completion: { (validatorResult, error) in
            if ((error) != nil) {
                XCTFail()
            }

            XCTAssertEqual(validatorResult?.orderID, PPCIntegrationTestsConstants.sandbox_orderId)
            XCTAssertEqual(validatorResult?.type, .card)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 15.0, handler: nil)
    }

    func testCheckoutWithPayPal_returnsSuccessResult() {
        BTAppSwitch.sharedInstance().returnURLScheme = "com.braintreepayments.Demo.payments"

        let expectation = self.expectation(description: "Checkout with PayPal Complete")
        validatorClient.checkoutWithPayPal(orderID: PPCIntegrationTestsConstants.sandbox_orderId, completion: { (validatorResult, error) in
            if ((error) != nil) {
                XCTFail()
            }

            XCTAssertEqual(validatorResult?.orderID, PPCIntegrationTestsConstants.sandbox_orderId)
            XCTAssertEqual(validatorResult?.type, .payPal)
            expectation.fulfill()
        })

        BTPaymentFlowDriver.handleAppSwitchReturn(payPalAppSwitchSuccessURL!)

        waitForExpectations(timeout: 13.0, handler: nil)
    }

    func testCheckoutWithApplePay_returnsSuccessResult() {
        let expectation = self.expectation(description: "Checkout with ApplePay Complete")
        validatorClient?.checkoutWithApplePay(orderID: PPCIntegrationTestsConstants.sandbox_orderId, paymentRequest: validPKPaymentRequest(), completion: { (validatorResult, error, applePayResultHandler) in
                if ((error) != nil) {
                    XCTFail()
                }

                XCTAssertEqual(validatorResult?.orderID, PPCIntegrationTestsConstants.sandbox_orderId)
                XCTAssertEqual(validatorResult?.type, .applePay)
                XCTAssertNotNil(applePayResultHandler)
                expectation.fulfill()
        })

        let delegate = validatorClient as? PKPaymentAuthorizationViewControllerDelegate
        delegate?.paymentAuthorizationViewController?(PKPaymentAuthorizationViewController(), didAuthorizePayment: PKPayment(), completion: { (_) in })

        waitForExpectations(timeout: 10.0, handler: nil)

    }

    // MARK: - Helpers

    func validCard() -> BTCard {
        return BTCard.init(number: "4111111111111111", expirationMonth: "01", expirationYear: "2022", cvv: "123")
    }

    func validPKPaymentRequest() -> PKPaymentRequest {
        let paymentRequest = PKPaymentRequest()

        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Sock", amount: NSDecimalNumber(string: "10")),
            PKPaymentSummaryItem(label: "Demo", amount: NSDecimalNumber(string: "10")),
        ]

        return paymentRequest
    }

}
