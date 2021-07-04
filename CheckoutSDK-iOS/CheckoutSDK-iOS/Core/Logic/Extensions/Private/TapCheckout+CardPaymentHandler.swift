//
//  TapCheckout+CardPaymentHandler.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/2/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import struct TapCardVlidatorKit_iOS.CardBrandWithSchemes

/// Logic to handle card payment flow
extension TapCheckout {
    
    /**
     Provides the logic needed to be done upon changing the card data provided by the user in the card form or the scanner
     - Parameter with card: The new card model with all the new data
     */
    func handleCardData(with card:TapCard?) {
        // Check if we have less than 6 digits we clear the current stored bin response
        
        guard let card = card, let cardNumber:String = card.tapCardNumber,
              cardNumber.count >= 6 else {
            // Then we need to reset the last called bin response if any.
            dataHolder.transactionData.binLookUpModelResponse = nil
            return
        }
        
        // Check if we need to call the binlook up first
        if shouldWeCallBinLookUpAgain(with: card) {
            // Call the binlook up
            getBINDetails(for: cardNumber.tap_substring(to: 6)) { [weak self] (binResponseModel) in
                // Let us handle and do the needed logic with the latest fetched bin response model
                // First, store it for further processing and access
                self?.dataHolder.transactionData.binLookUpModelResponse = binResponseModel
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
        guard dataHolder.transactionData.binLookUpModelResponse?.binNumber != cardNumber.tap_substring(to: 6) else {
            // This means we shouldn't call the binlook up
            return false
        }
        
        // This means we should call the bin look as we didn't call it before
        return true
    }
    
    /**
     Decides whether we should allow entering the card details or not based on checking if its type is one of the allowed card types passed by the merchant
     - Parameter with cardNumber: To check against this card number if any. If not provided, we will decide based on the last saved card data.
     - Returns: True if whether we didn't call the bin api yet or the bin api response card type is one of the allowed card types
     */
    func shouldAllowCard(with cardNumber:String? = nil) -> Bool {
        
        // Make sure we have a valid bin response
        guard let responseModel = dataHolder.transactionData.binLookUpModelResponse else {
            // Then we should allow as we have nothing to compare against
            return true
        }
        
        // If the caller passed a number to check against then we need to apply a different logic, than deciding if the current card is allowed or not
        if let nonNullCardNumber = cardNumber {
            // We need to check against the provided card number
            return shouldAllowUpdatedCard(with: nonNullCardNumber)
        }else{
            // Then we need to check about the last stored card data
            
            // get the bin response card type
            let currentCardType:CardType = responseModel.cardType
            // Check if it is one of the allowed card types passed from the merchant on checkout start
            return dataHolder.transactionData.allowedCardTypes.contains(currentCardType)
        }
    }
    
    /**
     Decides if the new updated to the card number should be allowed or not.
     - Parameter with cardNumber: The new card number entered by the user.
     - Returns: True if:
            A) No bin api called yet.
            B) The updated card number matches the last called bin and it is of the allowed card types
            C) Even if the current prefix doesn't match the allowed types but the user hit BACKSPACE, so only deletion is allowed at this case
     */
    fileprivate func shouldAllowUpdatedCard(with cardNumber:String) -> Bool {
        // We need to make sure that we already have a bin response to check against, new card number is more than 5 digits and the current bin response model doesn't match the allowed card types
        guard let _:TapBinResponseModel = dataHolder.transactionData.binLookUpModelResponse,
              cardNumber.count >= 6, !shouldAllowCard() else {
            return true
        }
        
        // In this case we have a card number that doesn't match the allowed card types. We need to only allow backspace/deletion no more entering wong card numbers
        
        return cardNumber.tap_length < dataHolder.transactionData.currentCard?.tapCardNumber?.tap_length ?? 6
    }
    
    /**
     Used to tell the UI to change the data of the card form to a given card details
     - Parameter with card: The tap card we nede to fill the UI with
     - Parameter then focusCardNumber: Indicate whether we need to focus the card number after setting the card data
     */
    func setCardData(with card:TapCard,then focusCardNumber:Bool) {
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.setCard(with: card, then: true)
    }
    
    /**
     Used to fetch the card brand with all the supported schemes under it as per the payment options api response
     - Parameter for cardBrand: The card brand we need to know all the schemes it supports
    - Returns: List of supported schemes by the provided brand
     */
    func fetchSupportedCardSchemes(for cardBrand:CardBrand?) -> CardBrandWithSchemes? {
        
        guard let cardBrand = cardBrand,
              let _ = dataHolder.transactionData.paymentOptionsModelResponse,
              let _ = dataHolder.transactionData.binLookUpModelResponse else {
            return nil
        }
        
        return .init(dataHolder.viewModels.tapCardPhoneListDataSource.filter{  $0.tapPaymentOption?.brand == cardBrand  }.first?.tapPaymentOption?.supportedCardBrands ?? [], cardBrand)
    }
    
    
    
    
    /**
     Handles the logic needed to be applied upon card form validation status changes
     - Parameter cardBrand: The detected card brand
     - Parameter with validation: The validation status came out of the card validator
     */
    func handleCardValidationStatus(for cardBrand: CardBrand,with validation: CrardInputTextFieldStatusEnum) {
        // Check if valid or not and based on that we decide the logic to be done
        if validation == .Valid,
           dataHolder.viewModels.tapCardTelecomPaymentViewModel.decideHintStatus() == .None {
            // All good and we can start the payment once the user clicks on the action button
            dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .ValidPayment
            dataHolder.viewModels.tapSaveCardSwitchViewModel.cardState = .validCard
            // Fetch the payment option related to the validated card brand
            let paymentOptions:[PaymentOption] = dataHolder.viewModels.tapCardPhoneListDataSource.filter{ $0.tapPaymentOption?.brand == cardBrand }.filter{ $0.tapPaymentOption != nil }.map{ $0.tapPaymentOption! }
            guard paymentOptions.count > 0 else {
                handleError(error: "Unexpected error, trying to start card payment without a payemnt option selected.")
                return }
            // Assign the action to be done once clicked on the action button to start the payment
            let payAction:()->() = { [weak self] in self?.startCardPayment(with:paymentOptions.first,and:self?.dataHolder.transactionData.currentCard) }
            dataHolder.viewModels.tapActionButtonViewModel.buttonActionBlock = payAction
            
        }else{
            // The status is invalid hence we need to clear the action button
            dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .InvalidPayment
            dataHolder.viewModels.tapActionButtonViewModel.buttonActionBlock = {}
            dataHolder.viewModels.tapSaveCardSwitchViewModel.cardState = .invalidCard
        }
    }
    
}
