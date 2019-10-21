import Foundation

class MockApplePayClient: BTApplePayClient {
    
    var paymentRequest: PKPaymentRequest?
    var error: Error?
    
    override func paymentRequest(_ completion: @escaping (PKPaymentRequest?, Error?) -> Void) {
        completion(paymentRequest, error)
    }
}
