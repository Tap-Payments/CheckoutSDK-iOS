//
//  CurrencyCardsTelecomModel.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/17/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
/// Represents a model that will link the different Cards and Telecom bar item view models with their approved currencies and countries
internal class CurrencyCardsTelecomModel {
    
    /// Represents the card/telecom bar item view model itself (Visa, Amex, )
    lazy var tapCardPhoneViewModel:TapCardPhoneIconViewModel = .init(associatedCardBrand: .visa)
    /// Represents the list of currencies the bar item supports or should be visible when selected
    lazy var supportedCurrencies:[TapCurrencyCode] = []
    /// Repreents the country associated with the telecom bar payments if any
    lazy var supportedTelecomCountry:TapCountry? = nil
    
    /**
     Creates a new instance that links the bar view model with certain currencies
     - Parameter tapCardPhoneViewModel: Represents the card/telecom bar item view model itself (Visa, Amex, )
     - Parameter supportedCurrencies: Represents the list of currencies the bar item supports or should be visible when selected selected
     - Parameter supportedTelecomCountry: Repreents the country associated with the telecom bar payments if any
     */
    init(tapCardPhoneViewModel:TapCardPhoneIconViewModel, supportedCurrencies:[TapCurrencyCode] = [], supportedTelecomCountry:TapCountry? = nil) {
        self.tapCardPhoneViewModel = tapCardPhoneViewModel
        self.supportedCurrencies = supportedCurrencies
        self.supportedTelecomCountry = supportedTelecomCountry
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


internal extension Array where Element: CurrencyCardsTelecomModel {
    /**
     Extended method to easily extract the list of tapCardPhoneViewModel from list of CurrencyCardsTelecomModel that supports a certain currenct
     - Parameter currency: Pass the currency you want to see its support. If no passed, the Global UserCurrency will be used as the filtering currency
     - Returns: List of the tapCardPhoneViewModels that supports the given currency code
     */
    func filter(for currency:TapCurrencyCode) -> [TapCardPhoneIconViewModel] {
        return self.filter{ $0.isEnabled(for: currency) }.map{ $0.tapCardPhoneViewModel }
    }
}

