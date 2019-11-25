import Foundation

class MockPayPalAPIClient: PPCAPIClient {

    var validationResult: PPCValidationResult?
    var validationError: Error?

    override func validatePaymentMethod(_ paymentMethod: BTPaymentMethodNonce, forOrderId orderId: String, completion: @escaping (PPCValidationResult?, Error?) -> Void) {
        completion(validationResult, validationError)
    }
}
