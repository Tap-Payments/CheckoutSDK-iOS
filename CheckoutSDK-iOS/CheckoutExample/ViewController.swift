//
//  ViewController.swift
//  CheckoutExample
//
//  Created by Osama Rabie on 7/31/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import UIKit
import CheckoutSDK_iOS
import PassKit

class ViewController: UIViewController {
   
    @IBOutlet weak var tapPayButton: TapActionButton!
    let tapPayButtonViewModel:TapPayButtonViewModel = .init()
    var tapSettings:TapSettings = TapSettings(language: "English", localisation: false, theme: "Default", currency: .USD, swipeToDismissFeature: true, paymentTypes: [.All],closeButtonTitleFeature: true, customer: try! .init(identifier: "cus_TS075220212320q2RD0707283"),transactionMode: .purchase)
    
    var localeID:String = "en" {
        didSet{
            TapLocalisationManager.shared.localisationLocale = localeID
        }
    }
    var localisationFileName:String? = "CustomLocalisation"
    var customTheme:TapCheckOutTheme? = nil
    @IBOutlet weak var amountTextField: UITextField!
    var selectedCurrency:TapCurrencyCode = .USD
    var amount:Double {
        if(getPaymentItems().count == 0) {
            return Double(amountTextField.text ?? "") ?? 1000
        }else{
            return getPaymentItems().reduce(0.0) {$0 + $1.itemFinalPrice()}
        }
    }
    var swipeToDismiss:Bool = true
    var closeButtonTitleStyle:CheckoutCloseButtonEnum = .icon
    var items:[ItemModel] = []
    
    var paymentTypes:[TapPaymentType] = [.All]
    var showDragHandler:Bool {
        return closeButtonTitleStyle == .icon
    }
    var customer:TapCustomer = try! .init(identifier: "cus_TS075220212320q2RD0707283")
    
    @IBOutlet weak var paymentItemsTableView: UITableView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
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
        TapCheckout.bundleID = "company.tap.goSellSDKExamplee"
        TapCheckout.secretKey = .init(sandbox: "sk_test_cvSHaplrPNkJO7dhoUxDYjqA",
                                      production: "sk_live_QglH8V7Fw6NPAom4qRcynDK2")
        
        //customTheme = .init(with: "https://menoalmotasel.online/RedLightTheme.json", and: "https://menoalmotasel.online/RedDarkTheme.json", from: .RemoteJsonFile)
        let tempCountry:Country = try! .init(isoCode: "KW")
        let tempAdddress:Address = .init(type:.residential,
                                         country: tempCountry,
                                         line1: "asdasd",
                                         line2: "sadsadas",
                                         line3: "2312323",
                                         city: "Hawally",
                                         state: "Kuwait",
                                         zipCode: "30003"
        )
        
        checkout.build(
            localiseFile: nil,//TapCheckoutLocalisation(with: URL(string: "https://menoalmotasel.online/CustomLocalisation.json")!, from:.RemoteJsonFile),
            customTheme: customTheme,
            delegate: self,
            currency: tapSettings.currency,
            amount: amount,
            items: getPaymentItems(),
            swipeDownToDismiss: swipeToDismiss,
            paymentType: tapSettings.paymentTypes.first ?? .All,
            closeButtonStyle: closeButtonTitleStyle,
            showDragHandler:showDragHandler,
            transactionMode: tapSettings.transactionMode,
            customer: try! .init(emailAddress: .with("osamaguc@gmail.com"), phoneNumber: nil, name: "Osama Ahmed Helmy", address: nil),
            tapMerchantID: "599424",
            taxes: [],
            shipping: nil,//.init(name: "Shipping 1", descriptionText: "Descrtiption", amount: 10, currency: .KWD, recipientName: "OSAMA AHMED", address: tempAdddress, provider: .init(id:"",name:"aramex")),
            require3DSecure: true,
            sdkMode: .sandbox,
            showSaveCreditCard: .All,
            isSubscription: true,
            recurringPaymentRequest: generateRecurring(),
            onCheckOutReady: {[weak self] tapCheckOut in
                DispatchQueue.main.async() {
                    tapCheckOut.start(presentIn: self)
                }
            })
    }
    
    @IBAction func showSettings(_ sender: UIButton) {
        let settingsVC = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        settingsVC.delegate = self
        present(settingsVC, animated: true, completion: nil)
    }
    @IBAction func addItemsClicked(_ sender: Any) {
        let viewController:CreateItemViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CreateItemViewController") as! CreateItemViewController
        viewController.delegate = self
        present(viewController, animated: true)
    }
    
    
    func generateRecurring() -> Any? {
        
        if #available(iOS 16.0, *) {
            let billing = PKRecurringPaymentSummaryItem(label: "My Subscription", amount: NSDecimalNumber(string: "59.99"))
            billing.startDate = Date().addingTimeInterval(60 * 60 * 24 * 7)
            billing.endDate = Date().addingTimeInterval(60 * 60 * 24 * 365)
            billing.intervalUnit = .month
            let recurringRequest:PKRecurringPaymentRequest = PKRecurringPaymentRequest(paymentDescription: "Recurring",
                                                                             regularBilling: billing,
                                                                             managementURL: URL(string: "https://my-backend.example.com/customer-portal")!)
            recurringRequest.billingAgreement = "You'll be billed $59.99 every month for the next 12 months. To cancel at any time, go to Account and click 'Cancel Membership.'"
            
            
            
            
            let billingTrail = PKRecurringPaymentSummaryItem(label: "My Subscription Trail", amount: NSDecimalNumber(string: "0"))
            billingTrail.startDate = Date()
            billingTrail.endDate = Date().addingTimeInterval(60 * 60 * 24 * 7)
            billing.intervalUnit = .month
            recurringRequest.trialBilling = billing
            
            return recurringRequest
        } else {
            return nil
        }
    }
    
}

extension ViewController: SettingsDelegate {
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
}



extension ViewController:CheckoutScreenDelegate {
    func tapBottomSheetWillDismiss() {
        tapPayButtonViewModel.expandButton()
        adjustTapButton()
    }
    func checkoutFailed(with authorize: Authorize) {
        tapPayButtonViewModel.endLoading(with: false) {
            self.tapBottomSheetWillDismiss()
        }
    }
    func checkoutFailed(with charge: Charge) {
        tapPayButtonViewModel.endLoading(with: false) {
            self.tapBottomSheetWillDismiss()
        }
    }
    func checkoutFailed(in session: URLSessionDataTask?, for result: [String : String]?, with error: Error?) {
        tapPayButtonViewModel.endLoading(with: false) {
            self.tapBottomSheetWillDismiss()
        }
    }
    
    
    func checkoutCaptured(with charge: Charge) {
        print("HERE")
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
        
        if (cell?.accessoryType == .checkmark){
            cell!.accessoryType = .none;
        }else{
            cell!.accessoryType = .checkmark;
        }
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




//MARK:- CHANGED FILE NAMES
/**
 TapApplePayKit-iOS/TapApplePayKit-iOS/Core/public/Models/TapApplePayRequest.swift
 TapUIKit-iOS/TapUIKit-iOS/TapUIKit-iOS/Core/TapChip/Views/Chips/ApplePayChip/ApplePayChipViewCellModel.swift
 */
