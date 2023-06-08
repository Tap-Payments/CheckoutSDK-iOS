//
//  TapCheckout+TransactionData.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/20/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import TapUIKit_iOS
import CommonDataModelsKit_iOS
import PassKit
import TapApplePayKit_iOS

/// Protocol to instruct parent upon important data changes to act upon
internal protocol TapCheckoutDataHolderDelegate {
    /// Handles all the logic needed when the user selected currency changed to reflect in the supported gateways chips for the new currency
    /// - Parameter shouldSort: If true, then update will have to sort the enabled payment options first then append the disabled sorted as well.
    func updateGatewayChipsList(shouldSort:Bool)
    /// Handles the logic to fetch different sections from the INIT api response
    func parseInitResponse()
    /// Handles the logic to fetch different sections from the Payment options response
    func parsePaymentOptionsResponse()
    /// Handles the logic to perform parsing for the card data loaded from the bin lookup api
    func parseTapBinResponse()
    /// Handles all the logic needed when the original transaction currency changed
    func transactionCurrencyUpdated()
    /// The amount section and items list will be changed if total amount or the selected currency is changed one of them or both
    func handleChangeAmountAndCurrency()
    /// Used to calclate the total price to be paid by the user, taking in consideration the items (each item with price. quantity, discounts, taxes) a transaction level shipping and taxes
    func calculateFinalAmount()->Double
    func createTapItemsViewModel()
}

/// A struct that holds the data related to the current transaction
internal class DataHolder {
    var viewModels:ViewModelsHolder = .init()
    var transactionData:TransactionDataHolder = .init()
    var themeLocalisationHolder:ThemeLocalisationHolder = .init()
    
    init(viewModels:ViewModelsHolder = .init() ,transactionData:TransactionDataHolder = .init(), themeLocalisationHolder:ThemeLocalisationHolder = .init()) {
        self.viewModels = viewModels
        self.transactionData = transactionData
        self.themeLocalisationHolder = themeLocalisationHolder
    }
}

/// A struct to hold the custom theme and localisations passed by the merchant
internal class ThemeLocalisationHolder {
    internal init(customTheme: TapCheckOutTheme? = nil, localiseFile: TapCheckoutLocalisation? = nil) {
        self.customTheme = customTheme
        self.localiseFile = localiseFile
    }
    
    /// The custom theme passed by the merchant
    var customTheme:TapCheckOutTheme? = nil
    /// The custom localisation passed by the merchant
    var localiseFile:TapCheckoutLocalisation? = nil
}

/// Struct that holds view models and UI related variables
internal class ViewModelsHolder {
    
    internal init(tapMerchantViewModel: TapMerchantHeaderViewModel = .init(), tapAmountSectionViewModel: TapAmountSectionViewModel = .init(), tapItemsTableViewModel: TapGenericTableViewModel = .init(), tapGatewayChipHorizontalListViewModel: TapChipHorizontalListViewModel = .init(dataSource: [], headerType: .GateWayListWithGoPayListHeader), tapGoPayChipsHorizontalListViewModel: TapChipHorizontalListViewModel = .init(dataSource: [], headerType: .GoPayListHeader), tapCardPhoneListViewModel: TapCardPhoneBarListViewModel = .init(), tapCardTelecomPaymentViewModel: TapCardTelecomPaymentViewModel = .init(), tapCurrienciesChipHorizontalListViewModel: TapChipHorizontalListViewModel = .init(), goPayBarViewModel: TapGoPayLoginBarViewModel? = nil, swipeDownToDismiss: Bool = false, currenciesChipsViewModel: [CurrencyChipViewModel] = [], goPayLoginCountries: [TapCountry] = [], closeButtonStyle: CheckoutCloseButtonEnum = .title, showDragHandler: Bool = false, tapCardPhoneListDataSource: [CurrencyCardsTelecomModel] = [], gatewayChipsViewModel: [ChipWithCurrencyModel] = [], goPayChipsViewModel: [ChipWithCurrencyModel] = [], tapLoyaltyViewModel:TapLoyaltyViewModel, customerDataViewModel:CustomerContactDataCollectionViewModel, customerShippingViewModel:CustomerShippingDataCollectionViewModel) {
        
        self.tapMerchantViewModel = tapMerchantViewModel
        self.tapAmountSectionViewModel = tapAmountSectionViewModel
        self.tapItemsTableViewModel = tapItemsTableViewModel
        self.tapGatewayChipHorizontalListViewModel = tapGatewayChipHorizontalListViewModel
        self.tapGoPayChipsHorizontalListViewModel = tapGoPayChipsHorizontalListViewModel
        self.tapCardPhoneListViewModel = tapCardPhoneListViewModel
        self.tapCardTelecomPaymentViewModel = tapCardTelecomPaymentViewModel
        self.tapCurrienciesChipHorizontalListViewModel = tapCurrienciesChipHorizontalListViewModel
        self.goPayBarViewModel = goPayBarViewModel
        self.swipeDownToDismiss = swipeDownToDismiss
        self.currenciesChipsViewModel = currenciesChipsViewModel
        self.goPayLoginCountries = goPayLoginCountries
        self.closeButtonStyle = closeButtonStyle
        self.showDragHandler = showDragHandler
        self.tapCardPhoneListDataSource = tapCardPhoneListDataSource
        self.gatewayChipsViewModel = gatewayChipsViewModel
        self.goPayChipsViewModel = goPayChipsViewModel
        self.tapLoyaltyViewModel = tapLoyaltyViewModel
        self.customerDataViewModel = customerDataViewModel
        self.customerShippingViewModel = customerShippingViewModel
        
        assignViewModelsDelegates()
    }
    
    /// Rerpesents the view model that controls the Merchant header section view
    var tapMerchantViewModel:TapMerchantHeaderViewModel = .init()
    /// Rerpesents the view model that controls the Amount section view
    var tapAmountSectionViewModel:TapAmountSectionViewModel = .init()
    /// Rerpesents the view model that controls the items list view
    var tapItemsTableViewModel:TapGenericTableViewModel = .init()
    /// Represents the view model that controls the payment gateway chips list view
    var tapGatewayChipHorizontalListViewModel:TapChipHorizontalListViewModel = .init(dataSource: [], headerType: .GateWayListWithGoPayListHeader) {
        didSet{
            assignViewModelsDelegates()
        }
    }
    /// Represents the view model that controls the gopay gateway chips list view
    var tapGoPayChipsHorizontalListViewModel:TapChipHorizontalListViewModel = .init(dataSource: [], headerType: .GoPayListHeader) {
        didSet{
            assignViewModelsDelegates()
        }
    }
    /// Represents the view model that controls the cards/telecom tabs view
    var tapCardPhoneListViewModel:TapCardPhoneBarListViewModel = .init()
    /// Represents the view model that controls the tabbar view
    var tapCardTelecomPaymentViewModel: TapCardTelecomPaymentViewModel = .init()
    /// Represents the view model that controls the chips list of supported currencies view
    var tapCurrienciesChipHorizontalListViewModel:TapChipHorizontalListViewModel = .init() {
        didSet{
            assignViewModelsDelegates()
        }
    }
    /// Represents the view model that controls the country picker when logging in to goPay using the phone number
    var goPayBarViewModel:TapGoPayLoginBarViewModel?
    /// Represents the view model that controls the action button view
    let tapActionButtonViewModel: TapActionButtonViewModel = .init()
    /// If it is set then when the user swipes down the payment will close, otherwise, there will be a shown button to dismiss the screen. Default is false
    var swipeDownToDismiss:Bool = false
    /// Decides whether or not, the card input should collect the card holder name. Default is false
    var collectCreditCardName:Bool = false
    /// Decides whether or not, the card name field will be editable
    var creditCardNameEditable:Bool = true
    // Decides whether or not, the card name field should be prefilled
    var creditCardNamePreload:String = ""
    /// Defines if the card info textfields should support RTL in Arabic mode or not
    var shouldFlipCardInfo:Bool = true
    /// Indicates if the card form shall have its own background theming or it should be clear and reflect whatever is behind it
    var cardShouldThemeItself:Bool = false
    /// Decides whether or not, the card input should show save card option. Default is false
    var showSaveCreditCard:SaveCardType = .None
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
    /// Represents the view model controling the loyalty widget if any
    var tapLoyaltyViewModel:TapLoyaltyViewModel? = .init()
    /// Represents the view mdoel cotrolling collecting customer contact data
    var customerDataViewModel:CustomerContactDataCollectionViewModel?
    /// The view model that controls the customer shipping data collection view
    var customerShippingViewModel:CustomerShippingDataCollectionViewModel?
    /// Represents the current using currency, will send the conversion currency if any otherwise the original transation currency
    var currentUsedCurrency:TapCurrencyCode {
        if tapAmountSectionViewModel.convertedTransactionCurrency.currency == .undefined {
            return tapAmountSectionViewModel.originalTransactionCurrency.currency
        }else{
            return tapAmountSectionViewModel.convertedTransactionCurrency.currency
        }
    }
    
    init() {
        
    }
    
    /// Used to assign the view delegates to the correct delegate source
    internal func assignViewModelsDelegates() {
        tapCurrienciesChipHorizontalListViewModel.delegate  = TapCheckout.sharedCheckoutManager()
        tapGatewayChipHorizontalListViewModel.delegate      = TapCheckout.sharedCheckoutManager()
        tapGoPayChipsHorizontalListViewModel.delegate       = TapCheckout.sharedCheckoutManager()
        tapLoyaltyViewModel?.delegate                       = TapCheckout.sharedCheckoutManager()
        tapActionButtonViewModel.delegate                   = TapCheckout.sharedCheckoutManager()
    }
    
    /// Checks if the user asked for showing save card and it is allowed from the backend as well
    internal func isSaveCardAllowed() -> SaveCardType {
        guard TapCheckout.sharedCheckoutManager().dataHolder.transactionData.saveCardSwitchType != .none else{
            return .None
        }
        return showSaveCreditCard
    }
    
    /// Then let us update the enabled/disabled status for the chips. Will mark the isEnabld and isDisabled flags for the payment options based on the given currency
    /// - Parameter for currency: The currency code you want to set the enable status based on. If not passed, we will use the selected currency for the singleton checkout
    internal func updatePaymentChipsEnableStatus(for currency:TapCurrencyCode? = nil) {
        // Fetch the correct currency
        let nonNullCurrencyCode = currency ?? TapCheckout.sharedCheckoutManager().dataHolder.transactionData.transactionUserCurrencyValue.currency
        // Now let us mark the flag for each payment option based on the supporting status of the computed currency
        TapCheckout.sharedCheckoutManager().dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.dataSource.forEach { $0.isDisabled = !(TapCheckout.sharedCheckoutManager().dataHolder.transactionData.paymentOptionsModelResponse?.fetchPaymentOption(with: $0.paymentOptionIdentifier)?.supportedCurrencies.contains(obj:nonNullCurrencyCode) ?? false) }
        
        print("SD")
    }
}

/// Struct that holds transaction related variables
internal class TransactionDataHolder {
    
    internal init(dataHolderDelegate: TapCheckoutDataHolderDelegate? = nil, intitModelResponse: TapInitResponseModel? = nil, paymentOptionsModelResponse: TapPaymentOptionsReponseModel? = nil, sdkMode: SDKMode = .sandbox, paymentType: TapPaymentType = .All, applePayMerchantID: String = "", loggedInToGoPay: Bool = false, transactionMode: TransactionMode = .purchase, customer: TapCustomer = TapCustomer.defaultCustomer(), destinations: [Destination]? = nil, tapMerchantID: String? = nil, taxes: [Tax]? = nil, shipping: Shipping? = nil, allowedCardTypes: [CardType] = [CardType(cardType: .Debit), CardType(cardType: .Credit)], postURL: URL? = nil, paymentDescription: String? = nil, paymentMetadata: TapMetadata = [:], paymentReference: Reference? = nil, paymentStatementDescriptor: String? = nil, require3DSecure: Bool = true, receiptSettings: Receipt? = nil, authorizeAction: AuthorizeAction = AuthorizeAction.default, allowsToSaveSameCardMoreThanOnce: Bool = true, enableSaveCard: Bool = true, isSaveCardSwitchOnByDefault: Bool = true, transactionCurrencyValue: AmountedCurrency = .init(.undefined, 0, ""), transactionUserCurrencyValue: AmountedCurrency = .init(.undefined, 0, ""), transactionItemsValue: [ItemModel] = [], selectedPaymentOption: PaymentOption? = nil, enableApiLogging:[TapLoggingType] = [.CONSOLE]) {
        
        self.dataHolderDelegate = dataHolderDelegate
        self.intitModelResponse = intitModelResponse
        self.paymentOptionsModelResponse = paymentOptionsModelResponse
        self.sdkMode = sdkMode
        self.paymentType = paymentType
        self.applePayMerchantID = applePayMerchantID
        self.loggedInToGoPay = loggedInToGoPay
        self.transactionMode = transactionMode
        self.customer = customer
        self.destinations = destinations
        self.tapMerchantID = tapMerchantID
        self.taxes = taxes
        self.shipping = shipping
        self.allowedCardTypes = allowedCardTypes
        self.postURL = postURL
        self.paymentDescription = paymentDescription
        self.paymentMetadata = paymentMetadata
        self.paymentReference = paymentReference
        self.paymentStatementDescriptor = paymentStatementDescriptor
        self.require3DSecure = require3DSecure
        self.receiptSettings = receiptSettings
        self.authorizeAction = authorizeAction
        self.allowsToSaveSameCardMoreThanOnce = allowsToSaveSameCardMoreThanOnce
        self.enableSaveCard = enableSaveCard
        self.isSaveCardSwitchOnByDefault = isSaveCardSwitchOnByDefault
        self.transactionCurrencyValue = transactionCurrencyValue
        self.transactionUserCurrencyValue = transactionUserCurrencyValue
        self.transactionItemsValue = transactionItemsValue
        self.selectedPaymentOption = selectedPaymentOption
        self.enableApiLogging = enableApiLogging
    }
    
    /// Protocol to instruct parent upon important data changes to act upon
    var dataHolderDelegate:TapCheckoutDataHolderDelegate?
    
    // MARK:- API Responses Variables
    
    
    
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
    
    /// Represents the last card data loaded from the Bin Lookup api
    var binLookUpModelResponse:TapBinResponseModel?{
        didSet{
            // Now it is time to fetch needed data from the model parsed
            if oldValue != binLookUpModelResponse {
                dataHolderDelegate?.parseTapBinResponse()
            }
        }
    }
    
    
    /// The allowed logging types
    var enableApiLogging:[TapLoggingType] = [.CONSOLE]
    
    // MARK:- Transaction Configuration Variables
    
    /// Defines the mode sandbox or production the sdk will perform this transaction on. Please check [SDKMode](x-source-tag://SDKMode)
    var sdkMode:SDKMode = .sandbox{
        didSet{
            // Save the sdk mode for further access
            SharedCommongDataModels.sharedCommongDataModels.sdkMode = sdkMode
        }
    }
    
    /// Represents The allowed payment types inclyding cards, apple pay, web and telecom
    var paymentType:TapPaymentType = .All
    
    /// Represnts the transaction reference model
    var reference:Reference?
    
    /// Represents the wallet topup object
    var topup:Topup?
    
    /// Represents The Apple pay merchant id to be used inside the apple pay kit
    var applePayMerchantID:String = ""
    /// Represents if the current customer is logged in to goPay
    var loggedInToGoPay:Bool = false {
        didSet{
            //dataHolderDelegate?.updateGatewayChipsList()
        }
    }
    /// Which transaction mode will be used in this call. Purchase, Authorization, Card Saving and Toknization. Please check [TransactionMode](x-source-tag://TransactionModeEnum)
    var transactionMode:TransactionMode = .purchase
    
    /// Decides which customer is performing this transaction. It will help you as a merchant to define the payer afterwards. Please check [TapCustomer](x-source-tag://TapCustomer)
    var customer:TapCustomer = TapCustomer.defaultCustomer()
    
    /// Decides which destination(s) this transaction's amount should split to. Please check [Destination](x-source-tag://Destination)
    var destinations: [Destination]?
    
    /// Decides which currency(s) this transaction can be paid with.
    var supportedCurrencies: [TapCurrencyCode]?
    
    /// Merchant ID. Optional. Useful when you have multiple Tap accounts and would like to do the `switch` on the fly within the single app.
    var tapMerchantID:String?
    
    /// Optional. List of Taxes you want to apply to the order if any.
    var taxes:[Tax]? = nil
    
    /// Optional. List of Shipping you want to apply to the order if any.
    var shipping:Shipping? = nil
    
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
    
    /// Defines the recurring payment request Please check [Apple Pay docs](https://developer.apple.com/documentation/passkit/pkrecurringpaymentrequest). NOTE: This will only be availble for iOS 16+ and subscripion parameter is on.
    var recurringPaymentRequest: Any? = nil
    
    //// Defines if you want to make a subscription based transaction. Default is false
    var isSubscription:Bool = false
    
    /// Defines the type of the apple pay button like Pay with or Subscripe with  etc. Default is Pay
    var applePayButtonType:TapApplePayButtonType = .AppleLogoOnly
    /// Defines the UI of the apple pay button white, black or outlined. Default is black
    var applePayButtonStyle:TapApplePayButtonStyleOutline = .Black
    
    /// Defines if the customer can save his card for upcoming payments
    /// Default is `true`.
    var enableSaveCard: Bool = true
    
    /// Defines if save card switch is on by default.
    /// - Note: If value of this property is `true`, then switch will be remaining off until card information is filled and valid.
    ///         And after will be toggled on automatically.
    var isSaveCardSwitchOnByDefault: Bool = true
    
    /// Represents the latest charge object from the api
    var currentCharge:Charge?
    
    /// Represents the latest charge object from the api
    var currentAuthorize:Authorize?
    
    /// Represents the latest token object from the api
    var currentToken:Token?
    
    /// Represents the latest
    var currentCard:TapCard? {
        didSet{
            TapCheckout.sharedCheckoutManager().handleCardData(with: currentCard)
        }
    }
    
    /// Represents the card prefix we are currently executing a binlook up for, used to prevent multiple calls if the user quickly typed the card number
    var currentlyRequestingBinFor:String?
    
    // MARK:- RxSwift Variables
    
    /// Represents the original transaction currency stated by the merchant on checkout start
    var transactionCurrencyValue:AmountedCurrency = .init(.undefined, 0, "") {
        didSet{
            if  oldValue != transactionCurrencyValue ||
                oldValue.displaybaleSymbol != transactionCurrencyValue.displaybaleSymbol {
                
                if transactionCurrencyValue.currency != .undefined {
                    // Listen to the changes in transaction currency
                    dataHolderDelegate?.transactionCurrencyUpdated()
                }
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
    var selectedPaymentOption:PaymentOption? {
        didSet{
            TapCheckout.sharedCheckoutManager().postChangingPaymentOptionLogic()
        }
    }
    
    /// Decides which save card option to be shown whether merchant, goPay, both or none
    var saveCardSwitchType:TapSwitchEnum {
        // Check if the mrtchant allowed it first
        guard enableSaveCard else { return .none }
        
        // Then check if its allowed permission wise from the backend
        guard let permissions = intitModelResponse?.data.permissions,
              permissions.contains(.merchantCheckout) else { return .none }
        
        // Then we need to check if the user is loggedInToGoPay
        guard loggedInToGoPay else { return .merchant }
        return .all
    }
    
    /// Determines whether the user opt out for saving the card into the merchant's system
    var isSaveCardMerchantActivated:Bool {
        // First check that the save card is enabled
        let saveCardType:SaveCardType = TapCheckout.sharedCheckoutManager().dataHolder.viewModels.isSaveCardAllowed()
        guard (saveCardType == .Merchant || saveCardType == .All)
        else { return false }
        
        // Then check if the user opt to save the card
        return TapCheckout.sharedCheckoutManager().dataHolder.viewModels.tapCardTelecomPaymentViewModel.isMerchantSaveAllowed
    }
    
    
    /// Determines whether the user opt out for saving the card into the GoPay's system
    var isSaveCardGoPayActivated:Bool {
        // First check that the save card is enabled
        let saveCardType:SaveCardType = TapCheckout.sharedCheckoutManager().dataHolder.viewModels.isSaveCardAllowed()
        
        guard (saveCardType == .Tap || saveCardType == .All)
        else { return false }
        
        // Then check if the user opt to save the card
        return TapCheckout.sharedCheckoutManager().dataHolder.viewModels.tapCardTelecomPaymentViewModel.isTapSaveAllowed
    }
    
}
