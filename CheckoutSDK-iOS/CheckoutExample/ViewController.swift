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
    var localisationFileName:String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
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
        checkout.tapCheckoutScreenDelegate = self
        present(checkout.startCheckoutSDK(localiseFile: localisationFileName), animated: true, completion: nil)
    }
    @IBAction func showSettings(_ sender: UIButton) {
        let settingsVC = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        settingsVC.delegate = self
        present(settingsVC, animated: true, completion: nil)
    }
}

extension ViewController: LocalisationSettingsDelegate {
    func didUpdateLanguage(with locale: String) {
        print("new localisation: \(locale)")
    }    
}



extension ViewController:CheckoutScreenDelegate {
    func tapBottomSheetWillDismiss() {
        adjustTapButton()
    }
    
    func didUpdateLocalisation(to enabled: Bool) {
        print("didUpdateLocalisation: \(enabled)")
    }
}
