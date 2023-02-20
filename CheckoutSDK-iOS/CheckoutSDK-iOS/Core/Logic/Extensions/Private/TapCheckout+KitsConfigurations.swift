//
//  TapCheckout+KitsConfigurations.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/16/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
//import MOLH
import CommonDataModelsKit_iOS
import TapUIKit_iOS
import TapThemeManager2020
import PassKit
import TapApplePayKit_iOS

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
    /** Configures the localisation manager bu setting the locale, adjusting the flipping and the localisation custom model if any
     - Parameter localiseFile: Please pass the name of the custom localisation model if needed. If not set, the normal and default TAP localisations will be used
     */
    func configureLocalisationManager(localiseFile:TapCheckoutLocalisation? = nil) {
        // Set the required locale
        sharedLocalisationManager.localisationLocale = TapCheckout.localeIdentifier
        // Adjust the flipping
        if TapCheckout.flippingStatus != .NoFlipping {
            //MOLH.setLanguageTo(TapCheckout.localeIdentifier)
        }
        
        // Check if the user provided a custom localisation file to use and it is a correct and a reachable one
        // Depends on the type of the localisation whether remote or locale
        guard let nonNullLocalisationModel = localiseFile,
              let nonNullLocaltionType = nonNullLocalisationModel.localisationType else { return }
        let _ = sharedLocalisationManager.configureLocalisation(with: nonNullLocalisationModel.filePath, or: nonNullLocalisationModel.localisationData, from: nonNullLocaltionType)
    }
    
    /** Configures the theme manager by setting the provided custom theme file names
     - Parameter customTheme: Please pass the tap checkout theme object with the names of your custom theme files if needed. If not set, the normal and default TAP theme will be used
     */
    func configureThemeManager(customTheme:TapCheckOutTheme? = nil) {
        guard let nonNullCustomTheme = customTheme else {
            TapThemeManager.setDefaultTapTheme()
            return
        }
        switch nonNullCustomTheme.themeType {
        case .LocalJsonFile: TapThemeManager.setDefaultTapTheme(lightModeJSONTheme: nonNullCustomTheme.lightModeThemeFileName ?? "", darkModeJSONTheme: nonNullCustomTheme.darkModeThemeFileName ?? "")
        case .RemoteJsonFile: TapThemeManager.setDefaultTapTheme(lightModeURLTheme: URL(string:nonNullCustomTheme.lightModeThemeFileName ?? "") ?? nil, darkModeURLTheme: URL(string: nonNullCustomTheme.darkModeThemeFileName ?? "") ?? nil)
        case .none:
            TapThemeManager.setDefaultTapTheme(lightModeJSONTheme: nonNullCustomTheme.lightModeThemeFileName ?? "", darkModeJSONTheme: nonNullCustomTheme.darkModeThemeFileName ?? "")
        }
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
     - Parameter enableApiLogging: Defines which level of logging do you wnt to enable. [TapLoggingType](x-source-tag://TapLoggingType)
     - Parameter isSaveCardSwitchOnByDefault: Defines if save card switch is on by default.. Default is `true`.
     - Parameter collectCreditCardName: Decides whether or not, the card input should collect the card holder name. Default is false
     - Parameter creditCardNameEditable: Decides whether or not, the card name field will be editable
     - Parameter creditCardNamePreload: Decides whether or not, the card name field should be prefilled
     - Parameter showSaveCreditCard: Decides whether or not, the card input should show save card option. Default is false
     - Parameter isSubscription: Defines if you want to make a subscription based transaction. Default is false
     - Parameter recurringPaymentRequest: Defines the recurring payment request Please check [Apple Pay docs](https://developer.apple.com/documentation/passkit/pkrecurringpaymentrequest). NOTE: This will only be availble for iOS 16+ and subscripion parameter is on.
     - Parameter applePayButtonType: Defines the type of the apple pay button like Pay with or Subscripe with  etc. Default is Pay
     - Parameter applePayButtonStyle: Defines the UI of the apple pay button white, black or outlined. Default is black
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
                                shipping:Shipping? = nil,
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
                                enableApiLogging:[TapLoggingType] = [.CONSOLE],
                                isSaveCardSwitchOnByDefault: Bool = true,
                                collectCreditCardName:Bool = false,
                                creditCardNameEditable:Bool = true,
                                creditCardNamePreload:String = "",
                                showSaveCreditCard:SaveCardType = .None,
                                isSubscription:Bool = false,
                                recurringPaymentRequest:Any? = nil,
                                applePayButtonType:TapApplePayButtonType = .AppleLogoOnly,
                                applePayButtonStyle:TapApplePayButtonStyleOutline = .Black
    ) {
        
        
        // Shared data manager attributes
        let sharedManager = TapCheckout.sharedCheckoutManager()
        
        // Configure the logger
        sharedManager.dataHolder.transactionData.enableApiLogging = enableApiLogging
        configureBugFinder()
        
        // Set the transaction and view models data
        sharedManager.dataHolder.viewModels.swipeDownToDismiss = swipeDownToDismiss
        sharedManager.dataHolder.viewModels.collectCreditCardName = collectCreditCardName
        sharedManager.dataHolder.viewModels.creditCardNameEditable = creditCardNameEditable
        sharedManager.dataHolder.viewModels.creditCardNamePreload = creditCardNamePreload
        sharedManager.dataHolder.viewModels.showSaveCreditCard = showSaveCreditCard
        sharedManager.dataHolder.viewModels.closeButtonStyle = closeButtonStyle
        sharedManager.dataHolder.viewModels.showDragHandler = showDragHandler
        
        sharedManager.dataHolder.transactionData.dataHolderDelegate = sharedManager
        
        sharedManager.dataHolder.transactionData.transactionCurrencyValue       = .init(currency, amount, "")
        sharedManager.dataHolder.transactionData.applePayMerchantID             = applePayMerchantID
        sharedManager.dataHolder.transactionData.paymentType                    = paymentType
        
        sharedManager.dataHolder.transactionData.transactionMode                = transactionMode
        sharedManager.dataHolder.transactionData.customer                       = customer
        sharedManager.dataHolder.transactionData.destinations                   = destinations
        sharedManager.dataHolder.transactionData.tapMerchantID                  = tapMerchantID
        sharedManager.dataHolder.transactionData.taxes                          = taxes
        sharedManager.dataHolder.transactionData.shipping                       = shipping
        sharedManager.dataHolder.transactionData.allowedCardTypes               = allowedCardTypes
        sharedManager.dataHolder.transactionData.paymentDescription             = paymentDescription
        sharedManager.dataHolder.transactionData.paymentMetadata                = paymentMetadata
        sharedManager.dataHolder.transactionData.paymentReference               = paymentReference
        sharedManager.dataHolder.transactionData.paymentStatementDescriptor     = paymentStatementDescriptor
        sharedManager.dataHolder.transactionData.require3DSecure                = require3DSecure
        sharedManager.dataHolder.transactionData.receiptSettings                = receiptSettings
        sharedManager.dataHolder.transactionData.authorizeAction                = authorizeAction
        
        sharedManager.dataHolder.transactionData.allowsToSaveSameCardMoreThanOnce = allowsToSaveSameCardMoreThanOnce
        sharedManager.dataHolder.transactionData.enableSaveCard                 = enableSaveCard
        sharedManager.dataHolder.transactionData.isSaveCardSwitchOnByDefault    = isSaveCardSwitchOnByDefault
        
        // Correctly set the recurring payment request
        if #available(iOS 16.0, *),
           isSubscription,
           let correctRequest:PKRecurringPaymentRequest = recurringPaymentRequest as?  PKRecurringPaymentRequest {
            sharedManager.dataHolder.transactionData.isSubscription = true
            sharedManager.dataHolder.transactionData.recurringPaymentRequest = correctRequest
        } else {
            // Fallback on earlier versions
            sharedManager.dataHolder.transactionData.isSubscription = false
            sharedManager.dataHolder.transactionData.recurringPaymentRequest = nil
        }
        
        sharedManager.dataHolder.transactionData.applePayButtonType     = applePayButtonType
        sharedManager.dataHolder.transactionData.applePayButtonStyle    = applePayButtonStyle
        
        // if items has no items, we need to add the default items
        if items == [] {
            /// - tag: DefaultItemsCreation
            // Please note that we didn't call the init api yet, hence we don't know the merchant name. We will create one item and we will call it PAY TO TAP PAYMENTS, once the init api comes in, we will change the title to hold the merchant's name.
            sharedManager.dataHolder.transactionData.transactionItemsValue = [ItemModel.init(title: TapCheckout.defaulItemTitle,description: "Total paid amount", price: amount, quantity: 1,discount: nil, totalAmount: 0,requiresShipping: false)]
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
