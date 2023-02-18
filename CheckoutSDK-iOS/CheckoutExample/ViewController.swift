//
//  ViewController.swift
//  CheckoutExample
//
//  Created by Osama Rabie on 7/31/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import UIKit
import CheckoutSDK_iOS
import CommonDataModelsKit_iOS
import TapUIKit_iOS
import LocalisationManagerKit_iOS
import PassKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tapPayButton: TapActionButton!
    let tapPayButtonViewModel:TapPayButtonViewModel = .init()
    var tapSettings:TapSettings = TapSettings(localisation: false, theme: "Default", currency: .USD, swipeToDismissFeature: true, paymentTypes: [.All],closeButtonTitleFeature: true, customer: try! .init(identifier: "cus_TS075220212320q2RD0707283"),transactionMode: .purchase,addShippingFeature: false)
    
    var localeID:String = "en" {
        didSet{
            TapLocalisationManager.shared.localisationLocale = localeID
            adjustTapButton()
        }
    }
    var localisationFileName:String? = "CustomLocalisation"
    var customTheme:TapCheckOutTheme? = nil
    @IBOutlet weak var amountTextField: UITextField!
    
    var amount:Double {
        if(getPaymentItems().count == 0) {
            return Double(amountTextField.text ?? "") ?? 1000
        }else{
            return getPaymentItems().reduce(0.0) {$0 + $1.itemFinalPrice()}
        }
    }
    var swipeToDismiss:Bool = true
    
    var items:[ItemModel] = []
    
    var showDragHandler:Bool {
        return !TapFormSettingsViewController.showCloseButtonTitle()
    }
   
    @IBOutlet weak var paymentItemsTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        TapFormSettingsViewController.funcPreFillData()
        
        TapLocalisationManager.shared.localisationLocale = TapFormSettingsViewController.selectedLocale()
        // Do any additional setup after loading the view.
        amountTextField.delegate = self
        tapSettings.load()
        //TapLocalisationManager.shared.localisationLocale = "en"
        //TapThemeManager.setDefaultTapTheme()
        adjustTapButton()
        paymentItemsTableView.estimatedRowHeight = 100
        paymentItemsTableView.rowHeight = UITableView.automaticDimension
        paymentItemsTableView.register(UINib(nibName: "ItemTableViewCell", bundle: nil), forCellReuseIdentifier: "ItemTableViewCell")
        paymentItemsTableView.delegate = self
        paymentItemsTableView.dataSource = self
        paymentItemsTableView.allowsMultipleSelection = true
        
        loadItems()
    }
    
    
    func getPaymentItems() -> [ItemModel] {
        
        if let selectedItems = paymentItemsTableView.indexPathsForSelectedRows,
           selectedItems.count > 0 {
            return selectedItems.map{ items[$0.row] }
        }
        
        return []
    }
    
    func loadItems() {
        items = []
        
        if let data = UserDefaults.standard.value(forKey:TapSettings.itemsSaveKey) as? Data {
            do {
                items = try PropertyListDecoder().decode([ItemModel].self, from: data)
            } catch {
                print("error paymentTypes: \(error.localizedDescription)")
            }
        }
        self.paymentItemsTableView.reloadData()
    }
    
    func adjustTapButton() {
        tapPayButton.setup(with: tapPayButtonViewModel)
        tapPayButtonViewModel.buttonStatus = .ValidPayment
        tapPayButtonViewModel.buttonActionBlock = { [weak self] in self?.startSDKClicked() }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        localeID = TapFormSettingsViewController.selectedLocale()
    }
    
    func startSDKClicked() {
        tapSettings.load()
        
        tapPayButtonViewModel.startLoading()
        // Tell the chekout to configure its resources
        let checkout:TapCheckout = .init()
        TapCheckout.flippingStatus = .FlipOnLoadWithFlippingBack
        // Checkout's localization. Currently supporting en and ar
        TapCheckout.localeIdentifier = localeID
        // Checkout's sample keys. Make sure
        // you use yours before going live
        //TapCheckout.bundleID = "company.tap.goSellSDKExamplee"
        TapCheckout.secretKey = .init(sandbox: TapFormSettingsViewController.merchantSettings().0,
                                      production: TapFormSettingsViewController.merchantSettings().1)
        
        //TapCheckout.secretKey = .init(sandbox: "sk_test_cvSHaplrPNkJO7dhoUxDYjqA",
          //                            production:"sk_live_V4UDhitI0r7sFwHCfNB6xMKp")
  
        //customTheme = .init(with: "https://menoalmotasel.online/RedLightTheme.json", and: "https://menoalmotasel.online/RedDarkTheme.json", from: .RemoteJsonFile)
        
    
        TapSettings.logs = []
        
        checkout.build(
            localiseFile: nil,//TapCheckoutLocalisation(with: URL(string: "https://menoalmotasel.online/CustomLocalisation.json")!, from:.RemoteJsonFile),
            customTheme: customTheme,
            delegate: self,
            currency: TapFormSettingsViewController.transactionSettings().1,
            amount: amount,
            items: getPaymentItems(),
            applePayMerchantID: TapFormSettingsViewController.merchantSettings().4,
            swipeDownToDismiss: swipeToDismiss,
            paymentType: TapFormSettingsViewController.transactionSettings().2,
            closeButtonStyle: TapFormSettingsViewController.showCloseButtonTitle() ? .title : .icon,
            showDragHandler:showDragHandler,
            transactionMode: TapFormSettingsViewController.transactionSettings().0,
            customer: TapFormSettingsViewController.customerSettings().7,
            tapMerchantID: TapFormSettingsViewController.merchantSettings().3,
            taxes: TapFormSettingsViewController.extraFees().3,
            shipping: TapFormSettingsViewController.extraFees().2,
            require3DSecure: TapFormSettingsViewController.cardSettings().5,
            sdkMode: TapFormSettingsViewController.sdkMode(),
            enableApiLogging: TapFormSettingsViewController.loggingCapabilities().4.map{ $0.rawValue },
            collectCreditCardName: TapFormSettingsViewController.cardSettings().0,
            creditCardNameEditable: TapFormSettingsViewController.cardSettings().3,
            creditCardNamePreload: TapFormSettingsViewController.cardSettings().4,
            showSaveCreditCard: TapFormSettingsViewController.cardSettings().2,
            isSubscription: TapSettings.isSubsciption,
            recurringPaymentRequest: generateRecurring(),
            applePayButtonType: TapFormSettingsViewController.applePaySettings().0,
            applePayButtonStyle: TapFormSettingsViewController.applePaySettings().1,
            onCheckOutReady: {[weak self] tapCheckOut in
                DispatchQueue.main.async() {
                    tapCheckOut.start(presentIn: self)
                }
            })
    }
    
    
    func generateRecurring() -> Any? {
        
        
        
        if #available(iOS 16.0, *),
           TapSettings.isSubsciption {
            let billing = PKRecurringPaymentSummaryItem(label: TapSettings.applePaySubscriptionName, amount: NSDecimalNumber(decimal: Decimal(amount)))
            billing.startDate = Date(timeIntervalSince1970: TapSettings.applePayBillingStartDate)
            billing.endDate = Date(timeIntervalSince1970: TapSettings.applePayBillingEndDate)
            billing.intervalUnit = TapSettings.applePayBillingCycle
            let recurringRequest:PKRecurringPaymentRequest = PKRecurringPaymentRequest(paymentDescription: TapSettings.applePaySubscriptionDesc,
                                                                                       regularBilling: billing,
                                                                                       managementURL: URL(string: "https://my-backend.example.com/customer-portal")!)
            recurringRequest.billingAgreement = TapSettings.applePaySubscriptionBillingAgree
            return recurringRequest
        } else {
            return nil
        }
    }
    
    @IBAction func showSettings(_ sender: UIButton) {
        let settingsVC = self.storyboard?.instantiateViewController(withIdentifier: "TapFormSettingsViewController") as! TapFormSettingsViewController
        
        let navigationController: UINavigationController = UINavigationController(rootViewController: settingsVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true, completion: nil)
    }
    @IBAction func addItemsClicked(_ sender: Any) {
        let alertController:UIAlertController = .init(title: "Options", message: "What do you want to do?", preferredStyle: .actionSheet)
        alertController.addAction(.init(title: "Add item", style: .default, handler: { _ in
            let viewController:CreateItemViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CreateItemViewController") as! CreateItemViewController
            viewController.delegate = self
            self.present(viewController, animated: true)
        }))
        
        alertController.addAction(.init(title: "Modify Taxes", style: .default, handler: { _ in
            let viewController:TaxTableViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "TaxTableViewController") as! TaxTableViewController
            self.present(viewController, animated: true)
        }))
        
        alertController.addAction(.init(title: "Show Logs", style: .default, handler: { _ in
            let viewController:LogsViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "LogsViewController") as! LogsViewController
            self.present(viewController, animated: true)
        }))
        
        alertController.addAction(.init(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
}
/*
extension ViewController: SettingsDelegate {
    func didUpdateCredCardSave(to type: TapUIKit_iOS.SaveCardType) {
        
    }
    
    func didUpdateCredCardName(to enabled: Bool) {
        creditNameFeature = enabled
    }
    
    
    func didUpdateTransactionMode(to mode: TransactionMode) {
        tapSettings.load()
    }
    
    func didChangeCustomer(with customer: TapCustomer) {
        self.customer = customer
        tapSettings.load()
    }
    
    func didUpdatePaymentTypes(to types: [TapPaymentType]) {
        paymentTypes = types
        tapSettings.load()
    }
    
    func didUpdateCloseButtonTitle(to enabled: Bool) {
        closeButtonTitleStyle = enabled ? .title : .icon
        tapSettings.load()
    }
    
    func didUpdateLanguage(with locale: String) {
        localeID = locale
        tapSettings.load()
        adjustTapButton()
    }
    
    func didUpdateLocalisation(to enabled: Bool) {
        localisationFileName = (enabled) ? "CustomLocalisation" : nil
        adjustTapButton()
    }
    
    func didChangeTheme(with themeName: String?) {
        print("selected theme: \(String(describing: themeName))")
        guard let nonNullThemeName = themeName else {
            customTheme = nil
            return
        }
        
        customTheme = .init(with: "\(nonNullThemeName)LightTheme", and: "\(nonNullThemeName)DarkTheme")
    }
    
    func didChangeCurrency(with currency: TapCurrencyCode) {
        selectedCurrency = currency
    }
    
    func didUpdateSwipeToDismiss(to enabled: Bool) {
        swipeToDismiss = enabled
    }
    
    func didUpdateAddShipping(to enabled: Bool) {
        addShipping = enabled
    }
}
*/


extension ViewController:CheckoutScreenDelegate {
    func tapBottomSheetWillDismiss() {
        tapPayButtonViewModel.expandButton()
        adjustTapButton()
    }
    
    func applePayTokenizationFailed(in session:URLSessionDataTask?, for result:[String:String]?, with error:Error?) {
        var message = "No error message"
        if let result = result {
            message = ""
            result.tap_allKeys.forEach{ message = "\(message)\n\($0) : \(result[$0] ?? "")" }
        }
        
        if let error = error {
            message = "\(message)\n\(error.localizedDescription)"
        }
        
        showAlert(title: "Apple pay token failed", message: message)
    }
    
    
    func cardTokenizationFailed(in session:URLSessionDataTask?, for result:[String:String]?, with error:Error?) {
        var message = "No error message"
        if let result = result {
            message = ""
            result.tap_allKeys.forEach{ message = "\(message)\n\($0) : \(result[$0] ?? "")" }
        }
        
        if let error = error {
            message = "\(message)\n\(error.localizedDescription)"
        }
        showAlert(title: "Card token failed", message: "Message: \(message)")
    }
    
    
    func saveCardTokenizationFailed(in session:URLSessionDataTask?, for result:[String:String]?, with error:Error?) {
        var message = "No error message"
        if let result = result {
            message = ""
            result.tap_allKeys.forEach{ message = "\(message)\n\($0) : \(result[$0] ?? "")" }
        }
        
        if let error = error {
            message = "\(message)\n\(error.localizedDescription)"
        }
        showAlert(title: "Saved card token failed", message: "Message: \(message)")
    }
    
    func saveCardFailed(with savedCard: TapCreateCardVerificationResponseModel) {
        showAlert(title: savedCard.response?.code ?? "Save failed", message: "Message: \(savedCard.response?.message ?? "NO MESSAGE")")
    }
    
    func log(string: String) {
        TapSettings.logs.append(string)
    }
    
    func saveCardSuccessfull(with savedCard: TapCreateCardVerificationResponseModel) {
        showAlert(title: "Success", message: "Card ID: \(savedCard.identifier),\nCard: **** \(savedCard.card.lastFourDigits)")
    }
    
    func cardTokenized(with token: Token) {
        showAlert(title: "Success", message: "Token ID: \(token.identifier),\nCard: **** \(token.card.lastFourDigits)")
    }
    
    func checkoutCaptured(with authorize: Authorize) {
        showAlert(title: "Success", message: "Authorize ID: \(authorize.identifier),\nAmount: \(authorize.amount)")
    }
    
    func checkoutCaptured(with charge: Charge) {
        showAlert(title: "Success", message: "Charge ID: \(charge.identifier),\nAmount: \(charge.amount)")
    }
    
    func checkoutFailed(in session: URLSessionDataTask?, for result: [String : String]?, with error: Error?) {
        tapPayButtonViewModel.endLoading(with: false) {
            self.tapBottomSheetWillDismiss()
            var message = "No error message"
            if let result = result {
                message = ""
                result.tap_allKeys.forEach{ message = "\(message)\n\($0) : \(result[$0] ?? "")" }
            }
            
            if let error = error {
                message = "\(message)\n\(error.localizedDescription)"
            }
            self.showAlert(title: "Error", message: message)
        }
    }
    
    func checkoutFailed(with charge: Charge) {
        showAlert(title: charge.response?.code ?? "Charge failed", message: "Charge ID: \(charge.identifier)\nError message:\(charge.response?.message ?? "NO MESSAGE")")
    }
    
    func checkoutFailed(with authorize: Authorize) {
        showAlert(title: authorize.response?.code ?? "Authorize failed", message: "Authorize ID: \(authorize.identifier)\nError message:\(authorize.response?.message ?? "NO MESSAGE")")
    }
    
    func showAlert(title:String, message:String) {
        let uialert:UIAlertController = .init(title: title, message: message, preferredStyle: .alert)
        uialert.addAction(.init(title: "OK", style: .cancel))
        DispatchQueue.main.async { [weak self] in
            self?.present(uialert, animated: true)
        }
    }
}


extension ViewController:UITextFieldDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        // Fix the amount entered by the tester
        
        // Check he entered a valid numeric data
        guard let enteredAmount:Double = Double(textField.text ?? "0"),
              enteredAmount > 0,
              enteredAmount < 10000 else {
            amountTextField.text = ""
            self.showToast(message: "Amount only digits less than 10,000", font: .systemFont(ofSize: 15))
            return
        }
        
        // Always round to third decimal digits
        amountTextField.text = String(format: "%.3f", enteredAmount)
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell!.accessoryType = paymentItemsTableView.indexPathsForSelectedRows?.contains(indexPath) ?? false ? .checkmark : .none
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell!.accessoryType = .none
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell", for: indexPath) as! ItemTableViewCell
        cell.configure(with: items[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            items.remove(at: indexPath.row)
            UserDefaults.standard.set(try! PropertyListEncoder().encode(items), forKey: TapSettings.itemsSaveKey)
            UserDefaults.standard.synchronize()
            
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
    
}

extension ViewController: CreateItemViewControllerDelegate {
    func itemAdded(with item: ItemModel) {
        
        loadItems()
    }
    
    
}


extension UIViewController {
    
    @objc func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:    #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}



