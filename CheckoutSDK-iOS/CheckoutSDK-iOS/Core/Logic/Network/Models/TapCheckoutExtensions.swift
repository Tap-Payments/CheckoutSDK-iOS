//
//  TapCheckoutExtensions.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/19/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
import PassKit
import CommonDataModelsKit_iOS
import TapUIKit_iOS

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

internal extension Array where Element: ChipWithCurrencyModel {
    /**
     Extended method to easily extract the list of GenericTapChipViewModel from list of ChipWithCurrencyModel that supports a certain currenct
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
    func totalItemsPrices(convertFromCurrency:AmountedCurrency? = nil,convertToCurrenct:AmountedCurrency? = nil) -> Double {
        return self.map{ $0.itemFinalPrice(convertFromCurrency: convertFromCurrency, convertToCurrenct: convertToCurrenct) }.reduce(0, +)
    }
    
    /**
     Extended method to easily covert list of tap payment items to Apple pay payment items
     - Parameter convertFromCurrency: The original currency if needed to convert from
     - Parameter convertToCurrenct: The new currency if needed to convert to
     - Returns: Correctly Apple Pay payment items
     */
    func toApplePayItems(convertFromCurrency:AmountedCurrency? = nil,convertToCurrenct:AmountedCurrency? = nil) -> [PKPaymentSummaryItem] {
        return self.map{ PKPaymentSummaryItem.init(label: $0.title ?? "Item", amount: NSDecimalNumber(value: ($0.itemFinalPrice(convertFromCurrency: convertFromCurrency, convertToCurrenct: convertToCurrenct)).rounded(toPlaces: convertToCurrenct?.decimalDigits))) }
        
        //return self.map{ PKPaymentSummaryItem.init(label: $0.title ?? "Item", amount: NSDecimalNumber(value: 1)) }
    }
}


internal extension Array where Element: Shipping {
   
    /**
     Extended method to easily covert list of tap payment shippings to Apple pay payment items
     - Parameter convertFromCurrency: The original currency if needed to convert from
     - Parameter convertToCurrenct: The new currency if needed to convert to
     - Returns: Correctly Apple Pay payment items
     */
    func toApplePayShippings(convertFromCurrency:AmountedCurrency? = nil,convertToCurrenct:AmountedCurrency? = nil) -> [PKPaymentSummaryItem] {
        
        guard let convertToCurrency = convertToCurrenct,
        let convertFromCurrency = convertFromCurrency else {
            return []
        }
        
        return self.map{ PKPaymentSummaryItem.init(label: $0.name, amount: NSDecimalNumber(value: (convertToCurrency.currency.convert(from: convertFromCurrency.currency, for: NSDecimalNumber(decimal:$0.amount).doubleValue)).rounded(toPlaces: convertToCurrency.decimalDigits))) }
    }
}


internal extension Shipping {
    /**
     Extended method to easily covert list of tap payment shippings to Apple pay payment items
     - Parameter convertFromCurrency: The original currency if needed to convert from
     - Parameter convertToCurrenct: The new currency if needed to convert to
     - Returns: Correctly Apple Pay payment items
     */
    func toApplePayShipping(convertFromCurrency:AmountedCurrency? = nil,convertToCurrenct:AmountedCurrency? = nil) -> [PKPaymentSummaryItem] {
        
        guard let convertToCurrency = convertToCurrenct,
              let convertFromCurrency = convertFromCurrency else {
            return []
        }
        
        return [PKPaymentSummaryItem.init(label: name, amount: NSDecimalNumber(value: (convertToCurrency.currency.convert(from: convertFromCurrency.currency, for: NSDecimalNumber(decimal:amount).doubleValue)).rounded(toPlaces: convertToCurrency.decimalDigits))) ]
    }
}


internal extension Array where Element: Tax {
    
    /**
     Extended method to easily covert list of tap payment taxs to Apple pay payment items
     - Parameter convertFromCurrency: The original currency if needed to convert from
     - Parameter convertToCurrenct: The new currency if needed to convert to
     - Returns: Correctly Apple Pay payment items
     */
    func toApplePayTaxes(convertFromCurrency:AmountedCurrency? = nil,convertToCurrenct:AmountedCurrency? = nil) -> [PKPaymentSummaryItem] {
        
        guard let _ = convertToCurrenct,
              let _ = convertFromCurrency else {
            return []
        }
        
        return [] //self.map{ PKPaymentSummaryItem.init(label: $0.name, amount: NSDecimalNumber(value: (convertToCurrency.currency.convert(from: convertFromCurrency.currency, for: NSDecimalNumber(decimal:$0.amount).doubleValue)).rounded(toPlaces: convertToCurrency.decimalDigits))) }
    }
}


extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int?) -> Double {
        guard let places = places else {
            return self
        }

        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}


