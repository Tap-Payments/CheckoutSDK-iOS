//
//  TapCheckout+UIHandling.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/20/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// Extension to handle logic to update ui view models based on data changes
internal extension TapCheckout {
    /// Handles the logic required to update all required fields and variables upon a change in the current shared data manager state
    func updateManager() {
        updateAmountSection()
        updateItemsList()
        updateGatewayChipsList()
        updateCardTelecomList()
        updateSaveCardSwitchStatus()
        updateApplePayRequest()
    }
    
    /// Handles the logic to determine the visibility and the status of the save card/ohone switch depending on the current card/telecom data source
    func updateSaveCardSwitchStatus() {
        dataHolder.viewModels.tapSaveCardSwitchViewModel.shouldShow = dataHolder.viewModels.tapCardTelecomPaymentViewModel.shouldShow
        if dataHolder.viewModels.tapSaveCardSwitchViewModel.shouldShow {
            dataHolder.viewModels.tapSaveCardSwitchViewModel.cardState = (dataHolder.viewModels.tapCardPhoneListViewModel.dataSource[0].associatedCardBrand.brandSegmentIdentifier == "cards") ? .invalidCard : .invalidTelecom
        }
    }
    
    /// Handles all the logic needed when the amount or the user selected currency changed to reflect in the Amount Section View
    func updateAmountSection() {
        // Apply the changes of user currency and total amount into the Amount view model
        dataHolder.viewModels.tapAmountSectionViewModel.convertedTransactionCurrency = dataHolder.transactionData.transactionUserCurrencyValue
        dataHolder.viewModels.tapAmountSectionViewModel.originalTransactionCurrency  = dataHolder.transactionData.transactionCurrencyValue
    }
    
    /// Handles all the logic needed when the user selected currency changed to reflect in the items list view
    func updateItemsList() {
        dataHolder.viewModels.tapItemsTableViewModel.dataSource.map{ $0 as! ItemCellViewModel }.forEach{ $0.convertCurrency = dataHolder.transactionData.transactionUserCurrencyValue }
    }
    
    /// Handles if goPay should be shown if the user is logged in, determine the header of the both gateways cards and goPay cards based on the visibility ot the goPay cards
    func updateGoPayAndGatewayLists() {
        // Check if the user is logged in before or not
        dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.shouldShow = dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.shouldShow && dataHolder.transactionData.loggedInToGoPay
        // Adjust the header of the tapGatewayChipList
        dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.headerType = dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.shouldShow ? .GateWayListWithGoPayListHeader : .GatewayListHeader
    }
    
    /// Handles all the logic needed when the user selected currency changed to reflect in the supported cards/telecom tabbar items for the new currency
    func updateCardTelecomList() {
        dataHolder.viewModels.tapCardPhoneListViewModel.dataSource = dataHolder.viewModels.tapCardPhoneListDataSource.filter(for: dataHolder.transactionData.transactionUserCurrencyValue.currency)
        
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.tapCardPhoneListViewModel = dataHolder.viewModels.tapCardPhoneListViewModel
        
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.changeTapCountry(to: dataHolder.viewModels.tapCardPhoneListDataSource.telecomCountry(for: dataHolder.transactionData.transactionUserCurrencyValue.currency))
    }
    
    /// Handles all the logic needed to correctly parse the passed data into a correct Apple Pay request format
    func updateApplePayRequest() {
        // get the apple pay chip view modl
        let applePayChips = dataHolder.viewModels.gatewayChipsViewModel.filter{ $0.tapChipViewModel.isKind(of: ApplePayChipViewCellModel.self) }
        guard applePayChips.count > 0, let applePayChipViewModel:ApplePayChipViewCellModel = applePayChips[0].tapChipViewModel as? ApplePayChipViewCellModel else { // meaning no apple pay chip is there
            return }
        
        applePayChipViewModel.configureApplePayRequest(currencyCode: dataHolder.transactionData.transactionUserCurrencyValue.currency,paymentItems: dataHolder.transactionData.transactionItemsValue.toApplePayItems(convertFromCurrency: dataHolder.transactionData.transactionCurrencyValue, convertToCurrenct: dataHolder.transactionData.transactionUserCurrencyValue), amount: dataHolder.transactionData.transactionUserCurrencyValue.currency.convert(from: dataHolder.transactionData.transactionCurrencyValue.currency, for: dataHolder.transactionData.transactionTotalAmountValue), merchantID: dataHolder.transactionData.applePayMerchantID)
        
    }
    
    
    /// We need to highlight the default currency of the user didn't select a new currency other than the default currency
    func highlightDefaultCurrency() {
        
        //guard transactionUserCurrencyValue == transactionCurrencyValue else { return }
        DispatchQueue.main.async { [weak self] in
            let selectedIndex:Int = self?.dataHolder.viewModels.tapCurrienciesChipHorizontalListViewModel.dataSource.map({ (genericTapChipViewModel) -> AmountedCurrency in
                guard let currencyChipModel:CurrencyChipViewModel = genericTapChipViewModel as? CurrencyChipViewModel else { return .init(.KWD, 0, "") }
                return currencyChipModel.currency
            }).firstIndex(of: self!.dataHolder.transactionData.transactionUserCurrencyValue) ?? 0
            
            self?.dataHolder.viewModels.tapCurrienciesChipHorizontalListViewModel.didSelectItem(at: selectedIndex,selectCell: true)
        }
    }
}


extension TapCheckout:TapCheckoutDataHolderDelegate {
    
    func updateGatewayChipsList() {
        dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.deselectAll()
        dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.deselectAll()
        
        dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.dataSource = dataHolder.viewModels.gatewayChipsViewModel.filter(for: dataHolder.transactionData.transactionUserCurrencyValue.currency)
        dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.dataSource = dataHolder.viewModels.goPayChipsViewModel.filter(for: dataHolder.transactionData.transactionUserCurrencyValue.currency)
        updateGoPayAndGatewayLists()
    }
    
    /// Handles the logic to fetch different sections from the Init API response
    func parseInitResponse() {
        // Double check..
        guard let initModel = dataHolder.transactionData.intitModelResponse else { return }
        
        // Fetch the merchant header info
        dataHolder.viewModels.tapMerchantViewModel = .init(title: nil, subTitle: initModel.data.merchant?.name, iconURL: initModel.data.merchant?.logoURL)
        
    }
    
    /// Handles the logic to fetch different sections from the Payment options response
    func parsePaymentOptionsResponse() {
        
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
    
    
    /// Handles the logic to perform parsing for the card data loaded from the bin lookup api
    func parseTapBinResponse() {
        
    }
    
    
    /// Handles all the logic needed when the original transaction currency changed
    func transactionCurrencyUpdated() {
        // Change in the original transaction currency, means this is the basic configuration called from the merchanr on load, so we initialy set it to be the same as the selected user currency
        dataHolder.transactionData.transactionUserCurrencyValue = dataHolder.transactionData.transactionCurrencyValue
        
        // Apply the change into the Amount view model
        dataHolder.viewModels.tapAmountSectionViewModel.originalTransactionCurrency = dataHolder.transactionData.transactionCurrencyValue
    }
    
    
    /// The amount section and items list will be changed if total amount or the selected currency is changed one of them or both
    func handleChangeAmountAndCurrency() {
        guard dataHolder.transactionData.transactionTotalAmountValue != 0 && dataHolder.transactionData.transactionUserCurrencyValue.currency != .undefined else { return }
        updateManager()
    }
    
    /**
     Used to calclate the total price to be paid by the user, taking in consideration the items (each item with price. quantity, discounts, taxes) a transaction level shipping and taxes
     */
    func calculateFinalAmount() -> Double {
        let sharedManager = TapCheckout.sharedCheckoutManager()
        
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
    func createTapItemsViewModel() {
        // Convert the passed items models into the ItemCellViewModels and update the items table view model with the new created list
        let itemsModels:[ItemCellViewModel] = dataHolder.transactionData.transactionItemsValue.map{ ItemCellViewModel.init(itemModel: $0, originalCurrency:dataHolder.transactionData.transactionCurrencyValue) }
        dataHolder.viewModels.tapItemsTableViewModel = .init(dataSource: itemsModels)
        dataHolder.viewModels.tapAmountSectionViewModel.numberOfItems = dataHolder.transactionData.transactionItemsValue.count
    }
}

