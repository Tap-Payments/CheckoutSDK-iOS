//
//  TapCheckoutManager+Calculations.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/18/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// Contains logic that needed to do any computation during the checkout process
internal extension TapCheckoutSharedManager {
    
    /**
     Used to compute the correct extra fees for a given payment option with regards to the current transaction total amount
     - Parameter for: The payment option you want to calclate its extra fees value
     - Returns: The correct extra fees to be allowed with regarding the extra fees type of the payment option and the transaction total amount
     */
    func calculateExtraFees(for paymentOption:PaymentOption) -> Double {
        // Get the correct extra fees value for the payment option
        return paymentOption.extraFees.reduce(0.0, { $0 + $1.extraFeeValue(for: calculateFinalAmount()) })
    }
    
}
