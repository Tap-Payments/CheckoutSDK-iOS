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
    let tapPayButtonViewModel:TapActionButtonViewModel = .init()
    var localeID:String = "en"
    var localisationFileName:String? = "CustomLocalisation"
    var customTheme:TapCheckOutTheme? = nil
    @IBOutlet weak var amountTextField: UITextField!
    var selectedCurrency:TapCurrencyCode = .USD
    var amount:Double = 1000
    var items:[ItemModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        amountTextField.delegate = self
        TapLocalisationManager.shared.localisationLocale = "en"
        TapThemeManager.setDefaultTapTheme()
        adjustTapButton()
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
        let checkout:TapCheckout = .init()
        TapCheckout.flippingStatus = .FlipOnLoadWithFlippingBack
        TapCheckout.localeIdentifier = localeID
        items = []
        for i in 1...Int.random(in: 3..<20) {
            var itemTitle:String = "Item Title # \(i)"
            if i % 5 == 4 {
                itemTitle = "VERY LOOOOOOOOOOOOOONG ITEM TITLE Item Title # \(i)"
            }
            let itemDescriptio:String = "Item Description # \(i)"
            let itemPrice:Double = Double.random(in: 10..<4000)
            let itemQuantity:Int = Int.random(in: 1..<10)
            let itemDiscountValue:Double = Double.random(in: 0..<itemPrice)
            var itemDiscount:DiscountModel? = .init(type: .Fixed, value: itemDiscountValue)
            if i % 5 == 2 {
                itemDiscount = nil
            }
            let itemModel:ItemModel = .init(title: itemTitle, description: itemDescriptio, price: itemPrice, quantity: itemQuantity, discount: itemDiscount)
            items.append(itemModel)
        }
        
        
        checkout.build(
                localiseFile: localisationFileName,
                customTheme: customTheme,
                delegate: self,
                currency: selectedCurrency,
                amount: amount,
                items: items
            ).start(presentIn: self)
    }
    
    @IBAction func showSettings(_ sender: UIButton) {
        let settingsVC = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        settingsVC.delegate = self
        present(settingsVC, animated: true, completion: nil)
    }
}

extension ViewController: SettingsDelegate {
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
}



extension ViewController:CheckoutScreenDelegate {
    func tapBottomSheetWillDismiss() {
        adjustTapButton()
    }
}


extension ViewController:UITextFieldDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        amount = Double(amountTextField.text ?? "") ?? 1000
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
