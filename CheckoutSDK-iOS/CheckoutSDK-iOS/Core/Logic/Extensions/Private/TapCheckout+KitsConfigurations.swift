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
     - Parameter swipeDownToDismiss: If it is set then when the user swipes down the payment will close, otherwise, there will be a shown button to dismiss the screen. Default is false
     - Parameter paymentType: The allowed payment types inclyding cards, apple pay, web and telecom
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
     - Parameter paymentReference: Implement this property to keep a reference to the transaction on your backend. Please check [Reference](x-source-tag://Reference)
     - Parameter paymentStatementDescriptor: Description of the payment  to appear on your settlemenets statement.
     - Parameter require3DSecure: Defines if you want to apply 3DS for this transaction. By default it is set to true.
     - Parameter receiptSettings: Defines how you want to notify about the status of transaction reciept by email, sms or both. Please check [Receipt](x-source-tag://Receipt)
     - Parameter authorizeAction: Defines what to do with the authorized amount after being authorized for a certain time interval. Please check [AuthorizeAction](x-source-tag://AuthorizeAction)
     - Parameter allowsToSaveSameCardMoreThanOnce: Defines if same card can be saved more than once. Default is `true`.
     - Parameter enableSaveCard: Defines if the customer can save his card for upcoming payments. Default is `true`.
     - Parameter isSaveCardSwitchOnByDefault: Defines if save card switch is on by default.. Default is `true`.
     */
    func configureSharedManager(currency:TapCurrencyCode,
                                amount:Double,
                                items:[ItemModel],applePayMerchantID:String = "merchant.tap.gosell",
                                swipeDownToDismiss:Bool = false,
                                paymentType:TapPaymentType,
                                closeButtonStyle:CheckoutCloseButtonEnum = .title,
                                showDragHandler:Bool = false,
                                transactionMode: TransactionMode,
                                customer: TapCustomer,
                                destinations: [Destination]?,
                                tapMerchantID: String? = nil,
                                taxes:[Tax]? = nil,
                                shipping:[Shipping] = [],
                                allowedCardTypes: [CardType] = [CardType(cardType: .All)],
                                postURL:URL? = nil,
                                paymentDescription:String? = nil,
                                paymentMetadata: TapMetadata = [:],
                                paymentReference: Reference? = nil,
                                paymentStatementDescriptor: String? = nil,
                                require3DSecure: Bool = true,
                                receiptSettings: Receipt? = nil,
                                authorizeAction: AuthorizeAction = AuthorizeAction.default,
                                allowsToSaveSameCardMoreThanOnce: Bool = true,
                                enableSaveCard: Bool = true,
                                isSaveCardSwitchOnByDefault: Bool = true) {
        
        
        // Shared data manager attributes
        let sharedManager = TapCheckout.sharedCheckoutManager()
        
        sharedManager.dataHolder.viewModels.swipeDownToDismiss = swipeDownToDismiss
        sharedManager.dataHolder.viewModels.closeButtonStyle = closeButtonStyle
        sharedManager.dataHolder.viewModels.showDragHandler = showDragHandler
        
        
         /*sharedManager.dataHolder.transactionData = TransactionDataHolder.init(dataHolderDelegate:sharedManager, paymentType: paymentType, applePayMerchantID: applePayMerchantID, transactionMode: transactionMode, customer: customer, destinations: destinations, tapMerchantID: tapMerchantID, taxes: taxes, shipping: shipping, allowedCardTypes: allowedCardTypes, postURL: postURL, paymentDescription: paymentDescription, paymentMetadata: paymentMetadata, paymentReference: paymentReference, paymentStatementDescriptor: paymentStatementDescriptor, require3DSecure: require3DSecure, receiptSettings: receiptSettings, authorizeAction: authorizeAction, allowsToSaveSameCardMoreThanOnce: allowsToSaveSameCardMoreThanOnce, enableSaveCard: enableSaveCard, isSaveCardSwitchOnByDefault: isSaveCardSwitchOnByDefault, transactionCurrencyValue: .init(currency, amount, "")) */
        
        sharedManager.dataHolder.transactionData.dataHolderDelegate = sharedManager
        
        sharedManager.dataHolder.transactionData.transactionCurrencyValue   = .init(currency, amount, "")
        sharedManager.dataHolder.transactionData.applePayMerchantID         = applePayMerchantID
        sharedManager.dataHolder.transactionData.paymentType                = paymentType
        
        sharedManager.dataHolder.transactionData.transactionMode            = transactionMode
        sharedManager.dataHolder.transactionData.customer                   = customer
        sharedManager.dataHolder.transactionData.destinations               = destinations
        sharedManager.dataHolder.transactionData.tapMerchantID              = tapMerchantID
        sharedManager.dataHolder.transactionData.taxes                      = taxes
        sharedManager.dataHolder.transactionData.shipping                   = shipping
        sharedManager.dataHolder.transactionData.allowedCardTypes           = allowedCardTypes
        sharedManager.dataHolder.transactionData.paymentDescription         = paymentDescription
        sharedManager.dataHolder.transactionData.paymentMetadata            = paymentMetadata
        sharedManager.dataHolder.transactionData.paymentReference           = paymentReference
        sharedManager.dataHolder.transactionData.paymentStatementDescriptor = paymentStatementDescriptor
        sharedManager.dataHolder.transactionData.require3DSecure            = require3DSecure
        sharedManager.dataHolder.transactionData.receiptSettings            = receiptSettings
        sharedManager.dataHolder.transactionData.authorizeAction            = authorizeAction
        
        
        // if items has no items, we need to add the default items
        if items == [] {
            sharedManager.dataHolder.transactionData.transactionItemsValue = [ItemModel.init(title: "PAY TO TAP PAYMENTS",description: "Total paid amount", price: amount, quantity: .init(value: 1, unitOfMeasurement: .units),discount: nil, totalAmount: 0)]
        }else {
            sharedManager.dataHolder.transactionData.transactionItemsValue = items
        }
    }
    
    
    /**
     Will be respinsble for dismissing the checkout screen and changing the action button to success or failure before dismissing
     - Parameter with buttonStatus: The success or failure to be displayed on the action button before dismissing
     */
    func dismissCheckout(with buttonStatus:Bool) {
        dataHolder.viewModels.tapActionButtonViewModel.endLoading(with: buttonStatus, completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.UIDelegate?.dismissCheckout(with: "")
            }
        })
    }
}