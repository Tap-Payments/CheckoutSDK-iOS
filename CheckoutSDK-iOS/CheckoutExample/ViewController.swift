//
//  ViewController.swift
//  CheckoutExample
//
//  Created by Osama Rabie on 7/31/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import UIKit
import CheckoutSDK_iOS

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
        TapCheckout.secretKey = .init(sandbox: "sk_test_cvSHaplrPNkJO7dhoUxDYjqA",
                                      production: "sk_live_V4UDhitI0r7sFwHCfNB6xMKp")
        
        //customTheme = .init(with: "https://menoalmotasel.online/RedLightTheme.json", and: "https://menoalmotasel.online/RedDarkTheme.json", from: .RemoteJsonFile)
        
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
            customer: tapSettings.customer,/* try! .init(emailAddress: .with("osamaguc@gmail.com"), phoneNumber: nil, name: "Osama Ahmed Helmy")*/
            tapMerchantID: "1124340",
            taxes: [],
            shipping: [],
            require3DSecure: true,
            sdkMode: .sandbox,
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
    func checkoutFailed(with error:Error) {
        tapPayButtonViewModel.endLoading(with: false) {
            self.tapBottomSheetWillDismiss()
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


