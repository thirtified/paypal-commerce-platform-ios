import Foundation
import XCTest

class PPCValidatorClient_IntegrationTests: XCTestCase {

    // MARK: - Properties

    let payPalAppSwitchSuccessURL = URL(string: "com.braintreepayments.demo.payments://x-callback-url/braintree/paypal-checkout?PayerID=V3M74ABWW6BE2&intent=sale&opType=payment&token=6WV18388K13273039")
    var validatorClient: PPCValidatorClient!

    // TODO: - Currently, these UAT and orderID expire, so you need
    // to update them each time you work on these tests.
    // Obtain test UAT and orderID from PP folks.
    let uat = "eyJraWQiOiI1NTY1MWVhZWE0MjZjZDVhMjM5ZWU0ZjUwMTczMDk3NmI2YzMxZmNkIiwidHlwIjoiSldUIiwiYWxnIjoiRVMyNTYifQ.eyJpc3MiOiJodHRwczovL2FwaS5wYXlwYWwuY29tIiwic3ViIjoiUGF5UGFsOlc1Skw2VlVKVTlUTUwiLCJhY3IiOlsiY2xpZW50Il0sIm9wdGlvbnMiOnt9LCJheiI6Im1zbWFzdGVyMWludC1nX2lkZW50aXR5c2VjdXJldG9rZW5zZXJ2XzkucWEiLCJzY29wZXMiOlsiQnJhaW50cmVlOlZhdWx0Il0sImV4cCI6MTU3NDM4MzczNywiZXh0ZXJuYWxfaWRzIjpbIlBheVBhbDpXNUpMNlZVSlU5VE1MIiwiQnJhaW50cmVlOm15bWt5Mm12eDVteWo1eXoiXSwianRpIjoiVTJBQUZUOEIwaWtKUUI2QW9OcjJ0c1M2LWdORGI2MGRnQ2lPN1Rzc2VSalUyeGtrUExYQXRGcnFHZmVhRDF2cVZMYXJsY1lPd05iU1htdk5kNi1GcVJmZTNzMkk2ODdLUkxnbzlJcE9uQVl1b1ZjbFlXMjJwTVlUN3IySmh1NHcifQ.o3BqSjT2jP2BzSLhlpmKjB_OKgcdgiFHnoqpeKS8TBSEKCCick-3EUOhizTr01Lco-B5tsYLu_z_EY56rkY5Yw"
    var testOrderID = "8NS005712X189603Y"

    override func setUp() {
        super.setUp()
        self.validatorClient = PPCValidatorClient(accessToken: self.uat)
    }

    // MARK: - Tests

    func testCheckoutWithCard_returnsSuccessResult() {
        let expectation = self.expectation(description: "Checkout with Card Complete")
        validatorClient.checkoutWithCard(testOrderID, card: validCard(), completion: { (validatorResult, error) in
            if ((error) != nil) {
                XCTFail()
            }

            XCTAssertEqual(validatorResult?.orderID, self.testOrderID)
            XCTAssertEqual(validatorResult?.type, .card)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 15.0, handler: nil)
    }

    func testCheckoutWithPayPal_returnsSuccessResult() {
        BTAppSwitch.sharedInstance().returnURLScheme = "com.braintreepayments.Demo.payments"

        let expectation = self.expectation(description: "Checkout with PayPal Complete")
        validatorClient.checkoutWithPayPal(testOrderID, completion: { (validatorResult, error) in
            if ((error) != nil) {
                XCTFail()
            }

            XCTAssertEqual(validatorResult?.orderID, self.testOrderID)
            XCTAssertEqual(validatorResult?.type, .payPal)
            expectation.fulfill()
        })

        BTPaymentFlowDriver.handleAppSwitchReturn(payPalAppSwitchSuccessURL!)

        waitForExpectations(timeout: 13.0, handler: nil)
    }

    func testCheckoutWithApplePay_returnsSuccessResult() {
        let expectation = self.expectation(description: "Checkout with ApplePay Complete")
        validatorClient?.checkoutWithApplePay(self.testOrderID, paymentRequest: validPKPaymentRequest(), completion: { (validatorResult, error, applePayResultHandler) in
                if ((error) != nil) {
                    XCTFail()
                }

                XCTAssertEqual(validatorResult?.orderID, self.testOrderID)
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
