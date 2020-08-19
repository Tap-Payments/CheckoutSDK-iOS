//
//  TapCheckoutExtensions.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/19/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
import PassKit

internal extension Array where Element: CurrencyCardsTelecomModel {
    /**
     Extended method to easily extract the list of tapCardPhoneViewModel from list of CurrencyCardsTelecomModel that supports a certain currenct
     - Parameter currency: Pass the currency you want to see its support. If no passed, the Global UserCurrency will be used as the filtering currency
     - Returns: List of the tapCardPhoneViewModels that supports the given currency code
     */
    func filter(for currency:TapCurrencyCode) -> [TapCardPhoneIconViewModel] {
        return self.filter{ $0.isEnabled(for: currency) }.map{ $0.tapCardPhoneViewModel }
    }
    
    func telecomCountry(for currency:TapCurrencyCode) -> TapCountry? {
        let nonNullCountriesFiltered = self.filter{ $0.isEnabled(for: currency) && $0.supportedTelecomCountry != nil }
        guard nonNullCountriesFiltered.count > 0 else {
            return nil
        }
        
        return nonNullCountriesFiltered[0].supportedTelecomCountry
    }
}

internal extension Array where Element: CurrencyChipModel {
    /**
     Extended method to easily extract the list of GenericTapChipViewModel from list of CurrencyChipModel that supports a certain currenct
     - Parameter currency: Pass the currency you want to see its support. If no passed, the Global UserCurrency will be used as the filtering currency
     - Returns: List of the chip models that supports the given currency code
     */
    func filter(for currency:TapCurrencyCode) -> [GenericTapChipViewModel] {
        return self.filter{ $0.isEnabled(for: currency) }.map{ $0.tapChipViewModel }
    }
}


internal extension Array where Element: ItemModel {
    /**
     Extended method to easily extract the total amount of a list of tap payment items
     - Parameter convertFromCurrency: The original currency if needed to convert from
     - Parameter convertToCurrenct: The new currency if needed to convert to
     - Returns: Total amount of list of tap payment items
     */
    func totalItemsPrices(convertFromCurrency:TapCurrencyCode? = nil,convertToCurrenct:TapCurrencyCode? = nil) -> Double {
        return self.map{ $0.itemFinalPrice(convertFromCurrency: convertFromCurrency, convertToCurrenct: convertToCurrenct) }.reduce(0, +)
    }
    
    /**
     Extended method to easily covert list of tap payment items to Apple pay payment items
     - Parameter convertFromCurrency: The original currency if needed to convert from
     - Parameter convertToCurrenct: The new currency if needed to convert to
     - Returns: Correctly Apple Pay payment items
     */
    func toApplePayItems(convertFromCurrency:TapCurrencyCode? = nil,convertToCurrenct:TapCurrencyCode? = nil) -> [PKPaymentSummaryItem] {
        return self.map{ PKPaymentSummaryItem.init(label: $0.title ?? "Item", amount: NSDecimalNumber(value: $0.itemFinalPrice(convertFromCurrency: convertFromCurrency, convertToCurrenct: convertToCurrenct))) }
    }
}


