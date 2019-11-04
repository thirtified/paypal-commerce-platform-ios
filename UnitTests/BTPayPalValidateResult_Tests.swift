import XCTest

class BTPayPalValidateResult_Tests: XCTestCase {

    func testPayPalValidateResult_initializes_withoutContingencyURL() {
        let result = BTPayPalValidateResult(json: BTJSON(withJSONFile: "paypal-validate-response-without-contingency")!)
        XCTAssertNil(result.contingencyURL)
    }

    func testPayPalValidateResult_initializesAllProperties_withContingencyURL() {
        let result = BTPayPalValidateResult(json: BTJSON(withJSONFile: "paypal-validate-response-with-contingency")!)

        XCTAssertEqual(result.contingencyURL, URL(string: "www.contingency.com"))
        XCTAssertEqual(result.issueType, "CONTINGENCY")
        XCTAssertEqual(result.message, "The requested action could not be performed, semantically incorrect, or failed business validation.")
    }

    func testPayPalValidateResult_initializesSomeProperties_withExpiredCardResult() {
        let result = BTPayPalValidateResult(json: BTJSON(withJSONFile: "paypal-validate-response-card-expired")!)

        XCTAssertEqual(result.contingencyURL, nil)
        XCTAssertEqual(result.issueType, "CARD_EXPIRED")
        XCTAssertEqual(result.message, "The requested action could not be performed, semantically incorrect, or failed business validation.")
    }

    func testPayPalValidateResult_initializesSomeProperties_withInvalidToken() {
        let result = BTPayPalValidateResult(json: BTJSON(withJSONFile: "paypal-validate-response-invalid-token")!)

        XCTAssertEqual(result.contingencyURL, nil)
        XCTAssertEqual(result.issueType, "")
        XCTAssertEqual(result.message, "Token signature verification failed")
    }
}
