import Foundation

struct OrderValidationInfo: Codable {
    let orderId: String
    let universalAccessToken: String
}

struct OrderCaptureInfo: Codable {
    let orderId: String
    let status: String
}

struct OrderParams: Codable {
    let amount: String
    let payeeEmail: String
    let intent: String
}

class DemoMerchantAPI {

    static let sharedService = DemoMerchantAPI()

    //    private let urlString = "https://braintree-p4p-sample-merchant.herokuapp.com/order-validation-info"
    private let fetchUrlString = "http://localhost:5000/order-validation-info"
    private let captureUrlString = "http://localhost:5000/capture-order"

    private init() {}

    func fetchOrderValidationInfo(orderParams: OrderParams, completion: @escaping ((OrderValidationInfo?, Error?) -> Void)) {
        let url = URL(string: fetchUrlString + constructParamsQueryString(orderParams: orderParams))!

        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(nil, error!)
                return
            }

            do {
                let orderValidationInfo = try JSONDecoder().decode(OrderValidationInfo.self, from: data)
                completion(orderValidationInfo, nil)
            } catch (let parseError) {
                completion(nil, parseError)
            }
            }.resume()
    }

    func constructParamsQueryString(orderParams: OrderParams) -> String {
        var queryString = ""

        if (orderParams.payeeEmail != "") {
            queryString += "?payeeEmail=" + orderParams.payeeEmail
        }

        if (orderParams.amount != "") {
            queryString += (queryString.contains("?") ? "&amount=" : "?amount=") + orderParams.amount
        }

        if (orderParams.intent != "") {
            queryString += (queryString.contains("?") ? "&intent=" : "?intent=") + orderParams.intent
        }

        return queryString
    }

    func captureOrder(orderId: String, completion: @escaping ((OrderCaptureInfo?, Error?) -> Void)) {
        let url = URL(string: captureUrlString + "/" + orderId)!

//        let request = URLRequest.init(url: url)
        //request.httpMethod = "PUT"
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(nil, error!)
                return
            }

            do {
                let orderCaptureInfo = try JSONDecoder().decode(OrderCaptureInfo.self, from: data)
                completion(orderCaptureInfo, nil)
            } catch (let parseError) {
                completion(nil, parseError)
            }
        }.resume()
    }
}
