//
//  TapCheckout+TransactionData.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/20/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// Protocol to instruct parent upon important data changes to act upon
internal protocol TapCheckoutDataHolderDelegate {
    func updateGatewayChipsList()
    func parseInitResponse()
    func parsePaymentOptionsResponse()
    func parseIntentResponse()
    func transactionCurrencyUpdated()
    func handleChangeAmountAndCurrency()
    func calculateFinalAmount()->Double
    func createTapItemsViewModel()
}

/// A struct that holds the data related to the current transaction
internal struct DataHolder {
    var viewModels:ViewModelsHolder = .init()
    var transactionData:TransactionDataHolder = .init()
}

/// Struct that holds view models and UI related variables
internal struct ViewModelsHolder {
    /// Rerpesents the view model that controls the Merchant header section view
    var tapMerchantViewModel:TapMerchantHeaderViewModel = .init()
    /// Rerpesents the view model that controls the Amount section view
    var tapAmountSectionViewModel:TapAmountSectionViewModel = .init()
    /// Rerpesents the view model that controls the items list view
    var tapItemsTableViewModel:TapGenericTableViewModel = .init()
    /// Represents the view model that controls the payment gateway chips list view
    var tapGatewayChipHorizontalListViewModel:TapChipHorizontalListViewModel = .init(dataSource: [], headerType: .GateWayListWithGoPayListHeader)
    /// Represents the view model that controls the gopay gateway chips list view
    var tapGoPayChipsHorizontalListViewModel:TapChipHorizontalListViewModel = .init(dataSource: [], headerType: .GoPayListHeader)
    /// Represents the view model that controls the cards/telecom tabs view
    var tapCardPhoneListViewModel:TapCardPhoneBarListViewModel = .init()
    /// Represents the view model that controls the tabbar view
    var tapCardTelecomPaymentViewModel: TapCardTelecomPaymentViewModel = .init()
    /// Represents the view model that controls the chips list of supported currencies view
    var tapCurrienciesChipHorizontalListViewModel:TapChipHorizontalListViewModel = .init()
    /// Represents the view model that controls the save card/number view
    var tapSaveCardSwitchViewModel: TapSwitchViewModel = .init(with: .invalidCard, merchant: "jazeera airways")
    /// Represents the view model that controls the country picker when logging in to goPay using the phone number
    var goPayBarViewModel:TapGoPayLoginBarViewModel?
    /// Represents the view model that controls the action button view
    let tapActionButtonViewModel: TapActionButtonViewModel = .init()
    /// If it is set then when the user swipes down the payment will close, otherwise, there will be a shown button to dismiss the screen. Default is false
    var swipeDownToDismiss:Bool = false
    /// Repreents the list fof supported currencies
    var currenciesChipsViewModel:[CurrencyChipViewModel] = []
    /// Repreents the list fof supported currencies
    var goPayLoginCountries:[TapCountry] = []
    /// Represents the required style of the sheet close button
    var closeButtonStyle:CheckoutCloseButtonEnum = .title
    /// Represents the drag handler to be shown or not
    var showDragHandler:Bool = false
    /// Represents the list of ALL allowed telecom/cards payments for the logged in merchant
    var tapCardPhoneListDataSource:[CurrencyCardsTelecomModel] = []
    /// Represents the list of ALL allowed payment chips for the logged in merchant
    var gatewayChipsViewModel:[ChipWithCurrencyModel] = []
    /// Represents the list of ALL allowed goPay chips for the logged in customer
    var goPayChipsViewModel:[ChipWithCurrencyModel] = []
    
}

/// Struct that holds transaction related variables
internal struct TransactionDataHolder {
    
    /// Protocol to instruct parent upon important data changes to act upon
    var dataHolderDelegate:TapCheckoutDataHolderDelegate?
    
    /// Represents the data loaded from the Init api on checkout start
    var intitModelResponse:TapInitResponseModel?{
        didSet{
            // Now it is time to fetch needed data from the model parsed
            dataHolderDelegate?.parseInitResponse()
        }
    }
    /// Represents the data loaded from the Init api on checkout start
    var paymentOptionsModelResponse:TapPaymentOptionsReponseModel?{
        didSet{
            // Now it is time to fetch needed data from the model parsed
            dataHolderDelegate?.parsePaymentOptionsResponse()
        }
    }
    /// Represents the data loaded from the Intent api on checkout start
    var intentModelResponse:TapIntentResponseModel?{
        didSet{
            // Now it is time to fetch needed data from the model parsed
            dataHolderDelegate?.parseIntentResponse()
        }
    }
    
    // MARK:- UI Related Variables
    
    
    
    // MARK:- Transaction Configuration Variables
    
    /// Defines the mode sandbox or production the sdk will perform this transaction on. Please check [SDKMode](x-source-tag://SDKMode)
    var sdkMode:SDKMode = .sandbox
    
    /// Represents The allowed payment types inclyding cards, apple pay, web and telecom
    var paymentType:TapPaymentType = .All
    
    
    /// Represents The Apple pay merchant id to be used inside the apple pay kit
    var applePayMerchantID:String = ""
    /// Represents if the current customer is logged in to goPay
    var loggedInToGoPay:Bool = false {
        didSet{
            dataHolderDelegate?.updateGatewayChipsList()
        }
    }
    /// Which transaction mode will be used in this call. Purchase, Authorization, Card Saving and Toknization. Please check [TransactionMode](x-source-tag://TransactionModeEnum)
    var transactionMode:TransactionMode = .purchase
    
    /// Decides which customer is performing this transaction. It will help you as a merchant to define the payer afterwards. Please check [TapCustomer](x-source-tag://TapCustomer)
    var customer:TapCustomer = TapCustomer.defaultCustomer()
    
    /// Decides which destination(s) this transaction's amount should split to. Please check [Destination](x-source-tag://Destination)
    var destinations: [Destination]?
    
    /// Merchant ID. Optional. Useful when you have multiple Tap accounts and would like to do the `switch` on the fly within the single app.
    var tapMerchantID:String?
    
    /// Optional. List of Taxes you want to apply to the order if any.
    var taxes:[Tax]? = nil
    
    /// Optional. List of Shipping you want to apply to the order if any.
    var shipping:[Shipping] = []
    
    /// allowed Card Types, if not set all will be accepeted.
    var allowedCardTypes:[CardType] = [CardType(cardType: .Debit), CardType(cardType: .Credit)] {
        didSet {
            if allowedCardTypes.count == 1 && allowedCardTypes[0].cardType == .All {
                allowedCardTypes = [CardType(cardType: .Debit), CardType(cardType: .Credit)]
            }
        }
    }
    
    /// The URL that will be called by Tap system notifying that payment has succeed or failed.
    var postURL:URL?
    
    /// Description of the payment to use for further analysis and processing in reports.
    var paymentDescription:String?
    
    /// Additional information you would like to pass along with the transaction. Please check [TapMetaData](x-source-tag://TapMetaData)
    var paymentMetadata: TapMetadata = [:]
    
    /// Payment reference. Implement this property to keep a reference to the transaction on your backend.
    var paymentReference: Reference?
    
    /// Description of the payment  to appear on your settlemenets statement.
    var paymentStatementDescriptor: String?
    
    /// Defines if you want to apply 3DS for this transaction. By default it is set to true.
    var require3DSecure: Bool = true
    
    /// Defines how you want to notify about the status of transaction reciept by email, sms or both. Please check [Receipt](x-source-tag://Receipt)
    var receiptSettings: Receipt? = nil
    
    /// Authorize action model to state what to do with the authorized amount after being authorized for a certain time interval. Please check [AuthorizeAction](x-source-tag://AuthorizeAction)
    var authorizeAction: AuthorizeAction = AuthorizeAction.default
    
    /// Defines if same card can be saved more than once.
    /// Default is `true`.
    var allowsToSaveSameCardMoreThanOnce: Bool = true
    
    
    /// Defines if the customer can save his card for upcoming payments
    /// Default is `true`.
    var enableSaveCard: Bool = true
    
    /// Defines if save card switch is on by default.
    /// - Note: If value of this property is `true`, then switch will be remaining off until card information is filled and valid.
    ///         And after will be toggled on automatically.
    var isSaveCardSwitchOnByDefault: Bool = true
    
    // MARK:- RxSwift Variables
    
    /// Represents the original transaction currency stated by the merchant on checkout start
    var transactionCurrencyValue:AmountedCurrency = .init(.undefined, 0, "") {
        didSet{
            guard oldValue != transactionCurrencyValue else { return }
            if transactionCurrencyValue.currency != .undefined {
                // Listen to the changes in transaction currency
                dataHolderDelegate?.transactionCurrencyUpdated()
            }
        }
    }
    
    /// Represents the transaction currency selected by the user
    var transactionUserCurrencyValue:AmountedCurrency = .init(.undefined, 0, "") {
        didSet{
            guard oldValue != transactionUserCurrencyValue else { return }
            dataHolderDelegate?.handleChangeAmountAndCurrency()
        }
    }
    
    /// Represents the original transaction total amount stated by the merchant on checkout start
    var transactionTotalAmountValue:Double {
        return dataHolderDelegate?.calculateFinalAmount() ?? 0
    }
    
    /// Represents the list of items passed by the merchant on load
    var transactionItemsValue:[ItemModel] = [] {
        didSet{
            // We only create items list when we have both elements, items and original currency
            if transactionItemsValue != [] {
                dataHolderDelegate?.createTapItemsViewModel()
            }
        }
    }
    
    /// Represents the payment option the user is actively selecting right now
    var selectedPaymentOption:PaymentOption?
    
}
