import Foundation

class MockURLSession: URLSession {

    var dataTaskHandler: ((URLRequest) -> Void)?

    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        dataTaskHandler?(request)
    }
}
