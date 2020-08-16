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
    var selectedCurrency:TapCurrencyCode = .KWD
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
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
        
        checkout.build(
                localiseFile: localisationFileName,
                customTheme: customTheme,
                delegate: self,
                currency: selectedCurrency
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
