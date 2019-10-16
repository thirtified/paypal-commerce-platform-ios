import XCTest

class BTPayPalAPIClient_Tests: XCTestCase {

    func testAPIClientInitialization_withValidUAT_returnsClientWithTokenizationKey() {
        let apiClient = BTPayPalAPIClient.init(accessToken: "123.123.123")
        XCTAssertEqual(apiClient.accessToken, "123.123.123")
    }

    func testAPIClient_constructTokenizePayload() {
        let apiClient = BTPayPalAPIClient.init(accessToken: "123.123.123")
        let validatePayload = apiClient.constructValidatePayload("fake-nonce") as NSObject?

        let expectedPayload = [
            "payment_source": [
                "token": [
                    "id": "fake-nonce",
                    "type": "NONCE"
                ],
                "contingencies": [
                    "3D_SECURE"
                ]
            ]
            ] as NSObject

        XCTAssertEqual(validatePayload, expectedPayload)
    }

    func testAPIClient_createValidateURLRequest() {
        let apiClient = BTPayPalAPIClient.init(accessToken: "123.123.123")
        let url = URL.init(string: "www.example.com")
        let urlRequest = try! apiClient.createValidateURLRequest(url!, withPaymentMethodNonce: "fake-nonce")

        let expectedHeaders = [
            "Authorization" : "Bearer 123.123.123",
            "Content-Type": "application/json"
        ]

        XCTAssertEqual(urlRequest.url, url)
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, expectedHeaders)
        guard let httpBody = urlRequest.httpBody else {
            XCTFail()
            return
        }
        XCTAssertGreaterThan(httpBody.count, 0)
    }

}
