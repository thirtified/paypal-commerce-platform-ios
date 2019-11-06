import Foundation
import BraintreePayPalValidator

struct Order: Codable {
    let id: String
    let status: String
}

struct CreateOrderParams: Codable {
    let intent: String
    let purchaseUnits: [PurchaseUnit]
    let payee: Payee

    struct PurchaseUnit: Codable {
        let amount: Amount

        struct Amount: Codable {
            let currencyCode: String
            let value: String
        }
    }

    struct Payee: Codable {
        let emailAddress: String
    }
}

typealias PurchaseUnit = CreateOrderParams.PurchaseUnit
typealias Amount = CreateOrderParams.PurchaseUnit.Amount
typealias Payee = CreateOrderParams.Payee

struct UAT: Codable {
    let universalAccessToken: String
}

struct ProcessOrderParams: Codable {
    let orderId: String
    let intent: String
    let countryCode: String
}

class DemoMerchantAPI {

    static let sharedService = DemoMerchantAPI()

    // private let urlString = "https://braintree-p4p-sample-merchant.herokuapp.com/order-validation-info"
    private let urlString = "http://localhost:5000"

    private init() {}

    func createOrder(countryCode: String, orderParams: CreateOrderParams, completion: @escaping ((Order?, Error?) -> Void)) {
        var components = URLComponents(string: urlString)!
        components.path = "/order"
        components.queryItems = [URLQueryItem(name: "countryCode", value: countryCode)]

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "POST"
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        urlRequest.httpBody = try! encoder.encode(orderParams)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(nil, error!)
                return
            }

            do {
                let order = try JSONDecoder().decode(Order.self, from: data)
                completion(order, nil)
            } catch (let parseError) {
                completion(nil, parseError)
            }
        }.resume()
    }

    func generateUAT(countryCode: String, completion: @escaping ((String?, Error?) -> Void)) {
        var components = URLComponents(string: urlString)!
        components.path = "/uat"
        components.queryItems = [URLQueryItem(name: "countryCode", value: countryCode)]

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "POST"

        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(nil, error!)
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let uat = try decoder.decode(UAT.self, from: data)
                completion(uat.universalAccessToken, nil)
            } catch (let parseError) {
                completion(nil, parseError)
            }
        }.resume()
    }

    func processOrder(processOrderParams: ProcessOrderParams, completion: @escaping ((Order?, Error?) -> Void)) {
        var urlRequest = URLRequest(url: URL(string: urlString + "/" + processOrderParams.intent.lowercased() + "-order")!)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue(PPDataCollector.clientMetadataID(nil), forHTTPHeaderField: "PayPal-Client-Metadata-Id")
        urlRequest.httpBody = try! JSONEncoder().encode(processOrderParams)

        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(nil, error!)
                return
            }

            do {
                let order = try JSONDecoder().decode(Order.self, from: data)
                completion(order, nil)
            } catch (let parseError) {
                completion(nil, parseError)
            }
        }.resume()
    }
}
