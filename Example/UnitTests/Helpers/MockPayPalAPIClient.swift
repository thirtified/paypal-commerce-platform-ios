@testable import PayPalCommercePlatform

class MockPayPalAPIClient: PPCAPIClient {

    var validationResult: PPCValidationResult?
    var validationError: Error?
    
    var approveURL: URL?
    var approveURLError: Error?

    override func validatePaymentMethod(_ paymentMethod: BTPaymentMethodNonce, forOrderId orderId: String, with3DS isThreeDSecureRequired: Bool, completion: @escaping (PPCValidationResult?, Error?) -> Void) {
        completion(validationResult, validationError)
    }
    
    override func fetchPayPalApproveURL(forOrderId orderId: String, completion: @escaping (URL?, Error?) -> Void) {
        completion(approveURL, approveURLError)
    }
}
