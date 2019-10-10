import BraintreePayPalValidator

class ViewController: UIViewController, BTViewControllerPresentingDelegate {
    @IBOutlet weak var cardNumberTextField: UITextField!
    @IBOutlet weak var expirationDateTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var cvvTextField: UITextField!
    @IBOutlet weak var payeeEmailTextField: UITextField!
    @IBOutlet weak var orderResultLabel: UILabel!
    @IBOutlet weak var processOrderButton: UIButton!
    @IBOutlet weak var orderIntentSegmentedControl: UISegmentedControl!
    @IBOutlet weak var checkoutResultLabel: UILabel!
    
    private var orderValidationInfo: OrderValidationInfo?
    private var orderRequestParams: OrderParams?
    private var payPalValidatorClient: BTPayPalValidatorClient?

    override func viewDidLoad() {
        super.viewDidLoad()

        updateOrderLabel(withText: "Generate an order id.")
    }

    // MARK: - IBActions

    @IBAction func cardCheckoutTapped(_ sender: UIButton) {
        guard let card = createBTCard() else { return }

        updateCheckoutLabel(withText: "Validating card...")
        payPalValidatorClient?.checkoutWithCard(card, presentingDelegate: self, completion: { (tokenizedCard, error) in
            if ((error) != nil) {
                self.updateCheckoutLabel(withText: "\(error?.localizedDescription ?? "Tokenization Error")")
                return
            }

            guard let cardNonce = tokenizedCard?.nonce else { return }
            self.updateCheckoutLabel(withText: "Validate card success: \(cardNonce)")
            self.processOrderButton.isEnabled = true
        })
    }

    @IBAction func payPalCheckoutTapped(_ sender: UIButton) {

        updateCheckoutLabel(withText: "Checking out with PayPal...")
        payPalValidatorClient?.checkoutWithPayPal(presentingDelegate: self, completion: { (error) in
            self.updateCheckoutLabel(withText: "PayPal checkout complete")
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

        self.updateCheckoutLabel(withText: "Presenting ApplePay Sheet ...")
        payPalValidatorClient?.checkoutWithApplePay(paymentRequest, presentingDelegate: self, completion: { (applePayCardNonce, error, applePayResultHandler) in
            guard let applePayCardNonce = applePayCardNonce else {
                self.updateCheckoutLabel(withText: "ApplePay Error: \(error?.localizedDescription ?? "error")")

                applePayResultHandler(false)
                return
            }

            self.updateCheckoutLabel(withText: "ApplePay Nonce: \(applePayCardNonce.nonce)")
            print("ApplePay nonce = \(applePayCardNonce.nonce)")
            self.processOrderButton.isEnabled = true

            applePayResultHandler(true)
        })
    }

    @IBAction func processOrderTapped(_ sender: Any) {
        updateCheckoutLabel(withText: "Processing order...")

        DemoMerchantAPI.sharedService.processOrder(orderId: self.orderValidationInfo!.orderId, intent: self.orderRequestParams!.intent) { (transactionResult, error) in
            guard let transactionResult = transactionResult else {
                self.updateCheckoutLabel(withText: "Transaction failed: \(error?.localizedDescription ?? "error")")
                return
            }

            if let orderIntentType = self.orderRequestParams?.intent {
                self.updateCheckoutLabel(withText: "\(orderIntentType) Order status: \(transactionResult.status)")
            }
        }
    }

    @IBAction func generateOrderTapped(_ sender: Any) {
        updateOrderLabel(withText: "Fetching new Token and Order ID...")
        updateCheckoutLabel(withText: "Checkout results")
        self.processOrderButton.isEnabled = false

        fetchOrderValidationInfo()
    }

    // MARK: - Construct order/request helpers

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
            showAlert(message: "Card entry form incomplete.")
            return nil
        }

        card.number = cardNumber
        card.cvv = cvv
        card.expirationMonth = String(expiry.prefix(2))
        card.expirationYear = "20" + String(expiry.suffix(2))
        return card
    }

    func fetchOrderValidationInfo() {
        setOrderQueryParams()

        DemoMerchantAPI.sharedService.fetchOrderValidationInfo(orderParams: self.orderRequestParams!) { (orderValidationInfo, error) in
            guard let info = orderValidationInfo, error == nil else {
                self.updateOrderLabel(withText: "Error: \(error!.localizedDescription)")
                return
            }

            self.orderValidationInfo = info
            self.payPalValidatorClient = BTPayPalValidatorClient(accessToken: info.universalAccessToken, orderId: info.orderId)
            self.updateOrderLabel(withText: "Order ID: \(info.orderId)\nToken: \(info.universalAccessToken)")
        }
    }

    func setOrderQueryParams() {
        var amount = "", payeeEmail = ""

        if let amountField = self.amountTextField.text {
            amount = amountField
        }

        if let payeeEmailField = self.payeeEmailTextField.text {
            payeeEmail = payeeEmailField
            if (payeeEmail == "") {
                // TODO: currently we default to this email if none is entered.
                // We need this email for testing. Do we want to leave this default here
                // or move it to server?
                payeeEmail = "rtimoschuk-us-bus-onb-ppcp-approve-seller15@paypal.com"
            }
        }

        let orderIntent = orderIntentSegmentedControl.titleForSegment(at: orderIntentSegmentedControl.selectedSegmentIndex)

        self.orderRequestParams = OrderParams.init(amount: amount, payeeEmail: payeeEmail, intent: orderIntent!)
    }

    // MARK: - UI Helpers

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Incomplete Fields", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        self.present(alert, animated: true)
    }

    private func updateOrderLabel(withText text: String) {
        DispatchQueue.main.async {
            self.orderResultLabel.text = text
        }
    }

    private func updateCheckoutLabel(withText text: String) {
        DispatchQueue.main.async {
            self.checkoutResultLabel.text = text
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
