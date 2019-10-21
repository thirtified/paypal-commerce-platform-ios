import Foundation

class MockViewControllerPresentingDelegate: NSObject, BTViewControllerPresentingDelegate {
    
    var requestsPresentationHandler: ((Any, UIViewController) -> Void)?
    var requestsDismissalHandler: ((Any, UIViewController) -> Void)?
    
    func paymentDriver(_ driver: Any, requestsPresentationOf viewController: UIViewController) {
        requestsPresentationHandler?(driver, viewController)
    }
    
    func paymentDriver(_ driver: Any, requestsDismissalOf viewController: UIViewController) {
        requestsDismissalHandler?(driver, viewController)
    }
}
