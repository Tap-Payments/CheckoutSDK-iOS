//
//  AmountedCurrency.swift
//  goSellSDK
//
//  Copyright © 2019 Tap Payments. All rights reserved.
//

/// Structure holding currency and the amount.
/*
internal struct AmountedCurrency: Decodable {
    
    // MARK: - Internal -
    // MARK: Properties
    
    /// Currency.
    internal let currency: TapCurrencyCode
    
    /// Amount.
    internal let amount: Double
    
    /// Currency symbol.
    internal let currencySymbol: String
    
    /// Currency flag icon url.
    internal let flag: String
    
    /// Conversion factor to transaction currency from baclend
    internal var rate: Double?
        
    /// Conversion factor to transaction currency computed
    internal var conversionFactor: Double{
        get{
            if let parsedRate:Double = rate
            {
                return parsedRate
            }else
            {
                return amount/TapCheckout.sharedCheckoutManager().transactionTotalAmountValue
            }
        }
    }
    
    // MARK: Methods
    
    internal init(_ currency: TapCurrencyCode, _ amount: Double, _ flag: String) {
        self.init(currency, amount, currency.symbolRawValue, flag)
    }
    
    internal init(_ currency: TapCurrencyCode, _ amount: Double, _ currencySymbol: String, _ flag: String) {
        
        self.currency       = currency
        self.amount         = amount
        self.currencySymbol = currencySymbol
        self.flag = flag
    }
    
    
    
    func calculateConvrsionRate()
    {
        //
    }
    
    // MARK: - Private -
    
    private enum CodingKeys: String, CodingKey {
        
        case currency       = "currency"
        case amount         = "amount"
        case currencySymbol = "symbol"
        case rate           = "rate"
        case flag           = "flag"
    }
}

// MARK: - Equatable
extension AmountedCurrency: Equatable {
    
    internal static func == (lhs: AmountedCurrency, rhs: AmountedCurrency) -> Bool {
        
        return lhs.currency == rhs.currency && lhs.amount == rhs.amount
    }
}
*/
