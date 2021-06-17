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
}
