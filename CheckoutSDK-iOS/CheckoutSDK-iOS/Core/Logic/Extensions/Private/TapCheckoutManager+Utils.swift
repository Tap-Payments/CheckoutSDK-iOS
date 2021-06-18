//
//  TapCheckoutManager+Utils.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/17/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// A collection of logic to provide utils and singleton interfaces for multiple required methods
internal extension TapCheckoutSharedManager {
    
    /**
     Gets the related payment option for a saved card
     - Parameter for: The saved card of the needed payment option
     - Returns: Payment option if found with the specified saved card, else nil
     */
    func fetchPaymentOption(for savedCard:SavedCard) -> PaymentOption? {
        guard let paymentOptionsResponse = paymentOptionsModelResponse, let paymentOptionIdentifier = savedCard.paymentOptionIdentifier else { return nil }
        return paymentOptionsResponse.fetchPaymentOption(with: paymentOptionIdentifier)
    }
    
    
    /**
     Gets the related payment option by id
     - Parameter with: The id of the needed payment option
     - Returns: Payment option if found with the specified id, else nil
     */
    func fetchPaymentOption(with paymentOptionIdentifier:String) -> PaymentOption? {
        guard let paymentOptionsResponse = paymentOptionsModelResponse, let paymentOption:PaymentOption = paymentOptionsResponse.paymentOptions.filter({ $0.identifier == paymentOptionIdentifier }).first else { return nil }
        return paymentOption
    }
    
    
    /**
     Gets the transaction total amount for a given currency
     - Parameter for: The currency you want to know the total amount regards
     - Returns: The total amount for the currency as stated in the payment options api response
     */
    func fetchTotalAmount(for currency:TapCurrencyCode) -> Double {
        guard let paymentOptionsResponse = paymentOptionsModelResponse else { return 0 }
        
        // get the amounted currency related to tthe tap currency code model
        let filteredCurrenciesList = paymentOptionsResponse.supportedCurrenciesAmounts.filter{ $0.currency == currency }
        guard !filteredCurrenciesList.isEmpty, let amount = filteredCurrenciesList.first?.amount  else { return 0 }
        
        return amount
    }
}
