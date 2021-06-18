//
//  TapCheckoutManager+PaymentProcesses.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/18/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// Collection of logic to process a payment with different flows
internal extension TapCheckoutSharedManager {
    
    /**
     Used to process a checkout process with a given payment option
     - Parameter with paymentOption: The payment option to start the checkout process with
     */
    func processCheckout(with paymentOption:PaymentOption) {
        // For all payment options types, we need to ask for extra fees first if any
        askForExtraFees(with: paymentOption)
    }
    
    /**
     Used to confirm the extra fees for a given payment option
     - Parameter with paymentOption: The payment option to ask for its extra fees
     */
    func askForExtraFees(with paymentOption:PaymentOption) {
        // get the extra fees value
        let extraFeesValue:Double = calculateExtraFees(for: paymentOption)
        // check if there is an extra fee to pay or not
        guard extraFeesValue > 0 else { return }
        // Create the formatted extra fee + the formatted new total amount
        let formatter = TapAmountedCurrencyFormatter { [weak self] in
            $0.currency = self?.transactionUserCurrencyValue.currency ?? .USD
            $0.locale = CurrencyLocale.englishUnitedStates
        }
        let extraFeesFormattedString = formatter.string(from: extraFeesValue) ?? "KD0.000"
        let newTotalAmountString = formatter.string(from: extraFeesValue + calculateFinalAmount()) ?? "KD0.000"
        
        // Create the formatted confirmation message
    }
    
}
