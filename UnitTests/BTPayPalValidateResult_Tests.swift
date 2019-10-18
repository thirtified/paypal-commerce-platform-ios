import XCTest

class BTPayPalValidateResult_Tests: XCTestCase {

    func testPayPalValidateResult_initializes_withoutContingencyURL() {
        let resultBody = [
            "payment_source": [
                "card": [
                    "last_digits": "1111",
                    "card_type": "VISA"
                ]
            ],
            "links": [
                [
                    "href": "https://api.paypal.com/v2/checkout/orders/order123/authorize",
                    "rel": "authorize",
                    "method": "POST"
                ],
                [
                    "href": "https://api.paypal.com/v2/checkout/orders/order123/capture",
                    "rel": "capture",
                    "method": "POST"
                ]
            ]
        ] as [String : Any]

        let result = BTPayPalValidateResult(json: BTJSON(value: resultBody))

        XCTAssertNil(result.contingencyURL)
    }

    func testPayPalValidateResult_initializesAllProperties_withContingencyURL() {
        let resultBody = [
            "name": "UNPROCESSABLE_ENTITY",
            "details": [
                [
                    "issue": "CONTINGENCY",
                    "description": "Buyer needs to resolve following contingency before proceeding with payment"
                ]
            ],
            "message": "The requested action could not be performed, semantically incorrect, or failed business validation.",
            "links": [
                [
                    "href": "www.contingency.com",
                    "rel": "3ds-contingency-resolution",
                    "method": "GET"
                ],
                [
                    "href": "developer.paypal.com",
                    "rel": "information_link",
                    "method": "GET"
                ]
            ],
            "debug_id": "ae6e6388ea33a",
            "informationLink": "https://developer.paypal.com/docs/api/orders#errors"
        ] as [String : Any]

        let result = BTPayPalValidateResult(json: BTJSON(value: resultBody))

        XCTAssertEqual(result.contingencyURL, URL.init(string: "www.contingency.com"))
        XCTAssertEqual(result.issueType, "CONTINGENCY")
        XCTAssertEqual(result.message, "The requested action could not be performed, semantically incorrect, or failed business validation.")
    }


}
