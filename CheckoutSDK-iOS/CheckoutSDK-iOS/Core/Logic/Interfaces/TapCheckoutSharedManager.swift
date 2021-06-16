//
//  TapCheckout+SheetDataSource.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/16/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
import CommonDataModelsKit_iOS
import TapUIKit_iOS
/// A protocol to comminicate between the UIManager and the data manager
internal protocol TapCheckoutSharedManagerUIDelegate {
    /**
     Inform the delegate to remove a certain view from the checkout sheet
     - Parameter view: The view required by the data manager to be removed from the checkout sheet
     */
    func removeView(view:UIView)
    /**
     Inform the delegate to end the loading status of the goPay login
     - Parameter status: If set, means the user has provided correct credentials and is logged in to goPay. Otherwise, he provided wrong ones
     */
    func goPaySignIn(status:Bool)
    
}

/// Represents a global accessable common data gathered by the merchant when loading the checkout sdk like amount, currency, etc
internal class TapCheckoutSharedManager {
    
    
    /// A protocol to comminicate between the UIManager and the data manager
    var UIDelegate:TapCheckoutSharedManagerUIDelegate?
    /// Represents a global accessable common data gathered by the merchant when loading the checkout sdk like amount, currency, etc
    private static var privateShared : TapCheckoutSharedManager?
    
    // MARK:- View Models Variables
    
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
    /// Represents the data loaded from the Init api on checkout start
    var intitModelResponse:TapInitResponseModel?{
        didSet{
            // Now it is time to fetch needed data from the model parsed
            parseInitResponse()
        }
    }
    /// Represents the data loaded from the Init api on checkout start
    var paymentOptionsModelResponse:TapPaymentOptionsReponseModel?{
        didSet{
            // Now it is time to fetch needed data from the model parsed
            parsePaymentOptionsResponse()
        }
    }
    /// Represents the data loaded from the Intent api on checkout start
    var intentModelResponse:TapIntentResponseModel?{
        didSet{
            // Now it is time to fetch needed data from the model parsed
            parseIntentResponse()
        }
    }
    
    // MARK:- UI Related Variables
    
    /// Represents the required style of the sheet close button
    var closeButtonStyle:CheckoutCloseButtonEnum = .title
    
    /// Represents the drag handler to be shown or not
    var showDragHandler:Bool = false
    
    
    // MARK:- Transaction Configuration Variables
    
    /// Defines the mode sandbox or production the sdk will perform this transaction on. Please check [SDKMode](x-source-tag://SDKMode)
    var sdkMode:SDKMode = .sandbox
    
    /// Represents The allowed payment types inclyding cards, apple pay, web and telecom
    var paymentType:TapPaymentType = .All
    
    /// Represents the list of ALL allowed telecom/cards payments for the logged in merchant
    var tapCardPhoneListDataSource:[CurrencyCardsTelecomModel] = []
    /// Represents the list of ALL allowed payment chips for the logged in merchant
    var gatewayChipsViewModel:[ChipWithCurrencyModel] = []
    /// Represents the list of ALL allowed goPay chips for the logged in customer
    var goPayChipsViewModel:[ChipWithCurrencyModel] = []
    /// Represents The Apple pay merchant id to be used inside the apple pay kit
    var applePayMerchantID:String = ""
    /// Represents if the current customer is logged in to goPay
    var loggedInToGoPay:Bool = false {
        didSet{
            updateGatewayChipsList()
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
    /// Represents an observer function to perform when setting the original transaction currency stated by the merchant on checkout start
    var transactionCurrencyObserver:(TapCurrencyCode)->() = { _ in } {
        didSet{
            transactionCurrencyObserver(transactionCurrencyValue)
        }
    }
    /// Represents the original transaction currency stated by the merchant on checkout start
    var transactionCurrencyValue:TapCurrencyCode = .undefined {
        didSet{
            guard oldValue != transactionCurrencyValue else { return }
            transactionCurrencyObserver(transactionCurrencyValue)
            if transactionCurrencyValue != .undefined {
                // Listen to the changes in transaction currency
                self.transactionCurrencyUpdated()
            }
        }
    }
    /// Represents an observer function to perform when setting the transaction currency selected by the user
    var transactionUserCurrencyObserver:(TapCurrencyCode)->() = { _ in } {
        didSet{
            transactionUserCurrencyObserver(transactionCurrencyValue)
        }
    }
    /// Represents the transaction currency selected by the user
    var transactionUserCurrencyValue:TapCurrencyCode = .undefined {
        didSet{
            guard oldValue != transactionUserCurrencyValue else { return }
            transactionUserCurrencyObserver(transactionCurrencyValue)
            handleChangeAmountAndCurrency()
        }
    }
    /// Represents the original transaction total amount stated by the merchant on checkout start
    var transactionTotalAmountObserver:(Double)->() = { _ in } {
        didSet{
            transactionTotalAmountObserver(transactionTotalAmountValue)
        }
    }
    /// Represents the original transaction total amount stated by the merchant on checkout start
    var transactionTotalAmountValue:Double {
        return calculateFinalAmount()
    }
    /// Represents the list of items passed by the merchant on load
    var transactionItemsObserver:([ItemModel])->() = { _ in } {
        didSet{
            transactionItemsObserver(transactionItemsValue)
        }
    }
    /// Represents the list of items passed by the merchant on load
    var transactionItemsValue:[ItemModel] = [] {
        didSet{
            transactionItemsObserver(transactionItemsValue)
            // We only create items list when we have both elements, items and original currency
            if transactionItemsValue != [] {
                createTapItemsViewModel()
            }
        }
    }
    
    
    // MARK:- Methods
    /**
     Creates a shared instance of the CheckoutDataManager
     - Returns: The shared checkout manager
     */
    internal class func sharedCheckoutManager() -> TapCheckoutSharedManager { // change class to final to prevent override
        guard let uwShared = privateShared else {
            privateShared = TapCheckoutSharedManager()
            return privateShared!
        }
        return uwShared
    }
    
    /// Resets all the view models and dispose all the active observers
    internal class func destroy() {
        privateShared = nil
    }
    
    private init() {}
    
    deinit {}
    
    /**
     Used to calclate the total price to be paid by the user, taking in consideration the items (each item with price. quantity, discounts, taxes) a transaction level shipping and taxes
     */
    func calculateFinalAmount() -> Double {
        let sharedManager = TapCheckoutSharedManager.sharedCheckoutManager()
        
        let items:[ItemModel] = sharedManager.transactionItemsValue
        let transactionShipping:[Shipping] = sharedManager.shipping
        let transactionTaxes:[Tax] = sharedManager.taxes ?? []
        
        // First calculate the plain total amount from the items inclyding for each item X : (X's price * Quantity) - X's Discounty + X's Shipping + X's Taxes
        let totalItemsPrices:Double =   items.totalItemsPrices()
        // Second calculate the total shipping fees for the transaction level
        let shippingFees:Double     =   Double(truncating: transactionShipping.reduce(0.0, { $0 + $1.amount }) as NSNumber)
        // Third calculate the total Taxes fees for the transaction level
        let taxesFees = transactionTaxes.reduce(0) { $0 + $1.amount.caluclateActualModificationValue(with: totalItemsPrices+shippingFees) }
        // Now we can get the final amount
        let result = totalItemsPrices + shippingFees + taxesFees
        return result
    }
    
    /// Resetting all view models to the initial state
    private func resetViewModels() {
        tapMerchantViewModel = .init()
        tapAmountSectionViewModel = .init()
        tapItemsTableViewModel = .init()
    }
    
    /// Resetting and disposing all previous subscribers to the observables
    private func resetObservables() {
        transactionCurrencyValue = .undefined
        transactionUserCurrencyValue = .undefined
        transactionItemsValue = []
    }
    
    /// The amount section and items list will be changed if total amount or the selected currency is changed one of them or both
    private func handleChangeAmountAndCurrency() {
        guard transactionTotalAmountValue != 0 && transactionUserCurrencyValue != .undefined else { return }
        updateManager()
    }
    
    /// Handles the logic required to update all required fields and variables upon a change in the current shared data manager state
    private func updateManager() {
        updateAmountSection()
        updateItemsList()
        updateGatewayChipsList()
        updateCardTelecomList()
        updateSaveCardSwitchStatus()
        updateApplePayRequest()
    }
    
    /// Handles the logic needed to create the tap items view model by utilising the original currency and the items list passed by the merchant
    private func createTapItemsViewModel() {
        // Convert the passed items models into the ItemCellViewModels and update the items table view model with the new created list
        let itemsModels:[ItemCellViewModel] = transactionItemsValue.map{ ItemCellViewModel.init(itemModel: $0, originalCurrency:transactionCurrencyValue) }
        tapItemsTableViewModel = .init(dataSource: itemsModels)
        tapAmountSectionViewModel.numberOfItems = transactionItemsValue.count
    }
    
    /// Handles the logic to determine the visibility and the status of the save card/ohone switch depending on the current card/telecom data source
    private func updateSaveCardSwitchStatus() {
        tapSaveCardSwitchViewModel.shouldShow = tapCardTelecomPaymentViewModel.shouldShow
        if tapSaveCardSwitchViewModel.shouldShow {
            tapSaveCardSwitchViewModel.cardState = (tapCardPhoneListViewModel.dataSource[0].associatedCardBrand.brandSegmentIdentifier == "cards") ? .invalidCard : .invalidTelecom
        }
    }
    
    /// Handles all the logic needed when the original transaction currency changed
    private func transactionCurrencyUpdated() {
        // Change in the original transaction currency, means this is the basic configuration called from the merchanr on load, so we initialy set it to be the same as the selected user currency
        transactionUserCurrencyValue = transactionCurrencyValue
        
        // Apply the change into the Amount view model
        tapAmountSectionViewModel.originalTransactionCurrency = transactionCurrencyValue
    }
    
    /// Handles all the logic needed when the amount or the user selected currency changed to reflect in the Amount Section View
    private func updateAmountSection() {
        // Apply the changes of user currency and total amount into the Amount view model
        tapAmountSectionViewModel.convertedTransactionCurrency = transactionUserCurrencyValue
        tapAmountSectionViewModel.originalTransactionAmount = transactionTotalAmountValue
    }
    
    /// Handles all the logic needed when the user selected currency changed to reflect in the items list view
    private func updateItemsList() {
        tapItemsTableViewModel.dataSource.map{ $0 as! ItemCellViewModel }.forEach{ $0.convertCurrency = transactionUserCurrencyValue }
    }
    
    /// Handles all the logic needed when the user selected currency changed to reflect in the supported gateways chips for the new currency
    private func updateGatewayChipsList() {
        tapGatewayChipHorizontalListViewModel.deselectAll()
        tapGoPayChipsHorizontalListViewModel.deselectAll()
        
        tapGatewayChipHorizontalListViewModel.dataSource = gatewayChipsViewModel.filter(for: transactionUserCurrencyValue)
        tapGoPayChipsHorizontalListViewModel.dataSource = goPayChipsViewModel.filter(for: transactionUserCurrencyValue)
        updateGoPayAndGatewayLists()
    }
    
    /// Handles if goPay should be shown if the user is logged in, determine the header of the both gateways cards and goPay cards based on the visibility ot the goPay cards
    private func updateGoPayAndGatewayLists() {
        // Check if the user is logged in before or not
        tapGoPayChipsHorizontalListViewModel.shouldShow = tapGoPayChipsHorizontalListViewModel.shouldShow && loggedInToGoPay
        // Adjust the header of the tapGatewayChipList
        tapGatewayChipHorizontalListViewModel.headerType = tapGoPayChipsHorizontalListViewModel.shouldShow ? .GateWayListWithGoPayListHeader : .GatewayListHeader
    }
    
    /// Handles all the logic needed when the user selected currency changed to reflect in the supported cards/telecom tabbar items for the new currency
    private func updateCardTelecomList() {
        tapCardPhoneListViewModel.dataSource = tapCardPhoneListDataSource.filter(for: transactionUserCurrencyValue)
        tapCardTelecomPaymentViewModel.tapCardPhoneListViewModel = tapCardPhoneListViewModel
        tapCardTelecomPaymentViewModel.changeTapCountry(to: tapCardPhoneListDataSource.telecomCountry(for: transactionUserCurrencyValue))
    }
    
    /// Handles all the logic needed to correctly parse the passed data into a correct Apple Pay request format
    private func updateApplePayRequest() {
        // get the apple pay chip view modl
        let applePayChips = gatewayChipsViewModel.filter{ $0.tapChipViewModel.isKind(of: ApplePayChipViewCellModel.self) }
        guard applePayChips.count > 0, let applePayChipViewModel:ApplePayChipViewCellModel = applePayChips[0].tapChipViewModel as? ApplePayChipViewCellModel else { // meaning no apple pay chip is there
            return }
        
        applePayChipViewModel.configureApplePayRequest(currencyCode: transactionUserCurrencyValue,paymentItems: transactionItemsValue.toApplePayItems(convertFromCurrency: transactionCurrencyValue, convertToCurrenct: transactionUserCurrencyValue), amount: transactionUserCurrencyValue.convert(from: transactionCurrencyValue, for: transactionTotalAmountValue), merchantID: applePayMerchantID)
        
    }
    
    
    /// We need to highlight the default currency of the user didn't select a new currency other than the default currency
    internal func highlightDefaultCurrency() {
        
        //guard transactionUserCurrencyValue == transactionCurrencyValue else { return }
        DispatchQueue.main.async { [weak self] in
            let selectedIndex:Int = self?.tapCurrienciesChipHorizontalListViewModel.dataSource.map({ (genericTapChipViewModel) -> TapCurrencyCode in
                guard let currencyChipModel:CurrencyChipViewModel = genericTapChipViewModel as? CurrencyChipViewModel else { return .KWD }
                return currencyChipModel.currency
            }).firstIndex(of: self!.transactionUserCurrencyValue) ?? 0
            
            self?.tapCurrienciesChipHorizontalListViewModel.didSelectItem(at: selectedIndex,selectCell: true)
        }
    }
    
    
    /// Handles the logic to fetch different sections from the Init API response
    private func parseInitResponse() {
        // Double check..
        guard let initModel = intitModelResponse else { return }
        
        // Fetch the merchant header info
        self.tapMerchantViewModel = .init(title: nil, subTitle: initModel.data.merchant?.name, iconURL: initModel.data.merchant?.logoURL)
        
    }
    
    private func parsePaymentOptionsResponse() {
        
        guard let paymentOptions = paymentOptionsModelResponse else { return }
         
         // Fetch the list of supported currencies
        self.currenciesChipsViewModel = paymentOptions.supportedCurrenciesAmounts.map{ CurrencyChipViewModel.init(currency: $0.currency) }
         self.tapCurrienciesChipHorizontalListViewModel = .init(dataSource: currenciesChipsViewModel, headerType: .NoHeader,selectedChip: currenciesChipsViewModel.filter{ $0.currency == transactionUserCurrencyValue }[0])
         
         // Fetch the list of the goPay supported login countries
        self.goPayLoginCountries = [.init(nameAR: "مصر", nameEN: "Egypt", code: "20", phoneLength: 10)]//paymentOptions.goPayLoginCountries ?? []
         self.goPayBarViewModel = .init(countries: goPayLoginCountries)
         
         // Fetch the list of goPay Saved Cards
         // First check if cards are allowed
        if paymentType == .All || paymentType == .Card {
            self.goPayChipsViewModel =  []
            goPayChipsViewModel.append(.init(tapChipViewModel:TapLogoutChipViewModel()))
         }else{
            self.goPayChipsViewModel = []
         }
         
         // Fetch the merchant based saved cards + differnt payment types
        self.gatewayChipsViewModel = paymentOptions.paymentOptions.filter{ paymentType == .All || paymentType == $0.paymentType || $0.paymentType == .All }.map{ ChipWithCurrencyModel.init(paymentOption: $0) }
         
         // Fetch the save card/phone switch data
         tapSaveCardSwitchViewModel = .init(with: .invalidCard, merchant: tapMerchantViewModel.subTitle ?? "")
         
         // Fetch the cards + telecom payments options
         //self.tapCardPhoneListDataSource = (paymentOptions.tapCardPhoneListDataSource ?? []).filter{ paymentTypes.contains(.All) || paymentTypes.contains($0.paymentType) }
        self.tapCardPhoneListDataSource = []
         
         // Load the goPayLogin status
         loggedInToGoPay = false//UserDefaults.standard.bool(forKey: TapCheckoutConstants.GoPayLoginUserDefaultsKey)
    }
    
    
    /// Handles the logic to fetch different sections from the Intent API response
    private func parseIntentResponse() {
        
        /*guard let intentModel = intentModelResponse else { return }
        
        // Fetch the merchant header info
        self.tapMerchantViewModel = .init(title: nil, subTitle: intentModel.merchant?.name, iconURL: intentModel.merchant?.logo)
        
        // Fetch the list of supported currencies
        self.currenciesChipsViewModel = intentModel.currencies.map{ CurrencyChipViewModel.init(currency: $0) }
        self.tapCurrienciesChipHorizontalListViewModel = .init(dataSource: currenciesChipsViewModel, headerType: .NoHeader,selectedChip: currenciesChipsViewModel.filter{ $0.currency == transactionUserCurrencyValue }[0])
        
        // Fetch the list of the goPay supported login countries
        self.goPayLoginCountries = intentModel.goPayLoginCountries ?? []
        self.goPayBarViewModel = .init(countries: goPayLoginCountries)
        
        // Fetch the list of goPay Saved Cards
        // First check if cards are allowed
        if paymentTypes.contains(.All) || paymentTypes.contains(.Card) {
            self.goPayChipsViewModel = intentModel.goPaySavedCards ?? []
            goPayChipsViewModel.append(.init(tapChipViewModel:TapLogoutChipViewModel()))
        }else{
            self.goPayChipsViewModel = []
        }
        
        // Fetch the merchant based saved cards + differnt payment types
        self.gatewayChipsViewModel = (intentModel.paymentChips ?? []).filter{ paymentTypes.contains(.All) || paymentTypes.contains($0.paymentType) || $0.paymentType == .All }
        
        // Fetch the save card/phone switch data
        tapSaveCardSwitchViewModel = .init(with: .invalidCard, merchant: tapMerchantViewModel.subTitle ?? "")
        
        // Fetch the cards + telecom payments options
        self.tapCardPhoneListDataSource = (intentModel.tapCardPhoneListDataSource ?? []).filter{ paymentTypes.contains(.All) || paymentTypes.contains($0.paymentType) }
        
        // Load the goPayLogin status
        loggedInToGoPay = UserDefaults.standard.bool(forKey: TapCheckoutConstants.GoPayLoginUserDefaultsKey)*/
    }
    
    
}


extension TapCheckoutSharedManager {
    
}
