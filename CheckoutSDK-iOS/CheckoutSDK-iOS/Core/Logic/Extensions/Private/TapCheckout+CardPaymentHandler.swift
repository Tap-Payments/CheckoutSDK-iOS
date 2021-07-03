//
//  TapCheckout+CardPaymentHandler.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/2/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// Logic to handle card payment flow
extension TapCheckout {
    
    /**
     Provides the logic needed to be done upon changing the card data provided by the user in the card form or the scanner
     - Parameter with card: The new card model with all the new data
     */
    func handleCardData(with card:TapCard) {
        // Check if we have less than 6 digits we clear the current stored bin response
        
        guard let cardNumber:String = card.tapCardNumber,
              cardNumber.count >= 6 else {
            // Then we need to reset the last called bin response if any.
            dataHolder.transactionData.binLookUpModelResponse = nil
            return
        }
        
        // Check if we need to call the binlook up first
        if shouldWeCallBinLookUpAgain(with: card) {
            // Call the binlook up
            getBINDetails(for: cardNumber.tap_substring(to: 6)) { (binResponseModel) in
                
            } onErrorOccured: { [weak self] (error) in
                self?.handleError(error: error)
            }

        }
    }
    
    /**
     Indicates whether we need to call the binlookup api for the provided card.
     - Parameter with card: The card we need to decide calling the binlookup api or not on.
     - Returns: True of the provided card has different 6 digits prefix than the last time called binlook up response. False otherwise.
     */
    fileprivate func shouldWeCallBinLookUpAgain(with card:TapCard) -> Bool {
        
        // We call the binlook up only when we have at least 6 digits
        guard let cardNumber:String = card.tapCardNumber,
              cardNumber.count >= 6 else {
            return false
        }
        
        // Let us make sure we already have a bin look up model called already to compare against and if yes, they have different prefixes
        guard let lastBinLookUpResponse:TapBinResponseModel = dataHolder.transactionData.binLookUpModelResponse,
              lastBinLookUpResponse.binNumber != cardNumber else {
            // This means we should call the bin look as we didn't call it before
            return true
        }
        
        // This means we shouldn't call the binlook up
        return false
    }
    
    
}
