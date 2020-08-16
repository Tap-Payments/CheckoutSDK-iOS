//
//  TapCheckout+KitsConfigurations.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/16/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
import MOLH
/// An extensions that groups methods related to configuring other Tap Kits before starting the checkout SDK itself
internal extension TapCheckout {
 
    
    /// Configures the bottom sheet by creating one and assigning the correct delegates and datasources
    func configureBottomSheet() {
        // Create the sheet itself
        bottomSheetController = TapBottomSheetDialogViewController()
        bottomSheetController.dataSource = self
        bottomSheetController.delegate = self
        bottomSheetController.modalPresentationStyle = .overCurrentContext
        // Make sure the theme is applied or we apply the default theme
        guard let _ = TapThemeManager.currentTheme else {
            TapThemeManager.setDefaultTapTheme()
            return
        }
    }
    /** Configures the localisation manager bu setting the locale, adjusting the flipping and the localisation custom file if any
     - Parameter localiseFile: Please pass the name of the custom localisation file if needed. If not set, the normal and default TAP localisations will be used
     */
    func configureLocalisationManager(localiseFile:String? = nil) {
        // Set the required locale
        sharedLocalisationManager.localisationLocale = TapCheckout.localeIdentifier
        // Adjust the flipping
        if TapCheckout.flippingStatus != .NoFlipping {
            MOLH.setLanguageTo(TapCheckout.localeIdentifier)
        }
        // Check if the user provided a custom localisation file to use and it is a correct and a reachable one
        guard let localiseFile = localiseFile,
            let stringPath = Bundle.main.path(forResource: localiseFile, ofType: "json") else { return }
        let urlPath = URL(fileURLWithPath: stringPath)
        sharedLocalisationManager.localisationFilePath = urlPath
    }
    
    /** Configures the theme manager by setting the provided custom theme file names
     - Parameter customTheme: Please pass the tap checkout theme object with the names of your custom theme files if needed. If not set, the normal and default TAP theme will be used
     */
    func configureThemeManager(customTheme:TapCheckOutTheme? = nil) {
        guard let nonNullCustomTheme = customTheme else {
            TapThemeManager.setDefaultTapTheme()
            return
        }
        
        TapThemeManager.setDefaultTapTheme(lightModeJSONTheme: nonNullCustomTheme.lightModeThemeFileName ?? "", darkModeJSONTheme: nonNullCustomTheme.darkModeThemeFileName ?? "")
    }
    
    /** Configures the Checkout shared manager by setting the provided custom data gatherd by the merchant
     - Parameter currency: Represents the original transaction currency stated by the merchant on checkout start
     */
    func configureSharedManager(currency:TapCurrencyCode) {
        let sharedManager = TapCheckoutSharedManager.sharedCheckoutManager
        sharedManager.transactionCurrencyObserver.accept(currency)
        // Bind observables
        
        // Listen to changes in user currency
        sharedManager.userSelectedCurrencyObserver.share().subscribe(onNext: { [weak self] (newUserCurrency) in
            self?.userSelectedCurrencyChanged(with: newUserCurrency)
        }).disposed(by: disposeBag)
    }
    
    /**
     Listen to changes in user currency
     - Parameter newUserCurrency: The new selected currency by the user
     */
    func userSelectedCurrencyChanged(with newUserCurrency:TapCurrencyCode) {
        // Update the items list price and UI
        tapCheckoutControllerViewController.updateItemsList(with: newUserCurrency)
        // Update the amount section
        tapCheckoutControllerViewController.updateAmountSection(with: newUserCurrency)
    }
    
}
