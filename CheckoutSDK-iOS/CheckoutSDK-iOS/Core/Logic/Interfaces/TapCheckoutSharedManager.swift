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
    
    /**
     Will be fired once the tap sheet content changed its height
     - Parameter newHeight: The new height the content of the Tap sheet has
     */
    func show(alert:UIAlertController)
    
    /**
     Will be fired once we need to ake the button starts/end loading
     - Parameter shouldLoad: True to start loading and false otherwise
     - Parameter success: Will be used in the case of ending loading with the success status
     - Parameter onComplete: Logic block to execute after stopping loading
     */
    func actionButton(shouldLoad:Bool,success:Bool,onComplete:@escaping()->())
    
    /**
     Will be fired once the checkout process faild and we need to dismiss
     - Parameter with error:  The error cause the checkout process to fail
     */
    func dismissCheckout(with error:Error)
    
}

/// Represents a global accessable common data gathered by the merchant when loading the checkout sdk like amount, currency, etc
internal class TapCheckoutSharedManager {
    
    /// A protocol to comminicate between the UIManager and the data manager
    var UIDelegate:TapCheckoutSharedManagerUIDelegate?
    /// Represents a global accessable common data gathered by the merchant when loading the checkout sdk like amount, currency, etc
    private static var privateShared : TapCheckoutSharedManager?
    
    // MARK:- View Models Variables
    var dataHolder:DataHolder = .init(viewModels: ViewModelsHolder.init(), transactionData: .init())
    
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
    
    /// Resetting all view models to the initial state
    private func resetViewModels() {
        dataHolder.viewModels = .init()
    }
    
    /// Resetting and disposing all previous subscribers to the observables
    private func resetObservables() {
        dataHolder.transactionData.transactionCurrencyValue = .init(.undefined, 0, "")
        dataHolder.transactionData.transactionUserCurrencyValue = .init(.undefined, 0, "")
        dataHolder.transactionData.transactionItemsValue = []
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
    
    /// Handles the logic to determine the visibility and the status of the save card/ohone switch depending on the current card/telecom data source
    private func updateSaveCardSwitchStatus() {
        dataHolder.viewModels.tapSaveCardSwitchViewModel.shouldShow = dataHolder.viewModels.tapCardTelecomPaymentViewModel.shouldShow
        if dataHolder.viewModels.tapSaveCardSwitchViewModel.shouldShow {
            dataHolder.viewModels.tapSaveCardSwitchViewModel.cardState = (dataHolder.viewModels.tapCardPhoneListViewModel.dataSource[0].associatedCardBrand.brandSegmentIdentifier == "cards") ? .invalidCard : .invalidTelecom
        }
    }
    
    /// Handles all the logic needed when the amount or the user selected currency changed to reflect in the Amount Section View
    private func updateAmountSection() {
        // Apply the changes of user currency and total amount into the Amount view model
        dataHolder.viewModels.tapAmountSectionViewModel.convertedTransactionCurrency = dataHolder.transactionData.transactionUserCurrencyValue
        dataHolder.viewModels.tapAmountSectionViewModel.originalTransactionCurrency  = dataHolder.transactionData.transactionCurrencyValue
    }
    
    /// Handles all the logic needed when the user selected currency changed to reflect in the items list view
    private func updateItemsList() {
        dataHolder.viewModels.tapItemsTableViewModel.dataSource.map{ $0 as! ItemCellViewModel }.forEach{ $0.convertCurrency = dataHolder.transactionData.transactionUserCurrencyValue }
    }
    
    /// Handles if goPay should be shown if the user is logged in, determine the header of the both gateways cards and goPay cards based on the visibility ot the goPay cards
    private func updateGoPayAndGatewayLists() {
        // Check if the user is logged in before or not
        dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.shouldShow = dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.shouldShow && dataHolder.transactionData.loggedInToGoPay
        // Adjust the header of the tapGatewayChipList
        dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.headerType = dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.shouldShow ? .GateWayListWithGoPayListHeader : .GatewayListHeader
    }
    
    /// Handles all the logic needed when the user selected currency changed to reflect in the supported cards/telecom tabbar items for the new currency
    private func updateCardTelecomList() {
        dataHolder.viewModels.tapCardPhoneListViewModel.dataSource = dataHolder.viewModels.tapCardPhoneListDataSource.filter(for: dataHolder.transactionData.transactionUserCurrencyValue.currency)
        
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.tapCardPhoneListViewModel = dataHolder.viewModels.tapCardPhoneListViewModel
        
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.changeTapCountry(to: dataHolder.viewModels.tapCardPhoneListDataSource.telecomCountry(for: dataHolder.transactionData.transactionUserCurrencyValue.currency))
    }
    
    /// Handles all the logic needed to correctly parse the passed data into a correct Apple Pay request format
    private func updateApplePayRequest() {
        // get the apple pay chip view modl
        let applePayChips = dataHolder.viewModels.gatewayChipsViewModel.filter{ $0.tapChipViewModel.isKind(of: ApplePayChipViewCellModel.self) }
        guard applePayChips.count > 0, let applePayChipViewModel:ApplePayChipViewCellModel = applePayChips[0].tapChipViewModel as? ApplePayChipViewCellModel else { // meaning no apple pay chip is there
            return }
        
        applePayChipViewModel.configureApplePayRequest(currencyCode: dataHolder.transactionData.transactionUserCurrencyValue.currency,paymentItems: dataHolder.transactionData.transactionItemsValue.toApplePayItems(convertFromCurrency: dataHolder.transactionData.transactionCurrencyValue, convertToCurrenct: dataHolder.transactionData.transactionUserCurrencyValue), amount: dataHolder.transactionData.transactionUserCurrencyValue.currency.convert(from: dataHolder.transactionData.transactionCurrencyValue.currency, for: dataHolder.transactionData.transactionTotalAmountValue), merchantID: dataHolder.transactionData.applePayMerchantID)
        
    }
    
    
    /// We need to highlight the default currency of the user didn't select a new currency other than the default currency
    internal func highlightDefaultCurrency() {
        
        //guard transactionUserCurrencyValue == transactionCurrencyValue else { return }
        DispatchQueue.main.async { [weak self] in
            let selectedIndex:Int = self?.dataHolder.viewModels.tapCurrienciesChipHorizontalListViewModel.dataSource.map({ (genericTapChipViewModel) -> AmountedCurrency in
                guard let currencyChipModel:CurrencyChipViewModel = genericTapChipViewModel as? CurrencyChipViewModel else { return .init(.KWD, 0, "") }
                return currencyChipModel.currency
            }).firstIndex(of: self!.dataHolder.transactionData.transactionUserCurrencyValue) ?? 0
            
            self?.dataHolder.viewModels.tapCurrienciesChipHorizontalListViewModel.didSelectItem(at: selectedIndex,selectCell: true)
        }
    }
    
    
    
    
    
    /// Handles the logic to fetch different sections from the Intent API response
    private func parseIntentResponse() {
        
        /*guard let intentModel = intentModelResponse else { return }
        
        // Fetch the merchant header info
        self.tapMerchantViewModel = .init(title: nil, subTitle: intentModel.merchant?.name, iconURL: intentModel.merchant?.logo)
        
        // Fetch the list of supported currencies
        self.dataHolder.viewModels.currenciesChipsViewModel = intentModel.currencies.map{ CurrencyChipViewModel.init(currency: $0) }
        self.dataHolder.viewModels.tapCurrienciesChipHorizontalListViewModel = .init(dataSource: dataHolder.viewModels.currenciesChipsViewModel, headerType: .NoHeader,selectedChip: dataHolder.viewModels.currenciesChipsViewModel.filter{ $0.currency == transactionUserCurrencyValue }[0])
        
        // Fetch the list of the goPay supported login countries
        self.dataHolder.viewModels.goPayLoginCountries = intentModel.dataHolder.viewModels.goPayLoginCountries ?? []
        self.dataHolder.viewModels.goPayBarViewModel = .init(countries: dataHolder.viewModels.goPayLoginCountries)
        
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
        dataHolder.viewModels.tapSaveCardSwitchViewModel = .init(with: .invalidCard, merchant: tapMerchantViewModel.subTitle ?? "")
        
        // Fetch the cards + telecom payments options
        self.tapCardPhoneListDataSource = (intentModel.tapCardPhoneListDataSource ?? []).filter{ paymentTypes.contains(.All) || paymentTypes.contains($0.paymentType) }
        
        // Load the goPayLogin status
        loggedInToGoPay = UserDefaults.standard.bool(forKey: TapCheckoutConstants.GoPayLoginUserDefaultsKey)*/
    }
    
    
}


extension TapCheckoutSharedManager:TapCheckoutDataHolderDelegate {
    
    internal func updateGatewayChipsList() {
        dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.deselectAll()
        dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.deselectAll()
        
        dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.dataSource = dataHolder.viewModels.gatewayChipsViewModel.filter(for: dataHolder.transactionData.transactionUserCurrencyValue.currency)
        dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.dataSource = dataHolder.viewModels.goPayChipsViewModel.filter(for: dataHolder.transactionData.transactionUserCurrencyValue.currency)
        updateGoPayAndGatewayLists()
    }
    
    /// Handles the logic to fetch different sections from the Init API response
    internal func parseInitResponse() {
        // Double check..
        guard let initModel = dataHolder.transactionData.intitModelResponse else { return }
        
        // Fetch the merchant header info
        dataHolder.viewModels.tapMerchantViewModel = .init(title: nil, subTitle: initModel.data.merchant?.name, iconURL: initModel.data.merchant?.logoURL)
        
    }
    
    /// Handles the logic to fetch different sections from the Payment options response
    internal func parsePaymentOptionsResponse() {
        
        guard let paymentOptions = dataHolder.transactionData.paymentOptionsModelResponse else { return }
        
        // Fetch the list of supported currencies
        self.dataHolder.viewModels.currenciesChipsViewModel = paymentOptions.supportedCurrenciesAmounts.map{ CurrencyChipViewModel.init(currency: $0) }
        self.dataHolder.viewModels.tapCurrienciesChipHorizontalListViewModel = .init(dataSource: dataHolder.viewModels.currenciesChipsViewModel, headerType: .NoHeader,selectedChip: dataHolder.viewModels.currenciesChipsViewModel.filter{ $0.currency == dataHolder.transactionData.transactionUserCurrencyValue }[0])
        
        // Fetch the list of the goPay supported login countries
        self.dataHolder.viewModels.goPayLoginCountries = [.init(nameAR: "مصر", nameEN: "Egypt", code: "20", phoneLength: 10)]//paymentOptions.dataHolder.viewModels.goPayLoginCountries ?? []
        self.dataHolder.viewModels.goPayBarViewModel = .init(countries: dataHolder.viewModels.goPayLoginCountries)
        
        // Fetch the list of goPay Saved Cards
        // First check if cards are allowed
        self.dataHolder.viewModels.goPayChipsViewModel = []
        
        // Fetch the merchant payment gateways
        self.dataHolder.viewModels.gatewayChipsViewModel = paymentOptions.paymentOptions.filter{ (dataHolder.transactionData.paymentType == .All || dataHolder.transactionData.paymentType == $0.paymentType || $0.paymentType == .All) && $0.paymentType != .Card }.map{ ChipWithCurrencyModel.init(paymentOption: $0) }
        
        // Fetch the merchant saved card if cards are allowed
        if dataHolder.transactionData.paymentType == .All || dataHolder.transactionData.paymentType == .Card {
            self.dataHolder.viewModels.gatewayChipsViewModel.append(contentsOf: (paymentOptions.savedCards ?? []).filter{ dataHolder.transactionData.allowedCardTypes.contains($0.cardType ?? .init(cardType: .All)) }.map{ ChipWithCurrencyModel.init(savedCard: $0) })
        }
        
        // Fetch the save card/phone switch data
        dataHolder.viewModels.tapSaveCardSwitchViewModel = .init(with: .invalidCard, merchant: dataHolder.viewModels.tapMerchantViewModel.subTitle ?? "")
        
        // Fetch the cards + telecom payments options
        self.dataHolder.viewModels.tapCardPhoneListDataSource = paymentOptions.paymentOptions.filter{ (dataHolder.transactionData.paymentType == .Card || dataHolder.transactionData.paymentType == .All) && $0.paymentType == .Card }.map{ CurrencyCardsTelecomModel.init(paymentOption: $0) }
        
        // Load the goPayLogin status
        dataHolder.transactionData.loggedInToGoPay = false//UserDefaults.standard.bool(forKey: TapCheckoutConstants.GoPayLoginUserDefaultsKey)
        updateManager()
    }
    
    
    /// Handles all the logic needed when the original transaction currency changed
    internal func transactionCurrencyUpdated() {
        // Change in the original transaction currency, means this is the basic configuration called from the merchanr on load, so we initialy set it to be the same as the selected user currency
        dataHolder.transactionData.transactionUserCurrencyValue = dataHolder.transactionData.transactionCurrencyValue
        
        // Apply the change into the Amount view model
        dataHolder.viewModels.tapAmountSectionViewModel.originalTransactionCurrency = dataHolder.transactionData.transactionCurrencyValue
    }
    
    
    /// The amount section and items list will be changed if total amount or the selected currency is changed one of them or both
    internal func handleChangeAmountAndCurrency() {
        guard dataHolder.transactionData.transactionTotalAmountValue != 0 && dataHolder.transactionData.transactionUserCurrencyValue.currency != .undefined else { return }
        updateManager()
    }
    
    /**
     Used to calclate the total price to be paid by the user, taking in consideration the items (each item with price. quantity, discounts, taxes) a transaction level shipping and taxes
     */
    func calculateFinalAmount() -> Double {
        let sharedManager = TapCheckoutSharedManager.sharedCheckoutManager()
        
        let items:[ItemModel] = sharedManager.dataHolder.transactionData.transactionItemsValue
        let transactionShipping:[Shipping] = sharedManager.dataHolder.transactionData.shipping
        let transactionTaxes:[Tax] = sharedManager.dataHolder.transactionData.taxes ?? []
        
        // First calculate the plain total amount from the items inclyding for each item X : (X's price * Quantity) - X's Discounty + X's Shipping + X's Taxes
        let totalItemsPrices:Double =   items.totalItemsPrices(convertFromCurrency: dataHolder.transactionData.transactionCurrencyValue, convertToCurrenct: dataHolder.transactionData.transactionUserCurrencyValue)
        // Second calculate the total shipping fees for the transaction level
        let shippingFees:Double     =   Double(truncating: transactionShipping.reduce(0.0, { $0 + $1.amount }) as NSNumber)
        // Third calculate the total Taxes fees for the transaction level
        let taxesFees = transactionTaxes.reduce(0) { $0 + $1.amount.caluclateActualModificationValue(with: totalItemsPrices+shippingFees) }
        // Now we can get the final amount
        let result = totalItemsPrices + shippingFees + taxesFees
        return result
    }
    
    
    /// Handles the logic needed to create the tap items view model by utilising the original currency and the items list passed by the merchant
    internal func createTapItemsViewModel() {
        // Convert the passed items models into the ItemCellViewModels and update the items table view model with the new created list
        let itemsModels:[ItemCellViewModel] = dataHolder.transactionData.transactionItemsValue.map{ ItemCellViewModel.init(itemModel: $0, originalCurrency:dataHolder.transactionData.transactionCurrencyValue) }
        dataHolder.viewModels.tapItemsTableViewModel = .init(dataSource: itemsModels)
        dataHolder.viewModels.tapAmountSectionViewModel.numberOfItems = dataHolder.transactionData.transactionItemsValue.count
    }
}
