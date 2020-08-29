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
    var localeID:String = "en"
    var localisationFileName:String? = "CustomLocalisation"
    var customTheme:TapCheckOutTheme? = nil
    @IBOutlet weak var amountTextField: UITextField!
    var selectedCurrency:TapCurrencyCode = .USD
    var amount:Double {
        return Double(amountTextField.text ?? "") ?? 1000
    }
    var swipeToDismiss:Bool = false
    var items:[ItemModel] = []
    var paymentTypes:[TapPaymentType] = [.All]
    
    @IBOutlet weak var paymentItemsTableView: UITableView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        amountTextField.delegate = self
        TapLocalisationManager.shared.localisationLocale = "en"
        TapThemeManager.setDefaultTapTheme()
        adjustTapButton()
        paymentItemsTableView.estimatedRowHeight = 100
        paymentItemsTableView.rowHeight = UITableView.automaticDimension
        paymentItemsTableView.register(UINib(nibName: "ItemTableViewCell", bundle: nil), forCellReuseIdentifier: "ItemTableViewCell")
        paymentItemsTableView.delegate = self
        paymentItemsTableView.dataSource = self
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
        tapPayButtonViewModel.startLoading()
        let checkout:TapCheckout = .init()
        TapCheckout.flippingStatus = .FlipOnLoadWithFlippingBack
        TapCheckout.localeIdentifier = localeID
        checkout.build(
            localiseFile: localisationFileName,
            customTheme: customTheme,
            delegate: self,
            currency: selectedCurrency,
            amount: amount,
            items: items,
            swipeDownToDismiss: swipeToDismiss,
            paymentTypes: paymentTypes,
            onCheckOutReady: {[weak self] tapCheckOut in
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
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
        let addItemsVC = AddItemViewController()
        addItemsVC.delegate = self
        let addItemsNav = UINavigationController(rootViewController: addItemsVC)
        present(addItemsNav, animated: true, completion: nil)
    }
}

extension ViewController: SettingsDelegate {
    func didUpdatePaymentTypes(to types: [TapPaymentType]) {
        paymentTypes = types
    }
    
    func didUpdateLanguage(with locale: String) {
        localeID = locale
        adjustTapButton()
    }
    
    func didUpdateLocalisation(to enabled: Bool) {
        localisationFileName = (enabled) ? "CustomLocalisation" : nil
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
}


extension ViewController:UITextFieldDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate, AddItemViewControllerDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell", for: indexPath) as! ItemTableViewCell
        cell.configure(with: items[indexPath.row])
        return cell
    }
    
    
    func addNewItem(with itemModel: ItemModel) {
        items.append(itemModel)
        self.paymentItemsTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            items.remove(at: indexPath.row)
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
    
}
