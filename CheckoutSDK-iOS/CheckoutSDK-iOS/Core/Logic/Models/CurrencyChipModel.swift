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
    /// Represents the the country the telecom operator works with
    var supportedCountry:TapCountry?
    
    /**
     Creates a new instance that links the chip model with certain currencies
     - Parameter tapChipViewModel: Represents the chip view model itself (Apple, goPay & saved card)
     - Parameter supportedCurrencies: Represents the list of currencies the chip supports or should be visible when selected
     - Parameter supportedCountry: Represents the the country the telecom operator works with
     */
    init(tapChipViewModel:GenericTapChipViewModel, supportedCurrencies:[TapCurrencyCode] = [],supportedCountry:TapCountry? = nil) {
        self.tapChipViewModel = tapChipViewModel
        self.supportedCurrencies = supportedCurrencies
        self.supportedCountry = supportedCountry
    }
    
    /**
     Determines if the tap chip view model should be visible with a given currency
     - Parameter currency: The currency to deteremine if the chip view model supports or no
     - Returns: True if the list if currencies is empty (means it should be visible always.) or It has the given currency. Returns false otherwise
     */
    func isEnabled(for currency:TapCurrencyCode) -> Bool {
        // Make sure the currency list has values with the given currenct or it supports every currency
        return (supportedCurrencies == []) || (supportedCurrencies.filter{ $0.appleRawValue == currency.appleRawValue } != [])
        
    }
}
