//
//  TapCheckout+CardPaymentHandler.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/2/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import TapCardVlidatorKit_iOS
import CommonDataModelsKit_iOS
import TapCardInputKit_iOS
import TapUIKit_iOS
/// Logic to handle card payment flow
extension TapCheckout {
    
    /**
     The event will be fired when the user cliks on a goPay saved card chip
     - Parameter viewModel: Represents The attached view model
     */
    func handleGoPaySavedCard(for viewModel: SavedCardCollectionViewCellModel) {
        // First of all deselct any selected cards in the gateways list
        dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.deselectAll()
    }
    
    /**
     The event will be fired when the user cliks on a  saved card chip
     - Parameter viewModel: Represents The attached view model
     - Parameter shouldResetCardFormFirst: Indicates if we remove the entered data in the card form upon selecting a saved card chip. Default is true
     */
    func handleSavedCard(for viewModel: SavedCardCollectionViewCellModel, shouldResetCardFormFirst:Bool = true) {
        // first check if we need to Reset the card form
        guard !shouldResetCardFormFirst else {
            // We reset the card form
            resetCardData(shouldFireCardDataChanged: false)
            // We reselct the selected saved card chip without the need to reset as we just did
            handleSavedCard(for: viewModel, shouldResetCardFormFirst: false)
            return
        }
        // First of all deselct any selected cards in the goPay list
        dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.deselectAll()
        // Save the selected payment option model for further processing
        dataHolder.transactionData.selectedPaymentOption = fetchPaymentOption(with: viewModel.paymentOptionIdentifier)
        // Configure the payment option to hold the selected saved card object
        dataHolder.transactionData.selectedPaymentOption?.savedCard = fetchSavedCardOption(with: viewModel.savedCardID ?? "")
        // Change its type to a saved card one to know that while processing the transaction
        dataHolder.transactionData.selectedPaymentOption?.paymentType = .SavedCard
        
        // We need to inform the card input, to start the saved card mode
        if let nonNullSavedCard = fetchSavedCardOption(with: viewModel.savedCardID ?? "") {
            dataHolder.viewModels.tapCardTelecomPaymentViewModel.setSavedCard(savedCard: nonNullSavedCard)
            // Keep the button invalid until the CVV is correcly filled
            dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .InvalidPayment
            dataHolder.viewModels.tapActionButtonViewModel.buttonActionBlock = {}
        }
    }
    
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
            // Instruct the data manager that we are currently requesting a bin for this prefix
            dataHolder.transactionData.currentlyRequestingBinFor = cardNumber.tap_substring(to: 6)
            // Call the binlook up
            getBINDetails(for: cardNumber.tap_substring(to: 6)) { [weak self] (binResponseModel) in
                // Let us handle and do the needed logic with the latest fetched bin response model
                // First, store it for further processing and access
                self?.dataHolder.transactionData.binLookUpModelResponse = binResponseModel
            } onErrorOccured: { [weak self] (session, result, error) in
                self?.handleError(session: session, result: result, error: error)
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
        
        // Let us make sure we are not requesting currently for the same number
        guard dataHolder.transactionData.currentlyRequestingBinFor != cardNumber.tap_substring(to: 6) else { return false }
        
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
     - Parameter shouldRemoveCurrentCard:If there is a card number, first thing to do now is to clear the fields
     - Parameter for cardUIStatus: Indicates whether the given card is from a normal process like scanning or to show the special UI for a saved card flow
     */
    func setCardData(with card:TapCard,then focusCardNumber:Bool,shouldRemoveCurrentCard:Bool = true,for cardUIStatus:CardInputUIStatus) {
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.setCard(with: card, then: true, shouldRemoveCurrentCard: shouldRemoveCurrentCard, for: cardUIStatus)
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
    func handleCardValidationStatus(for cardBrand: CardBrand,with validation: CrardInputTextFieldStatusEnum,cardStatusUI:CardInputUIStatus) {
        // Check if valid or not and based on that we decide the logic to be done
        if validation == .Valid,
           dataHolder.viewModels.tapCardTelecomPaymentViewModel.decideHintStatus(and:cardStatusUI) == .None {
            // All good and we can start the payment once the user clicks on the action button
            
            // Based on the card input status (filling in CVV for a saved card or just finished filling in the data of a new card) we decide the actions to be done by the pay button
            if cardStatusUI == .NormalCard {
                dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .ValidPayment
                // Fetch the payment option related to the validated card brand
                let paymentOptions:[PaymentOption] = dataHolder.viewModels.tapCardPhoneListDataSource.filter{ $0.tapPaymentOption?.brand == cardBrand }.filter{ $0.tapPaymentOption != nil }.map{ $0.tapPaymentOption! }
                guard paymentOptions.count > 0, let selectedPaymentOption:PaymentOption = paymentOptions.first else {
                    handleError(session: nil, result: nil, error: "Unexpected error, trying to start card payment without a payemnt option selected.")
                    return }
                // Assign the action to be done once clicked on the action button to start the payment
                dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .ValidPayment
                let payAction:()->() = { [weak self] in self?.processCheckout(with:selectedPaymentOption,andCard:self?.dataHolder.transactionData.currentCard) }
                dataHolder.viewModels.tapActionButtonViewModel.buttonActionBlock = payAction
            }else{
                // The action button should be in a valid state as saved cards are ready to process right away
                // Make the button action to start the paymet with the selected saved card
                // Start the payment with the selected saved card
                let savedCardActionBlock:()->() = { [weak self] in
                    self?.processCheckout(with: (self?.dataHolder.transactionData.selectedPaymentOption!)!) }
                chanegActionButton(status: .ValidPayment, actionBlock: savedCardActionBlock)
            }
        }else{
            // The status is invalid hence we need to clear the action button
            dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .InvalidPayment
            dataHolder.viewModels.tapActionButtonViewModel.buttonActionBlock = {}
        }
        
        // Check about the loyalty widget
        handleLoyalty(for:cardBrand,with: validation)
        // Check about customer data collection if needed
        handleCustomerContact(with: validation)
    }
    
    
    /**
     Handles the logic needed to be applied upon card form validation status changes regrding the loyalty widget
     - Parameter cardBrand: The detected card brand
     - Parameter with validation: The validation status came out of the card validator
     */
    func handleCustomerContact(with validation: CrardInputTextFieldStatusEnum) {
        // Check of we can display loyalty section or not
        if canShowCustomerContactData(),
           let nonCustomerContactViewModel: CustomerContactDataCollectionViewModel = dataHolder.viewModels.customerDataViewModel {
            //updateLoyaltySection()
            // Now let us show the loyalty section after a slight delay allowing the keyboard to be dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250), execute: { [weak self] in
                self?.UIDelegate?.showCustomerContactDataCollection(with: nonCustomerContactViewModel, animate: true)
            })
        }else{
            // Then if no valid card data is provided, all what we need to do is to remove the loyalty section if any
            UIDelegate?.hideCustomerContactDataCollection()
        }
    }
    
    /**
     Handles the logic needed to be applied upon card form validation status changes regrding the loyalty widget
     - Parameter cardBrand: The detected card brand
     - Parameter with validation: The validation status came out of the card validator
     */
    func handleLoyalty(for cardBrand: CardBrand,with validation: CrardInputTextFieldStatusEnum) {
        // Check of we can display loyalty section or not
        if canShowLoyalty(),
           let nonNullLoyaltyViewModel: TapLoyaltyViewModel = dataHolder.viewModels.tapLoyaltyViewModel {
            //updateLoyaltySection()
            // Now let us show the loyalty section after a slight delay allowing the keyboard to be dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250), execute: { [weak self] in
                self?.UIDelegate?.showLoyalty(with: nonNullLoyaltyViewModel, animate:true)
            })
        }else{
            // Then if no valid card data is provided, all what we need to do is to remove the loyalty section if any
            UIDelegate?.hideLoyalty()
        }
    }
    
    
    /// Checks all the conditoins to show a customer contact data collection section including
    func canShowCustomerContactData() -> Bool {
        // Check if the card's data including number, CVV and expiry are valid
        guard dataHolder.viewModels.tapCardTelecomPaymentViewModel.allCardFieldsValid(),
              // Check if the user activated saving for TAP
              dataHolder.viewModels.tapCardTelecomPaymentViewModel.isTapSaveAllowed,
              // Check if there is a data needed to be collected
              let _: CustomerContactDataCollectionViewModel = dataHolder.viewModels.customerDataViewModel
        else {
            return false
        }
        
        return true
    }
    
    /// Checks all the conditoins to show a loyalty section including
    /// There is a loyalty model, card data is fully valid, used currency is supported by the loyalty model
    func canShowLoyalty() -> Bool {
        // Check if the card's data including number, CVV and expiry are valid
        guard dataHolder.viewModels.tapCardTelecomPaymentViewModel.allCardFieldsValid(),
              // Check if there is a loyalty model to display
              let nonNullLoyaltyViewModel: TapLoyaltyViewModel = dataHolder.viewModels.tapLoyaltyViewModel,
              // Check if the card's bank is the same providing the loyalty model
              let _:String = dataHolder.transactionData.binLookUpModelResponse?.bank?.lowercased(),
              // Get the spported currencies by the loyalty model
              let supportedLoyaltyCurrencies:[TapCurrencyCode] = nonNullLoyaltyViewModel.loyaltyModel?.supportedCurrencies?.map({ $0.currency?.currency ?? .undefined })
              //binBankName.contains("adcb"),
        else {
              return false
        }
        
        // Let us see which currency is being used now as we will use it to make sure it is one of the supported currencies by the loyalty model if any
        let currenyUsedCurrency: TapCurrencyCode = dataHolder.viewModels.currentUsedCurrency
        // Check if the current selected currency is one of the supported currencies in the loyalty model
        return supportedLoyaltyCurrencies.contains(currenyUsedCurrency)
    }
    
    
    /**
     Handles the logic to be executed when redirection is finished for card saving
     - Parameter with tapID: The tap id of the object (card saving) generated from the backend in the URL
     */
    func cardPaymentProcessFinished(with tapID:String) {
        TapCheckout.sharedCheckoutManager().chanegActionButton(status: .ValidPayment, actionBlock: nil)
        // Hide the webview
        UIDelegate?.closeWebView()
        // Show the button in a loading state
        dataHolder.viewModels.tapActionButtonViewModel.startLoading()
        // We need to retrieve the object using the passed id and process it afterwards
        retrieveObject(with: tapID) { [weak self] (returnVerifiedSaveCard: TapCreateCardVerificationResponseModel?, error: TapSDKError?) in
            if let error = error {
                self?.handleError(session: nil, result: nil, error: error)
            }else if let returnVerifiedSaveCard = returnVerifiedSaveCard {
                // No errors occured we need to process the current charge or authorize
                self?.handleCardVerify(with: returnVerifiedSaveCard)
            }
        } onErrorOccured: { [weak self] (session, result, error) in
            self?.handleError(session: session, result: result, error: error)
        }
        
    }
    
}
