import XCTest
@testable import PayPalCommercePlatform

class PPCPayPalCheckoutRequest_Tests: XCTestCase {

    let payPalCheckoutRequest = PPCPayPalCheckoutRequest()

    func testPaymentFlowName() {
        XCTAssertEqual(payPalCheckoutRequest.paymentFlowName(), "paypal-commerce-platform-pwpp")
    }
}
