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
}
