import XCTest

class BTPayPalValidatorClient_Tests: XCTestCase {

    func testValidatorClientInitialization_withUAT_withOrderId_initializes() {
        let validatorClient = BTPayPalValidatorClient.init(accessToken: "header.payload.signature", orderId: "order123")
        XCTAssertNotNil(validatorClient);
    }

    func testValidatorClientInitialization_withInvalidUAT_returnsNil() {
        let validatorClient = BTPayPalValidatorClient.init(accessToken: "invalidUAT", orderId: "order123")
        XCTAssertNil(validatorClient);
    }
}
