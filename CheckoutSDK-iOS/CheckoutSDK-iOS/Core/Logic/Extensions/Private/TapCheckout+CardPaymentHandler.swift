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
        // First thing to do is to enable the card form, just in case it was disabled due to clicking on a redirectional payment gateway
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.changeEnableStatus(to:true)
        // first check if we need to Reset the card form
        guard !shouldResetCardFormFirst else {
            // We cache current card data for further usage
            dataHolder.viewModels.tapCardTelecomPaymentViewModel.cacheCard()
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
            
            // Log it
            //log().verbose("Saved card selected : \( nonNullSavedCard.displayTitle ) & \( nonNullSavedCard.identifier ?? "" )")
            setLoggingCustomerData()
            logBF(message: "Saved card selected : \( nonNullSavedCard.displayTitle ) & \( nonNullSavedCard.identifier ?? "" )", tag: .EVENTS)
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
     - Parameter forceNoFocus: If it is true, then no field will be focused whatsoever
     */
    func setCardData(with card:TapCard,then focusCardNumber:Bool,shouldRemoveCurrentCard:Bool = true,for cardUIStatus:CardInputUIStatus, forceNoFocus:Bool = false) {
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.setCard(with: card, then: focusCardNumber, shouldRemoveCurrentCard: shouldRemoveCurrentCard, for: cardUIStatus, forceNoFocus: forceNoFocus)
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
     - Parameter isCVVFocused: Will tell the focusing state of the CVV, will be used not to show CVV hint if the field is focused in the saved card view
     */
    func handleCardValidationStatus(for cardBrand: CardBrand,with validation: CrardInputTextFieldStatusEnum,cardStatusUI:CardInputUIStatus, isCVVFocused:Bool) {
        // As long as we are getting updated card data, we will only consider it as the selected payment option if and only if it is a valid card
        // But we will keep an instance of it in case it is a saved card. As the saved card paymnent option is computed at the time it is selected
//        let currentSelectedPaymentOption = dataHolder.transactionData.selectedPaymentOption
//        dataHolder.transactionData.selectedPaymentOption = nil
        // Check if valid or not and based on that we decide the logic to be done
        if validation == .Valid,
           dataHolder.viewModels.tapCardTelecomPaymentViewModel.decideHintStatus(and:cardStatusUI,isCVVFocused: isCVVFocused) == .None {
            // All good and we can start the payment once the user clicks on the action button
            
            // Based on the card input status (filling in CVV for a saved card or just finished filling in the data of a new card) we decide the actions to be done by the pay button
            if cardStatusUI == .NormalCard {
                // Fetch the payment option related to the validated card brand
                guard let selectedPaymentOption:PaymentOption = fetchPaymentOption(with: cardBrand) else {
                    handleError(session: nil, result: nil, error: "Unexpected error, trying to start card payment without a payemnt option selected.")
                    return }
                // Store this selected payment option for further usages
                dataHolder.transactionData.selectedPaymentOption = selectedPaymentOption
                
                // We need to handle now what to do with the detected card brand as we are showing enabled and disabled ones
                handleValidCardPaymentOption(selectedPaymentOption: selectedPaymentOption)
            }else{
                // The action button should be in a valid state as saved cards are ready to process right away
                // Make the button action to start the paymet with the selected saved card
                // Start the payment with the selected saved card
                //dataHolder.transactionData.selectedPaymentOption = currentSelectedPaymentOption
                let savedCardActionBlock:()->() = { [weak self] in
                    self?.processCheckout(with: (self?.dataHolder.transactionData.selectedPaymentOption!)!, andCard: self?.dataHolder.transactionData.currentCard) }
                chanegActionButton(status: .ValidPayment, actionBlock: savedCardActionBlock)
            }
        }else{
            // The status is invalid hence we need to clear the action button
            dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .InvalidPayment
            dataHolder.viewModels.tapActionButtonViewModel.buttonActionBlock = {}
            // Remove the currency widget if any
            removeCurrencyWidget()
        }
        
        // Check about the loyalty widget
//        handleLoyalty(for:cardBrand,with: validation)
        // Check about customer data collection if needed
        //handleCustomerContact(with: validation)
    }
    
    /// Will do the needed logic upong detecting a valid card brand
    /// - Parameter selectedPaymentOption: The payment option associated with the detected card brand
    func handleValidCardPaymentOption(selectedPaymentOption:PaymentOption) {
        
        // First, let us ask the widget show logic to decide if it will show one or not
        showOrUpdateCurrencyWidget(paymentOption: selectedPaymentOption, type: isCardBrandEnabled(in: selectedPaymentOption) ? TapCurrencyWidgetType.enabledPaymentOption : TapCurrencyWidgetType.disabledPaymentOption, in: .Card)
        
        // Second, let us decide what is the post logic for the detected brand based on its validity and supported by currency or not
        postLogicValidCardBrandDetected(selectedPaymentOption: selectedPaymentOption)
        
        // Third, let us Log the brand
        logCardBrand(selectedPaymentOption: selectedPaymentOption)
    }
    
    /// Will decide what is the button action handler based on the selected payment option card brand. If it is enabled it will be active, and disabled itehrwise
    /// - Parameter selectedPaymentOption: The payment option associated with the detected card brand
    func postLogicValidCardBrandDetected(selectedPaymentOption:PaymentOption) {
        if isCardBrandEnabled(in: selectedPaymentOption) {
            // Assign the action to be done once clicked on the action button to start the payment
            dataHolder.transactionData.selectedPaymentOption = selectedPaymentOption
            dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .ValidPayment
            let payAction:()->() = { [weak self] in self?.processCheckout(with:selectedPaymentOption,andCard:self?.dataHolder.transactionData.currentCard) }
            dataHolder.viewModels.tapActionButtonViewModel.buttonActionBlock = payAction
        }else{
            // This means, that the detected card brand is not enabled for the selected currency.
            // we need to check, if this card is a co-badged one, and if the parent brand is an enabled one, so we show pay button with it
            // First, we need to check if we have a valid bin lookup response and if it is a co-badged one
            /// First of all we need to make sure that we have a co-badged card
            let (weHaveCobadged, paymentOptionForParentCardBrand, _) = doWeHaveCoBadgedCard()
            
            if weHaveCobadged,
               let paymentOptionForParentCardBrand = paymentOptionForParentCardBrand,
               isCardBrandEnabled(in: paymentOptionForParentCardBrand) {
                // This means, that we have a co-badged card brand and its original card brand is actually supported by the current currency
                // Then we will mark the pay button as valid and set the selected payment option to the one that has the original card brand
                dataHolder.transactionData.selectedPaymentOption = paymentOptionForParentCardBrand
                dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .ValidPayment
                let payAction:()->() = { [weak self] in self?.processCheckout(with:paymentOptionForParentCardBrand,andCard:self?.dataHolder.transactionData.currentCard) }
                dataHolder.viewModels.tapActionButtonViewModel.buttonActionBlock = payAction
            }else{
                // This means whether the card is not co-badged and not enabled,
                // Or co-badged but even the parent brand is not enabled
                dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .InvalidPayment
            }
        }
    }
    
    /// Will log the detected card brand for analytics purposes
    /// - Parameter selectedPaymentOption: The payment option associated with the detected card brand
    func logCardBrand(selectedPaymentOption:PaymentOption) {
        // Log the brand
        setLoggingCustomerData()
        //log().verbose("Finished valid raw card data for \(selectedPaymentOption.title)")
        logBF(message: "Finished valid raw card data for \(selectedPaymentOption.title)", tag: .EVENTS)
    }
    
    /// Will check if the provided payment option is enabled for the current selected currency
    /// - Parameter in paymentoption: The payment option we need to check
    /// - Returns: True, if the provided payment option does support the currently selected currency
    func isCardBrandEnabled(in paymentOption:PaymentOption) -> Bool {
        return paymentOption.supportedCurrencies.contains(obj: dataHolder.transactionData.transactionUserCurrencyValue.currency)
    }
    
    /// Checks whether the selected payment option is supported by the selected  currency or not
    /// - Parameter in paymentoption: The payment option we need to check
    /// - Returns: True, means the selected payment option supports the user's currency and false otherwise
    func isPaymentOptionEnabled(in paymentOption:PaymentOption) -> Bool {
        return paymentOption.supportedCurrencies.contains(obj: dataHolder.transactionData.transactionUserCurrencyValue.currency)
    }
    
    /// Handles the logic needed when the card form is being focused. Which is deselecting all payment schemes chips
    func handleCardFormIsFocused() {
        
        // We will need to act only if there is a redirection scheme was selected, as all others will not need.
        // Apple pay is a one step payment hence it is not selected by default
        // Saved card chip will already disable the card form only allowing CVV to be entered
        // Also, if there is a disabled chip selected & currency widget is displayed
        if dataHolder.transactionData.selectedPaymentOption?.paymentType == .Web ||
            dataHolder.viewModels.tapCurrencyWidgetModel != nil {
            // First step to deselect everything selected in the gopay and gateways horizontal chips
            dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.deselectAll()
            dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.deselectAll()
            // Second step, is remove the selected gateway if any from the selected payment option
            dataHolder.transactionData.selectedPaymentOption = nil
            // Then we update the action button style
            dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .InvalidPayment
            dataHolder.viewModels.tapActionButtonViewModel.buttonActionBlock = {}
            // Then let us enable the card form back
            dataHolder.viewModels.tapCardTelecomPaymentViewModel.changeEnableStatus(to: true, doPostLogic: true)
        }
        // In all cases, let us defensive wise to remove the currenc widget if any
        removeCurrencyWidget()
    }
    
    /// The method checks all conditions that will lead for displaying a currency widget related to the card data or not
    /// - Parameter selectedPaymentOption: The payment option we want to know if shall show a currency widget for or not
    /// - Returns: True, means it will be displayed. False, otherwise.
    func willShowCurrencyWidgetForCard(selectedPaymentOption:PaymentOption?) -> Bool {
        // Currency card widget won't be displayed unless selected payment option is a card one
        guard let selectedPaymentOption = selectedPaymentOption else { return false }
        let isSelectedOptionCard:Bool = selectedPaymentOption.paymentType == .Card
        
        // Currency card widget won't be displayed unless all card fields are valid
        let allCardDataAreValid:Bool = dataHolder.viewModels.tapCardTelecomPaymentViewModel.allCardFieldsValid()
        
        // // Currency card widget won't be displayed unless it supports more than 1 currency
        // let doesCardBrandSupportsMultipleCurrencies:Bool = selectedPaymentOption.supportedCurrencies.count > 1
        
        // Currency card widget won't be displayed if the last time, the user changed currency from the card widget and he didn't change the brand or the currency again. For example, if he was in VISA and switched to USD then if he is still on VISA and USD we shouldn't ask him again
        let userChangedWithThisBrandAndCurrency:Bool = (lastConfirmedCurrencyWidget?.paymentOption.identifier == selectedPaymentOption.identifier && lastConfirmedCurrencyWidget?.selectedAmountCurrency?.currency == dataHolder.transactionData.transactionUserCurrencyValue.currency)

        // We only display the widget if the currency is not the same as the selected currency if it is an enabled card brand already
        let isCardBrandEnabled:Bool = isCardBrandEnabled(in: selectedPaymentOption)
        let userCurrencyMatchesTransactionCurrency:Bool = dataHolder.transactionData.transactionCurrencyValue.currency == dataHolder.transactionData.transactionUserCurrencyValue.currency
        
        // We also need to check if it is enabled, it has another currency to show other than the current selected one
        let doesCardHasMoreCurrenciesThanCurrent:Bool = (!isCardBrandEnabled || selectedPaymentOption.supportedCurrencies.count > 1)
        
        return allCardDataAreValid && isSelectedOptionCard && !userChangedWithThisBrandAndCurrency && !(userCurrencyMatchesTransactionCurrency && isCardBrandEnabled) && doesCardHasMoreCurrenciesThanCurrent || willShowCurrencyWidgetForCoBadged()
    }
    
    /// This method will check if we will show the widget because the current payment option is a co-badged card
    /// - Returns: true, if we have a binlookup response and it's a co-badged and we need to show a widget for it. False, otherwise.
    func willShowCurrencyWidgetForCoBadged() -> (Bool) {
        // First of all we need to make sure that we have a co-badged card
        let (weHaveCobadged, _, coBadgedPaymentOption) = doWeHaveCoBadgedCard()
        
        if weHaveCobadged,
           let coBadgedPaymentOption = coBadgedPaymentOption,
           // Check if the cobadged is not supported by selected currency
           !isCardBrandEnabled(in: coBadgedPaymentOption) {
            return true
        }
        return false
    }
    
    /// Checks if the current detected card is a co-badged one
    /// - Returns: True, if we have a binlook upu and it is a co-badged card and the currency of the co-badge scheme is supported by the transaction currencies. False, otherwise. Also, if it is true, it will return the payment option that contains the parent brand and for the co-badged value.
    func doWeHaveCoBadgedCard() -> (Bool,PaymentOption?,PaymentOption?) {
        // First of all we need to make sure that we have a co-badged card
        // We need to make sure we have a valid binlook up and it has a scheme different than the original brand
        if let binLookUpResponse:TapBinResponseModel = dataHolder.transactionData.binLookUpModelResponse,
           let schemeBrand:CardBrand = binLookUpResponse.scheme?.cardBrand,
           // Then for a co-badge the parent brand (e.g VISA) will be different than the scheme brand (e.g. MADA)
           binLookUpResponse.cardBrand != schemeBrand,
           // Let us get the payment options supporting both parent and co-badge
           let paymentOptionForParentCardBrand:PaymentOption = fetchPaymentOption(with: binLookUpResponse.cardBrand),
           let paymentOptionForCoBadgeBrand:PaymentOption = fetchPaymentOption(with: schemeBrand) {
            return(true,paymentOptionForParentCardBrand,paymentOptionForCoBadgeBrand)
        }
        return (false,nil,nil)
    }
    
    /// The method checks all conditions that will lead for displaying a currency widget related to the card data or not
    /// - Parameter selectedPaymentOption: The payment option we want to know if shall show a currency widget for or not
    /// - Returns: True, means it will be displayed. False, otherwise.
    func willShowCurrencyWidgetForPaymentChip(selectedPaymentOption:PaymentOption?) -> Bool {
        /// Currency payment chip widget won't be displayed unless selected payment option is a redirection one
        guard let selectedPaymentOption = selectedPaymentOption else { return false }
        let isSelectedOptionWeb:Bool = selectedPaymentOption.paymentType == .Web
        
        // Currency card widget won't be displayed if the last time, the user changed currency from the payement chips and he didn't change the brand or the currency again. For example, if he was in PAYPAL and switched to USD then if he is still on PAYPAL and USD we shouldn't ask him again
        let userChangedWithThisOptionAndCurrency:Bool = (lastConfirmedCurrencyWidget?.paymentOption.identifier == selectedPaymentOption.identifier && lastConfirmedCurrencyWidget?.selectedAmountCurrency?.currency == dataHolder.transactionData.transactionUserCurrencyValue.currency)
        
        // We only display the widget if the currency is not the same as the selected currency if it is an enabled payment chip
        let isPaymentOptionEnabled:Bool = isPaymentOptionEnabled(in: selectedPaymentOption)
        let userCurrencyMatchesTransactionCurrency:Bool = dataHolder.transactionData.transactionCurrencyValue.currency == dataHolder.transactionData.transactionUserCurrencyValue.currency
        
        return isSelectedOptionWeb && !userChangedWithThisOptionAndCurrency && !(userCurrencyMatchesTransactionCurrency && isPaymentOptionEnabled)
    }
    
    /// Decides whether or not a currency widget should be displayed based on meeting all the requiremenets of this payment option type
    /// - Parameter for selectedPaymentOption: The payment option in concern we need to show a currency widget when it is activated
    /// - Parameter and type: The type of this payment option whether it's card or chips based
    /// - Returns: True, if the payment option passes all the requirements needed to show a currency widget for his specified type
    func shouldShowCurrencyWidget(for selectedPaymentOption:PaymentOption?,and type: CurrencyWidgetPositionEnum) -> Bool {
        return (type == .Card) ? willShowCurrencyWidgetForCard(selectedPaymentOption: selectedPaymentOption) : willShowCurrencyWidgetForPaymentChip(selectedPaymentOption: selectedPaymentOption)
    }
    
    /**
     Handles the logic needed to be applied upon card form validation status changes regrding the loyalty widget
     - Parameter cardBrand: The detected card brand
     - Parameter with validation: The validation status came out of the card validator
     */
    /*func handleCustomerContact(with validation: CrardInputTextFieldStatusEnum) {
        // Check of we can display loyalty section or not
        if canShowCustomerContactData(),
           let nonCustomerContactViewModel: CustomerContactDataCollectionViewModel = dataHolder.viewModels.customerDataViewModel,
           let nonCustomerShippingViewModel: CustomerShippingDataCollectionViewModel = dataHolder.viewModels.customerShippingViewModel{
            //updateLoyaltySection()
            // Now let us show the loyalty section after a slight delay allowing the keyboard to be dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250), execute: { [weak self] in
                self?.UIDelegate?.showCustomerContactDataCollection(with: nonCustomerContactViewModel, and: nonCustomerShippingViewModel, animate: true)
            })
        }else{
            // Then if no valid card data is provided, all what we need to do is to remove the loyalty section if any
            UIDelegate?.hideCustomerContactDataCollection()
        }
    }*/
    
    /**
     Handles the logic needed to be applied upon card form validation status changes regrding the loyalty widget
     - Parameter cardBrand: The detected card brand
     - Parameter with validation: The validation status came out of the card validator
     */
    /*func handleLoyalty(for cardBrand: CardBrand,with validation: CrardInputTextFieldStatusEnum) {
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
    }*/
    
    
    /// Checks all the conditoins to show a customer contact data collection section including
    /*func canShowCustomerContactData() -> Bool {
        // Check if the card's data including number, CVV and expiry are valid
        guard dataHolder.viewModels.tapCardTelecomPaymentViewModel.allCardFieldsValid(),
              // Check if the user activated saving for TAP
              dataHolder.viewModels.tapCardTelecomPaymentViewModel.isTapSaveAllowed,
              // Check if there is a data needed to be collected
              let _: CustomerContactDataCollectionViewModel = dataHolder.viewModels.customerDataViewModel,
              let _: CustomerShippingDataCollectionViewModel = dataHolder.viewModels.customerShippingViewModel
        else {
            return false
        }
        
        return true
    }*/
    
    /// Checks all the conditoins to show a loyalty section including
    /// There is a loyalty model, card data is fully valid, used currency is supported by the loyalty model
    /*func canShowLoyalty() -> Bool {
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
    }*/
    
    
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
