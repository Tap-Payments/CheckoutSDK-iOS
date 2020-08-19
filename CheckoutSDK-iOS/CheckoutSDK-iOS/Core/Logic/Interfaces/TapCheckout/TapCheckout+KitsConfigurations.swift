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
     - Parameter amount: Represents the original transaction amount stated by the merchant on checkout start
     - Parameter items: Represents the List of payment items if any. If no items are provided one will be created by default as PAY TO [MERCHANT NAME] -- Total value
     */
    func configureSharedManager(currency:TapCurrencyCode, amount:Double,items:[ItemModel]) {
        let sharedManager = TapCheckoutSharedManager.sharedCheckoutManager()
        sharedManager.transactionCurrencyObserver.accept(currency)
        
        // if items has no items, we need to add the default items
        if items == [] {
            sharedManager.transactionItemsObserver.accept([ItemModel.init(title: "PAY TO TAP PAYMENTS",description: nil, price: amount, quantity: 1,discount: nil)])
        }else {
            sharedManager.transactionItemsObserver.accept(items)
        }
        
        sharedManager.transactionTotalAmountObserver.accept(items.totalItemsPrices())
    }
    
}
