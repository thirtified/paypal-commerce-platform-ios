import XCTest
import PayPalCommercePlatform

class PPCOrderDetails_Tests: XCTestCase {

    func testInitWithJSON_whenApproveURLIsPresent_returnsOrderDetails() {
        let orderDetails = PPCOrderDetails(json: BTJSON(value: [
            "links": [
                [
                    "rel": "approve",
                    "href": "www.some-paypal-checkout-url.com"
                ]
            ]
        ]))
        XCTAssertNotNil(orderDetails)
        XCTAssertEqual(orderDetails?.approveURL.absoluteString, "www.some-paypal-checkout-url.com")
    }
    
    func testInitWithJSON_whenJSONDoesNotContainExpectedData_returnsNil() {
        XCTAssertNil(PPCOrderDetails(json: BTJSON(value: [])))
        XCTAssertNil(PPCOrderDetails(json: BTJSON(value: [:])))
        XCTAssertNil(PPCOrderDetails(json: BTJSON(value: ["links": "random string"])))
        XCTAssertNil(PPCOrderDetails(json: BTJSON(value: ["links": [1, 2, 3]])))
        XCTAssertNil(PPCOrderDetails(json: BTJSON(value: ["links": [["rel": 1]]])))
        XCTAssertNil(PPCOrderDetails(json: BTJSON(value: ["links": [["rel": "approve"]]])))
        XCTAssertNil(PPCOrderDetails(json: BTJSON(value: ["links": [["rel": "approve", "href": 100]]])))
        XCTAssertNil(PPCOrderDetails(json: BTJSON(value: ["links": [["rel": "approve", "href": "invalid url"]]])))
    }
}
