import XCTest

class PPCAPIClient_Tests: XCTestCase {

    let payPalAPIClient = PPCAPIClient(accessToken: "123.123.123")
    let nonce = BTPayPalAccountNonce(nonce: "paypal-nonce", localizedDescription: "PayPal Account Nonce")!
    let mockURLSession = MockURLSession()
    
    override func setUp() {
        super.setUp()
        mockURLSession.error = nil
        payPalAPIClient.urlSession = mockURLSession
    }
    
    // MARK: - initialization

    func testInitWithAccessToken_setsAccessToken() {
        XCTAssertEqual(payPalAPIClient.accessToken, "123.123.123")
    }

    // MARK: -  validatePaymentMethod

    func testValidatePaymentMethod_constructsURLRequest_with3DSRequested() {
        let expectation = self.expectation(description: "Calls URLSession with URLRequest")

        mockURLSession.data = try! BTJSON().asJSON()
        mockURLSession.urlResponse = HTTPURLResponse(url: URL(string: "www.example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)

        mockURLSession.onDataTaskWithRequest = { request in
            guard let body = request.httpBody else { XCTFail(); return }
            
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.absoluteString, "https://api.ppcpn.stage.paypal.com/v2/checkout/orders/order-id/validate-payment-method")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer 123.123.123")
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
            XCTAssertEqual(request.url?.absoluteString, "https://api.ppcpn.stage.paypal.com/v2/checkout/orders/order-id/validate-payment-method")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer 123.123.123")
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
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }
}