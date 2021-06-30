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


/// Represents a global accessable common data gathered by the merchant when loading the checkout sdk like amount, currency, etc
internal class TapCheckoutSharedManager {
    
    
    
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


