import BraintreePayPalValidator
//import BraintreeCard
//import BraintreePaymentFlow

class ViewController: UIViewController, BTViewControllerPresentingDelegate {
    @IBOutlet weak var cardNumberTextField: UITextField!
    @IBOutlet weak var expirationDateTextField: UITextField!
    @IBOutlet weak var cvvTextField: UITextField!
    @IBOutlet weak var resultsLabel: UILabel!
    @IBOutlet weak var finalizeButton: UIButton!

    private var orderValidationInfo: OrderValidationInfo?
    private var payPalValidatorClient: BTPayPalValidatorClient?

    override func viewDidLoad() {
        super.viewDidLoad()

        updateLabel(withText: "Fetching Token and Order ID...")
        fetchOrderValidationInfo()
    }

    @IBAction func cardCheckoutTapped(_ sender: UIButton) {
        guard let card = createBTCard() else { return }

        updateLabel(withText: "Validating card...")
        payPalValidatorClient?.checkoutWithCard(card, presentingDelegate: self, completion: { (tokenizedCard, error) in
            if ((error) != nil) {
                self.updateLabel(withText: "\(error?.localizedDescription ?? "Tokenization Error")")
                return
            }

            guard let cardNonce = tokenizedCard?.nonce else { return }
            self.updateLabel(withText: "Validate card success: \(cardNonce)")
            self.finalizeButton.isEnabled = true
        })
    }

    @IBAction func payPalCheckoutTapped(_ sender: UIButton) {

        updateLabel(withText: "Checking out with PayPal...")
        payPalValidatorClient?.checkoutWithPayPal(presentingDelegate: self, completion: { (error) in
            self.updateLabel(withText: "PayPal checkout complete")
        })
    }

    @IBAction func applePayCheckoutTapped(_ sender: Any) {
        let paymentRequest = PKPaymentRequest.init()

        // Set other PKPaymentRequest properties here
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.paymentSummaryItems =
            [
                PKPaymentSummaryItem(label: "Sock", amount: NSDecimalNumber(string: "10")),
                PKPaymentSummaryItem(label: "P4PDemo", amount: NSDecimalNumber(string: "10")),
        ]

        self.updateLabel(withText: "Presenting ApplePay Sheet ...")
        payPalValidatorClient?.checkoutWithApplePay(paymentRequest, presentingDelegate: self, completion: { (applePayCardNonce, error, applePayResultHandler) in
            guard let applePayCardNonce = applePayCardNonce else {
                self.updateLabel(withText: "ApplePay Error: \(error?.localizedDescription ?? "error")")

                applePayResultHandler(false)
                return
            }

            self.updateLabel(withText: "ApplePay Nonce: \(applePayCardNonce.nonce)")
            print("ApplePay nonce = \(applePayCardNonce.nonce)")
            self.finalizeButton.isEnabled = true

            applePayResultHandler(true)
        })
    }

    @IBAction func finalizeOrderTapped(_ sender: Any) {
        updateLabel(withText: "Finalizing/Capturing order...")

        DemoMerchantAPI.sharedService.captureOrder(orderId: self.orderValidationInfo!.orderId) { (captureResult, error) in
            guard let captureResult = captureResult else {
                self.updateLabel(withText: "Order Capture Failed: \(error?.localizedDescription ?? "error")")
                return
            }

            self.updateLabel(withText: "Order Capture Status: \(captureResult.status)")
        }
    }

    @IBAction func refreshTapped(_ sender: Any) {
        updateLabel(withText: "Fetching new Token and Order ID...")
        fetchOrderValidationInfo()
    }

    func createBTCard() -> BTCard? {
        let card = BTCard()

        guard let cardNumber = self.cardNumberTextField.text else {
            return nil
        }

        guard let expiry = self.expirationDateTextField.text else {
            return nil
        }

        guard let cvv = self.cvvTextField.text else {
            return nil
        }

        // TODO: Apply proper regulations on card info UITextFields.
        // Will not work properly if expiration not in "01/22" format.
        if (cardNumber == "" || expiry == "" || cvv == "" || expiry.count < 5) {
            showIncompleteFieldsAlert()
            return nil
        }

        card.number = cardNumber
        card.cvv = cvv
        card.expirationMonth = String(expiry.prefix(2))
        card.expirationYear = "20" + String(expiry.suffix(2))
        return card
    }

    func showIncompleteFieldsAlert() {
        let alert = UIAlertController(title: "Incomplete Fields", message: "Card entry form incomplete.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        self.present(alert, animated: true)
    }

    private func updateLabel(withText text: String) {
        DispatchQueue.main.async {
            self.resultsLabel.text = text
        }
    }

    func fetchOrderValidationInfo() {
        DemoMerchantAPI.sharedService.fetchOrderValidationInfo { (orderValidationInfo, error) in
            guard let info = orderValidationInfo, error == nil else {
                self.updateLabel(withText: "Error: \(error!.localizedDescription)")
                return
            }

            self.orderValidationInfo = info
            self.payPalValidatorClient = BTPayPalValidatorClient(accessToken: info.universalAccessToken, orderId: info.orderId)
            self.updateLabel(withText: "Order ID: \(info.orderId)\nToken: \(info.universalAccessToken)")
        }
    }

    // MARK: - BTViewControllerPresentingDelegate
    func paymentDriver(_ driver: Any, requestsPresentationOf viewController: UIViewController) {
        self.present(viewController, animated: true) { }
    }

    func paymentDriver(_ driver: Any, requestsDismissalOf viewController: UIViewController) {
        self.dismiss(animated: true) { }
    }
}
