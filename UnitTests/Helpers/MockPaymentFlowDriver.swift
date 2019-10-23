import Foundation

class MockPaymentFlowDriver: BTPaymentFlowDriver {

    var paymentFlowResult: BTPaymentFlowResult?
    var paymentFlowError: Error?
    
    override func startPaymentFlow(_ request: BTPaymentFlowRequest & BTPaymentFlowRequestDelegate, completion completionBlock: @escaping (BTPaymentFlowResult?, Error?) -> Void) {
        completionBlock(paymentFlowResult, paymentFlowError)
    }
}
