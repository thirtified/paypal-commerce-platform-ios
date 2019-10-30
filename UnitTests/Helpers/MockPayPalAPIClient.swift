import Foundation

class MockPayPalAPIClient: BTPayPalAPIClient {

    var validateResult: BTPayPalValidateResult?
    var validateError: Error?

    override func validatePaymentMethod(_ paymentMethod: BTPaymentMethodNonce, forOrderId orderId: String, completion: @escaping (BTPayPalValidateResult?, Error?) -> Void) {
        completion(validateResult, validateError)
    }
}
