import BraintreePayPalValidator
import InAppSettingsKit

class DemoViewController: UIViewController, BTViewControllerPresentingDelegate {

    // MARK: - Properties

    @IBOutlet weak var cardNumberTextField: UITextField!
    @IBOutlet weak var expirationDateTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var cvvTextField: UITextField!
    @IBOutlet weak var payeeEmailTextField: UITextField!
    @IBOutlet weak var orderResultLabel: UILabel!
    @IBOutlet weak var processOrderButton: UIButton!
    @IBOutlet weak var checkoutResultLabel: UILabel!
    @IBOutlet weak var uatLabel: UILabel!

    private var orderId: String?
    private var payPalValidatorClient: BTPayPalValidatorClient?

    private var intent: String {
        return UserDefaults.standard.string(forKey: "intent") ?? "capture"
    }

    private var countryCode: String {
        return UserDefaults.standard.string(forKey: "countryCode") ?? "US"
    }

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
        generateUAT()
    }

    override func viewWillAppear(_ animated: Bool) {
        amountTextField.text = "10.00"

        if countryCode == "UK" {
            self.payeeEmailTextField.text = "native-sdk-gb-merchant-111@paypal.com"
        } else {
            self.payeeEmailTextField.text = "ahuang-us-bus-ppcp-approve-seller3@paypal.com"
        }

        processOrderButton.setTitle("\(intent.capitalized) Order", for: .normal)
        orderResultLabel.text = "Order ID: None"
        orderId = nil
    }

    // MARK: - IBActions

    @IBAction func cardCheckoutTapped(_ sender: UIButton) {
        guard let orderId = orderId, let card = createBTCard() else { return }

        updateCheckoutLabel(withText: "Validating card...")
        payPalValidatorClient?.checkoutWithCard(orderId, card: card, presentingDelegate: self, completion: { (validatorResult, error) in
            if ((error) != nil) {
                self.updateCheckoutLabel(withText: "\(error?.localizedDescription ?? "Tokenization Error")")
                return
            }

            guard let orderID = validatorResult?.orderID else { return }
            self.updateCheckoutLabel(withText: "Validate card success: \(orderID)")
            self.processOrderButton.isEnabled = true
        })
    }

    @IBAction func payPalCheckoutTapped(_ sender: BTUIPayPalButton) {
        guard let orderId = orderId else { return }

        updateCheckoutLabel(withText: "Checking out with PayPal...")
        payPalValidatorClient?.checkoutWithPayPal(orderId, presentingDelegate: self, completion: { (validatorResult, error) in
            guard let orderID = validatorResult?.orderID else { return }
            self.updateCheckoutLabel(withText: "PayPal checkout complete: \(orderID)")
            self.processOrderButton.isEnabled = true
        })
    }

    @IBAction func applePayCheckoutTapped(_ sender: Any) {
        guard let orderId = orderId else { return }

        let paymentRequest = PKPaymentRequest()

        // Set other PKPaymentRequest properties here
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Sock", amount: NSDecimalNumber(string: "10")),
            PKPaymentSummaryItem(label: "Demo", amount: NSDecimalNumber(string: "10")),
        ]

        self.updateCheckoutLabel(withText: "Presenting ApplePay Sheet ...")
        payPalValidatorClient?.checkoutWithApplePay(orderId, paymentRequest: paymentRequest, presentingDelegate: self, completion: { (validatorResult, error, applePayResultHandler) in
            guard let validatorResult = validatorResult else {
                self.updateCheckoutLabel(withText: "ApplePay Error: \(error?.localizedDescription ?? "error")")
                applePayResultHandler(false)
                return
            }

            self.updateCheckoutLabel(withText: "ApplePay successful: \(validatorResult.orderID)")
            self.processOrderButton.isEnabled = true

            applePayResultHandler(true)
        })
    }

    @IBAction func processOrderTapped(_ sender: Any) {
        guard let orderId = orderId else { return }

        updateCheckoutLabel(withText: "Processing order...")

        let params = ProcessOrderParams(orderId: orderId, intent: intent, countryCode: countryCode)

        DemoMerchantAPI.sharedService.processOrder(processOrderParams: params) { (transactionResult, error) in
            guard let transactionResult = transactionResult else {
                self.updateCheckoutLabel(withText: "Transaction failed: \(error?.localizedDescription ?? "error")")
                return
            }

            self.updateCheckoutLabel(withText: "\(self.intent.capitalized) Status: \(transactionResult.status)")
        }
    }

    @IBAction func generateOrderTapped(_ sender: Any) {
        updateOrderLabel(withText: "Creating order...")
        updateCheckoutLabel(withText: "")
        self.processOrderButton.isEnabled = false

        let amount = amountTextField.text!
        let payeeEmail = payeeEmailTextField.text!
        let currencyCode = countryCode == "US" ? "USD" : "EUR"

        let orderRequestParams = CreateOrderParams(intent: intent.uppercased(),
                                                   purchaseUnits: [PurchaseUnit(amount: Amount(currencyCode: currencyCode, value: amount))],
                                                   payee: Payee(emailAddress: payeeEmail))

        DemoMerchantAPI.sharedService.createOrder(orderParams: orderRequestParams) { (orderResult, error) in
            guard let order = orderResult, error == nil else {
                self.updateOrderLabel(withText: "Error: \(error!.localizedDescription)")
                return
            }

            self.orderId = order.id
            self.updateOrderLabel(withText: "Order ID: \(order.id)")
        }
    }

    @IBAction func settingsTapped(_ sender: Any) {
        let settingsViewController = IASKAppSettingsViewController()
        settingsViewController.delegate = self
        
        let navigationController = UINavigationController(rootViewController: settingsViewController)
        present(navigationController, animated: true, completion: nil)
    }
    
    @IBAction func refreshTapped(_ sender: Any) {
        generateUAT()
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

    func generateUAT() {
        DemoMerchantAPI.sharedService.generateUAT(countryCode: countryCode) { (uat, error) in
            guard let uat = uat, error == nil else {
                self.updateUATLabel(withText: "Failed to fetch UAT: \(error!.localizedDescription). Tap refresh to try again.")
                return
            }

            self.updateUATLabel(withText: "UAT: \(uat)")
            self.payPalValidatorClient = BTPayPalValidatorClient(accessToken: uat)
        }
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

    private func updateUATLabel(withText text: String) {
        DispatchQueue.main.async {
            self.uatLabel.text = text
        }
    }

    // MARK: - BTViewControllerPresentingDelegate

    func paymentDriver(_ driver: Any, requestsPresentationOf viewController: UIViewController) {
        self.present(viewController, animated: true)
    }

    func paymentDriver(_ driver: Any, requestsDismissalOf viewController: UIViewController) {
        self.dismiss(animated: true)
    }
}

// MARK: - IASKSettingsDelegate
extension DemoViewController: IASKSettingsDelegate {
    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController!) {
        sender.dismiss(animated: true)
        // TODO - reload
    }
}
