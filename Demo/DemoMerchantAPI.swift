import Foundation

struct OrderValidationInfo: Codable {
    let orderId: String
    let universalAccessToken: String
}

struct OrderTransactionInfo: Codable {
    let orderId: String
    let status: String
}

struct OrderParams: Codable {
    let amount: String
    let payeeEmail: String
    let intent: String
    let partnerCountry: String
}

class DemoMerchantAPI {

    static let sharedService = DemoMerchantAPI()

    //    private let urlString = "https://braintree-p4p-sample-merchant.herokuapp.com/order-validation-info"
    private let fetchUrlString = "http://localhost:5000/order-validation-info"
    private let transactionUrlString = "http://localhost:5000/process-order"

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
            queryString += (queryString.contains("?") ? "&intent=" : "?intent=") + orderParams.intent.uppercased()
        }

        if (orderParams.partnerCountry != "") {
            queryString += (queryString.contains("?") ? "&partnerCountry=" : "?partnerCountry=") + orderParams.partnerCountry
        }
        
        return queryString
    }

    func processOrder(orderId: String, intent: String, partnerCountry: String, completion: @escaping ((OrderTransactionInfo?, Error?) -> Void)) {
        let url = URL(string: transactionUrlString + "/" + orderId + "?intent=" + intent + "&partnerCountry=" + partnerCountry)!

//        let request = URLRequest.init(url: url)
        //request.httpMethod = "PUT"
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(nil, error!)
                return
            }

            do {
                let orderTransactionInfo = try JSONDecoder().decode(OrderTransactionInfo.self, from: data)
                completion(orderTransactionInfo, nil)
            } catch (let parseError) {
                completion(nil, parseError)
            }
        }.resume()
    }
}
