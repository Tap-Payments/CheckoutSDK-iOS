//
//  CurrencyChipModel.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/17/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation

/// Represents a model that will link the different chips models with their approved currencies
internal class CurrencyChipModel {
    
    /// Represents the chip view model itself (Apple, goPay & saved card)
    lazy var tapChipViewModel:GenericTapChipViewModel = .init()
    /// Represents the list of currencies the chip supports or should be visible when selected
    lazy var supportedCurrencies:[TapCurrencyCode] = []
    
    /**
     Creates a new instance that links the chip model with certain currencies
     - Parameter tapChipViewModel: Represents the chip view model itself (Apple, goPay & saved card)
     - Parameter supportedCurrencies: Represents the list of currencies the chip supports or should be visible when selected
     */
    init(tapChipViewModel:GenericTapChipViewModel, supportedCurrencies:[TapCurrencyCode] = []) {
        self.tapChipViewModel = tapChipViewModel
        self.supportedCurrencies = supportedCurrencies
    }
    
    /**
     Determines if the tap chip view model should be visible with a given currency
     - Parameter currency: The currency to deteremine if the chip view model supports or no
     - Returns: True if the list if currencies is empty (means it should be visible always.) or It has the given currency. Returns false otherwise
     */
    func enable(for currency:TapCurrencyCode) -> Bool {
        // Make sure the currency list has values with the given currenct or it supports every currency
        return (supportedCurrencies == []) || (supportedCurrencies.filter{ $0.appleRawValue == currency.appleRawValue } != [])
        
    }
}

internal extension Array where Element: CurrencyChipModel {
    /**
     Extended method to easily extract the list of GenericTapChipViewModel from list of CurrencyChipModel that supports a certain currenct
     - Parameter currency: Pass the currency you want to see its support. If no passed, the Global UserCurrency will be used as the filtering currency
     - Returns: List of the chip models that supports the given currency code
     */
    func filter(for currency:TapCurrencyCode? = nil) -> [GenericTapChipViewModel] {
        let filterForCurrency:TapCurrencyCode = currency ?? TapCheckoutSharedManager.sharedCheckoutManager().transactionUserCurrencyObserver.value
        return self.filter{ $0.enable(for: filterForCurrency) }.map{ $0.tapChipViewModel }
    }
}
