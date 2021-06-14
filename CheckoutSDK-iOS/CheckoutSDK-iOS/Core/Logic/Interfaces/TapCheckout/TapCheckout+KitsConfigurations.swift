//
//  TapCheckout+KitsConfigurations.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/16/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
import MOLH
import CommonDataModelsKit_iOS
import TapUIKit_iOS
import TapThemeManager2020

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
     - Parameter applePayMerchantID: The Apple pay merchant id to be used inside the apple pay kit
     - Parameter intentModel: The loaded Intent API response model
     - Parameter swipeDownToDismiss: If it is set then when the user swipes down the payment will close, otherwise, there will be a shown button to dismiss the screen. Default is false
     - Parameter paymentTypes: The allowed payment types inclyding cards, apple pay, web and telecom
     - Parameter closeButtonStyle: Defines the required style of the sheet close button
     - Parameter showDragHandler: Decide to show the drag handler or not
     - Parameter transactionMode: Decide which transaction mode will be used in this call. Purchase, Authorization, Card Saving and Toknization. Please check [TransactionMode](x-source-tag://TransactionModeEnum)
     - Parameter customer: Decides which customer is performing this transaction. It will help you as a merchant to define the payer afterwards. Please check [TapCustomer](x-source-tag://TapCustomer)
     - Parameter destinations: Decides which destination(s) this transaction's amount should split to. Please check [Destination](x-source-tag://Destination)
     - Parameter tapMerchantID: Optional. Useful when you have multiple Tap accounts and would like to do the `switch` on the fly within the single app.
     - Parameter taxes: Optional. List of Taxes you want to apply to the order if any.
     - Parameter shipping: Optional. List of Shipping you want to apply to the order if any.
     - Parameter allowedCadTypes: Decides the allowed card types whether Credit or Debit or All. If not set all will be accepeted.
     - Parameter postURL: The URL that will be called by Tap system notifying that payment has succeed or failed.
     - Parameter paymentDescription: Description of the payment to use for further analysis and processing in reports.
     - Parameter TapMetadata: Additional information you would like to pass along with the transaction. Please check [TapMetaData](x-source-tag://TapMetaData)
     */
    func configureSharedManager(currency:TapCurrencyCode,
                                amount:Double,
                                items:[ItemModel],applePayMerchantID:String = "merchant.tap.gosell",
                                intentModel:TapIntentResponseModel,
                                swipeDownToDismiss:Bool = false,
                                paymentTypes:[TapPaymentType],
                                closeButtonStyle:CheckoutCloseButtonEnum = .title,
                                showDragHandler:Bool = false,
                                transactionMode: TransactionMode,
                                customer: TapCustomer,
                                destinations: [Destination]?,
                                tapMerchantID: String? = nil,
                                taxes:[Tax] = [],
                                shipping:[Shipping] = [],
                                allowedCardTypes: [CardType] = [CardType(cardType: .All)],
                                postURL:URL? = nil,
                                paymentDescription:String? = nil,
                                paymentMetadata: TapMetadata = [:]) {
        
        let sharedManager = TapCheckoutSharedManager.sharedCheckoutManager()
        sharedManager.transactionCurrencyValue = currency
        sharedManager.applePayMerchantID = applePayMerchantID
        sharedManager.paymentTypes = paymentTypes
        sharedManager.swipeDownToDismiss = swipeDownToDismiss
        sharedManager.intentModelResponse = intentModel
        sharedManager.closeButtonStyle = closeButtonStyle
        sharedManager.showDragHandler = showDragHandler
        sharedManager.transactionMode = transactionMode
        sharedManager.customer = customer
        sharedManager.destinations = destinations
        sharedManager.tapMerchantID = tapMerchantID
        sharedManager.taxes = taxes
        sharedManager.shipping = shipping
        sharedManager.allowedCardTypes = allowedCardTypes
        sharedManager.paymentDescription = paymentDescription
        sharedManager.paymentMetadata = paymentMetadata
        
        // a variable used to hold the correct amount, which will be the passed amount in case no items or the total items' prices when items are passed
        var finalAmount:Double = amount
        // if items has no items, we need to add the default items
        if items == [] {
            sharedManager.transactionItemsValue = [ItemModel.init(title: "PAY TO TAP PAYMENTS",description: "Total paid amount", price: amount, quantity: 1,discount: nil,totalAmount: 0)]
        }else {
            sharedManager.transactionItemsValue = items
            finalAmount = items.totalItemsPrices()
        }
        // Tell the manager what is the final amount based on given items prices or a given total amount
        sharedManager.transactionTotalAmountValue = finalAmount
        
        
    }
    
}
