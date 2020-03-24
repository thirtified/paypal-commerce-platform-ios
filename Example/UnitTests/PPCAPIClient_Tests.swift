import XCTest
@testable import PayPalCommercePlatform

class PPCAPIClient_Tests: XCTestCase {
  
    let uatParams: [String : Any] = [
        "iss": "https://api.sandbox.paypal.com",
        "sub": "PayPal:fake-pp-merchant",
        "acr": [
            "client"
        ],
        "scopes": [
            "Braintree:Vault"
        ],
        "exp": 1571980506,
        "external_ids": [
            "PayPal:fake-pp-merchant",
            "Braintree:fake-bt-merchant"
        ],
        "jti": "fake-jti"
    ]
    
    var uatString: String!
    var payPalAPIClient: PPCAPIClient!
    var mockBTAPIClient: MockBTAPIClient!
    
    let nonce = BTPayPalAccountNonce(nonce: "paypal-nonce", localizedDescription: "PayPal Account Nonce")!
    let mockURLSession = MockURLSession()
    
    override func setUp() {
        super.setUp()
        uatString = PayPalUATTestHelper.encodeUAT(uatParams)
        mockBTAPIClient = MockBTAPIClient(authorization: uatString)
        
        payPalAPIClient = PPCAPIClient(accessToken: uatString)!
        payPalAPIClient.urlSession = mockURLSession
        payPalAPIClient.braintreeAPIClient = mockBTAPIClient
    }
    
    // MARK: - initialization

    func testInitWithAccessToken_returnsAPIClient() {
        XCTAssertNotNil(PPCAPIClient(accessToken: uatString))
    }
    
    func testInitWithInvalidAccessToken_returnsNil() {
        XCTAssertNil(PPCAPIClient(accessToken: "invalid-token"))
    }

    // MARK: -  validatePaymentMethod

    func testValidatePaymentMethod_constructsURLRequest_with3DSRequested() {
        let expectation = self.expectation(description: "Calls URLSession with URLRequest")

        mockURLSession.data = try! BTJSON().asJSON()
        mockURLSession.urlResponse = HTTPURLResponse(url: URL(string: "www.example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)

        mockURLSession.onDataTaskWithRequest = { request in
            guard let body = request.httpBody else { XCTFail(); return }
            
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "https://api.sandbox.paypal.com/v2/checkout/orders/order-id/validate-payment-method")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.uatString!)")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(body, try! BTJSON(withJSONFile: "paypal-validate-request-with-3ds")?.asJSON())
            expectation.fulfill()
        }

        payPalAPIClient.validatePaymentMethod(nonce, forOrderId: "order-id", with3DS: true, completion: { _, _ in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testValidatePaymentMethod_constructsURLRequest_without3DSRequested() {
        let expectation = self.expectation(description: "Calls URLSession with URLRequest")

        mockURLSession.data = try! BTJSON().asJSON()
        mockURLSession.urlResponse = HTTPURLResponse(url: URL(string: "www.example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)

        mockURLSession.onDataTaskWithRequest = { request in
            guard let body = request.httpBody else { XCTFail(); return }

            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "https://api.sandbox.paypal.com/v2/checkout/orders/order-id/validate-payment-method")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.uatString!)")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(body, try! BTJSON(withJSONFile: "paypal-validate-request-without-3ds")?.asJSON())
            expectation.fulfill()
        }

        payPalAPIClient.validatePaymentMethod(nonce, forOrderId: "order-id", with3DS: false, completion: { _, _ in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testValidatePaymentMethod_whenResponseCodeIs200_callsCompletionWithValidationResult() {
        let expectation = self.expectation(description: "Calls completion with PPCValidationResult")

        mockURLSession.data = try! BTJSON(withJSONFile: "paypal-validation-response-without-contingency")?.asJSON()
        mockURLSession.urlResponse = HTTPURLResponse(url: URL(string: "www.example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)

        payPalAPIClient.validatePaymentMethod(nonce, forOrderId: "order-id", with3DS: false) { (result, error) in
            XCTAssertNotNil(result)
            XCTAssertNil(result?.contingencyURL)
            XCTAssertNil(error)
            XCTAssertTrue(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.validate.succeeded"))
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testValidatePaymentMethod_whenResponseCodeIs422_andContingencyIsPresent_callsCompletionWithValidationResult() {
        let expectation = self.expectation(description: "Calls completion with PPCValidationResult")

        mockURLSession.data = try! BTJSON(withJSONFile: "paypal-validation-response-with-contingency")?.asJSON()
        mockURLSession.urlResponse = HTTPURLResponse(url: URL(string: "www.example.com")!, statusCode: 422, httpVersion: nil, headerFields: nil)

        payPalAPIClient.validatePaymentMethod(nonce, forOrderId: "order-id", with3DS: true) { (result, error) in
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.contingencyURL?.absoluteString, "www.contingency.com")
            XCTAssertEqual(result?.issueType, "CONTINGENCY")
            XCTAssertEqual(result?.message, "The requested action could not be performed, semantically incorrect, or failed business validation.")
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testValidatePaymentMethod_whenResponseCodeIs422_andCardExpiredResponse_callsCompletionWithError() {
        let expectation = self.expectation(description: "Calls completion with error")

        mockURLSession.data = try! BTJSON(withJSONFile: "paypal-validation-response-card-expired")?.asJSON()
        mockURLSession.urlResponse = HTTPURLResponse(url: URL(string: "www.example.com")!, statusCode: 422, httpVersion: nil, headerFields: nil)

        payPalAPIClient.validatePaymentMethod(nonce, forOrderId: "order-id", with3DS: false) { (result, error) in
            XCTAssertNil(result)
            XCTAssertEqual(error?.localizedDescription, "CARD_EXPIRED")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testValidatePaymentMethod_whenResponseCodeIs403_andInvalidTokenResponse_callsCompletionWithError() {
        let expectation = self.expectation(description: "Calls completion with error")

        mockURLSession.data = try! BTJSON(withJSONFile: "paypal-validation-response-invalid-token")?.asJSON()
        mockURLSession.urlResponse = HTTPURLResponse(url: URL(string: "www.example.com")!, statusCode: 403, httpVersion: nil, headerFields: nil)

        payPalAPIClient.validatePaymentMethod(nonce, forOrderId: "order-id", with3DS: false) { (result, error) in
            XCTAssertNil(result)
            XCTAssertEqual(error?.localizedDescription, "Token signature verification failed")
            XCTAssertTrue(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.validate.failed"))
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testValidatePaymentMethod_whenValidateFailsWithError_callsCompletionWithError() {
        let expectation = self.expectation(description: "Calls completion with error")

        mockURLSession.data = nil
        mockURLSession.urlResponse = nil
        mockURLSession.error = NSError(domain: "Some error domain", code: 5, userInfo: [NSLocalizedDescriptionKey: "An error occurred"])

        payPalAPIClient.validatePaymentMethod(nonce, forOrderId: "order-id", with3DS: false) { (result, error) in
            XCTAssertNil(result)
            XCTAssertEqual(error?.localizedDescription, "An error occurred")
            XCTAssertTrue(self.mockBTAPIClient.postedAnalyticsEvents.contains("ios.paypal-commerce-platform.validate.failed"))
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    // MARK: - fetchPayPalApproveURL
    
    func testFetchPayPalApproveURL_constructsURLRequest_withOrderId() {
        let expectation = self.expectation(description: "Calls URLSession with URL containing order id")

        mockURLSession.data = try! BTJSON().asJSON()
        
        mockURLSession.onDataTaskWithRequest = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.absoluteString, "https://api.sandbox.paypal.com/v2/checkout/orders/some-order-id")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(self.uatString!)")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            expectation.fulfill()
        }

        payPalAPIClient.fetchPayPalApproveURL(forOrderId: "some-order-id", completion: {_, _ in })

        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testFetchPayPalApproveURL_whenConstructingURLFails_callsCompletionWithError() {
        let expectation = self.expectation(description: "Calls completion with URL creation error")

        payPalAPIClient.fetchPayPalApproveURL(forOrderId: "invalid order id", completion: { url, error in
            XCTAssertNil(url)
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.localizedDescription, "Checkout with PayPal failed. Unable to fetch approve url.")
            expectation.fulfill()
        })

        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testFetchPayPalApproveURL_whenRequestIsSuccessful_callsCompletionWithURL() {
        let expectation = self.expectation(description: "Calls completion with approveURL")
        
        mockURLSession.data = try! BTJSON(value: [
            "links": [
                [
                    "rel": "approve",
                    "href": "www.some-paypal-checkout-url.com"
                ]
            ]
        ]).asJSON()
        
        payPalAPIClient.fetchPayPalApproveURL(forOrderId: "my-order-id") { (url, error) in
            XCTAssertNil(error)
            XCTAssertEqual(url?.absoluteString, "www.some-paypal-checkout-url.com")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testFetchPayPalApproveURL_whenResponseIsMalformed_callsCompletionWithError() {
        let expectation = self.expectation(description: "Calls completion with malformed response error")
        
        mockURLSession.data = try! BTJSON(value: []).asJSON()
        
        payPalAPIClient.fetchPayPalApproveURL(forOrderId: "my-order-id") { (url, error) in
            XCTAssertNil(url)
            XCTAssertEqual(error?.localizedDescription, "Checkout with PayPal failed. Malformed response from /orders/v2 endpoint.")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testFetchPayPalApproveURL_whenRequestFails_callsCompletionWithError() {
        let expectation = self.expectation(description: "Calls completion with request failed error")
        
        mockURLSession.error = NSError(domain: "My Error", code: 0, userInfo: [NSLocalizedDescriptionKey : "Test Error"])
        
        payPalAPIClient.fetchPayPalApproveURL(forOrderId: "my-order-id") { (url, error) in
            XCTAssertNil(url)
            XCTAssertEqual(error?.localizedDescription, "Test Error")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
