//
//  TapCheckoutManager+PaymentProcesses.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/18/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// Collection of logic to process a payment with different flows
internal extension TapCheckout {
    
    // MARK:- General methods for all modes
    /**
     Used to process a checkout process with a given payment option
     - Parameter with paymentOption: The payment option to start the checkout process with
     - Parameter andCard: The card associated with the payment option if any
     - Parameter andApplePayToken: The tap apple pay token associated with the payment option if any
     */
    func processCheckout(with paymentOption:PaymentOption,andCard:TapCard? = nil,andApplePayToken:TapApplePayToken? = nil) {
        // For all payment options types, we need to ask for extra fees first if any
        askForExtraFees(with: paymentOption) { [weak self] in
            guard let nonNullSelf = self else { return }
            nonNullSelf.startPayment(with: paymentOption, andCard: andCard, andApplePayToken: andApplePayToken)
        }
    }
    
    /**
     Used to call the correct checkout logic based on the selected payment option
     - Parameter with paymentOption: The payment option to start the checkout process with
     - Parameter andCard: The card associated with the payment option if any
     - Parameter andApplePayToken: The tap apple pay token associated with the payment option if any
     */
    func startPayment(with paymentOption:PaymentOption,andCard:TapCard?,andApplePayToken:TapApplePayToken? = nil) {
        // Based on the payment option type, we need to follow the corresponding logic flow
        switch paymentOption.paymentType {
        case .Web:
            startWebPayment(with: paymentOption)
        case .Card:
            startCardPayment(with: paymentOption, and: andCard)
        case .SavedCard:
            startSavedCardPayment(with: paymentOption)
        case .ApplePay,.Device:
            startApplePayPayment(with: paymentOption, and: andApplePayToken)
        default:
            return
        }
    }
    
    // MARK:- Redirection based methods
    /**
     Used to call the correct checkout logic for the web based payment options
     - Parameter with paymentOption: The payment option to start the checkout process with
     */
    func startWebPayment(with paymentOption:PaymentOption) {
        // Change the action button to loading status
        TapCheckout.sharedCheckoutManager().dataHolder.viewModels.tapActionButtonViewModel.startLoading()
        // Create the charge request and call it
        let chargeRequest:TapChargeRequestModel = createChargeOrAuthorizeRequestModel(with: paymentOption, token: nil, cardBIN: nil)
        callChargeOrAuthorizeAPI(chargeRequestModel: chargeRequest) { [weak self] charge in
            DispatchQueue.main.async{
                // Process the charge protocol response we got from the server
                guard let nonNullSelf = self else { return }
                nonNullSelf.handleCharge(with: charge)
            }
        } onErrorOccured: { [weak self] error in
            self?.handleError(error: error)
        }

    }
    
    // MARK:- Card based methods
    /**
     Used to call the correct checkout logic for the web based payment options
     - Parameter with paymentOption: The payment option to start the checkout process with
     - Parameter and card: The card object to be used in the transaction.
     */
    func startCardPayment(with paymentOption:PaymentOption? = nil,and card:TapCard? = nil) {
        // Make sure we have a card info entered already and ready to use
        guard let _:TapBinResponseModel = dataHolder.transactionData.binLookUpModelResponse,
              let currentCard:TapCard = card else {
            handleError(error: "UnExpected error, paying with a card while missing card data or binlookup data")
            return
        }
        // Change the action button to loading status
        TapCheckout.sharedCheckoutManager().dataHolder.viewModels.tapActionButtonViewModel.startLoading()
        
        // Create a card tokenization api to start with and call it
        guard let createCardTokenRequest:TapCreateTokenRequest = createCardTokenRequestModel(for: currentCard) else { return }
        callCardTokenAPI(cardTokenRequestModel: createCardTokenRequest) { (token) in
            DispatchQueue.main.async{ [weak self] in
                // Process the token we got from the server
                guard let nonNullSelf = self else { return }
                nonNullSelf.handleToken(with: token,for: paymentOption)
            }
        } onErrorOccured: { [weak self] (error) in
            self?.handleError(error: error)
        }
    }
    // MARK:- Token based methods
    /**
     Handles the token response to see what should be the next action
     - Parameter with token: The token response we want to analyse and decide the next action based on it
     */
    func handleToken(with token:Token,for paymentOption:PaymentOption? = nil) {
        // Save the object for further processing
        dataHolder.transactionData.currentToken = token
        // Now based on the mode we need to decide what to do with this token
        switch dataHolder.transactionData.transactionMode {
        case .purchase,.authorizeCapture:
            handleTokenCharge(with: token,for: paymentOption)
        case .cardTokenization:
            handleTokenTokenize(with: token,for: paymentOption)
        case .cardSaving:
            handleTokenCardSave(with: token,for: paymentOption)
        default:
            return
        }
    }
    
    
    
    
    /**
     Performs the logic post tokenizing a card in a save card mode
     - Parameter with token: The token response we want to analyse and decide the next action based on it
     */
    func handleTokenCardSave(with token:Token,for paymentOption:PaymentOption? = nil) {
        // Let us first check if this card can be saved
        guard shouldSaveCard(with: token) else {
            handleError(error: "Whether you don't have permission to save cards at your side so please contact TAP Payments. Or the customer already has this card saved before.")
            return
        }
        
        // If all good we need to make a call to card verify api
        guard let cardVerifyRequest:TapCreateCardVerificationRequestModel = createCardVerificationRequestModel(for: token) else {
            handleError(error: "Failed while creating TapCreateCardVerificationRequestModel")
            return
        }
        
        // Let us hit the card verify api
        callCardVerifyAPI(cardVerifyRequestModel: cardVerifyRequest) { [weak self] cardVerifyResponse in
            DispatchQueue.main.async{
                // Process the card verify response we got from the server
                guard let nonNullSelf = self else { return }
                nonNullSelf.handleCardVerify(with: cardVerifyResponse)
            }
        } onErrorOccured: { [weak self] error in
            self?.handleError(error: error)
        }
    }
    
    /**
     Performs the logic post tokenizing a card in a token mode
     - Parameter with token: The token response we want to analyse and decide the next action based on it
     */
    func handleTokenTokenize(with token:Token,for paymentOption:PaymentOption? = nil) {
        // Let us inform the caller app that the tokenization had been done successfully
        tapCheckoutScreenDelegate?.cardTokenized?(with: token)
        // Now it is time to safely dismiss ourselves showing a green tick :)
        dismissCheckout(with: true)
    }
    
    
    /**
     Performs a charge after tokenizing the card
     - Parameter with token: The token response we want to analyse and decide the next action based on it
     */
    func handleTokenCharge(with token:Token,for paymentOption:PaymentOption? = nil) {
        // Change the action button to loading status
        TapCheckout.sharedCheckoutManager().dataHolder.viewModels.tapActionButtonViewModel.startLoading()
        // Create the charge request and call it
        let chargeRequest:TapChargeRequestModel = createChargeOrAuthorizeRequestModel(with: paymentOption!, token: token, cardBIN: token.card.binNumber,saveCard: dataHolder.transactionData.isSaveCardMerchantActivated)
        callChargeOrAuthorizeAPI(chargeRequestModel: chargeRequest) { [weak self] charge in
            DispatchQueue.main.async{
                // Process the charge protocol response we got from the server
                guard let nonNullSelf = self else { return }
                nonNullSelf.handleCharge(with: charge)
            }
        } onErrorOccured: { [weak self] error in
            self?.handleError(error: error)
        }
    }
    
    // MARK:- Authourize and Charge based methods
    /**
     Handles the charge response to see what should be the next action
     - Parameter with charge: The charge response we want to analyse and decide the next action based on it
     */
    func handleCharge(with chargeOrAuthorize:ChargeProtocol?) {
        // Save the object for further processing
        if chargeOrAuthorize is Charge {
            dataHolder.transactionData.currentCharge = chargeOrAuthorize as? Charge
        }else if chargeOrAuthorize is Authorize {
            dataHolder.transactionData.currentAuthorize = chargeOrAuthorize as? Authorize
        }
        
        // Based on the status we will know what to do
        let chargeStatus = chargeOrAuthorize?.status
        switch chargeStatus {
        case .captured:
            handleCaptured(for:chargeOrAuthorize)
            break
        case .authorized:
            handleCaptured(for:chargeOrAuthorize)
            break
        case .failed,.declined:
            handleFailed(for:chargeOrAuthorize)
            break
        case .initiated,.inProgress:
            handleInitated(for:chargeOrAuthorize)
            break
        default:
            handleCancelled(for:chargeOrAuthorize)
        }
    }
    
    
    /**
     Will be called once the charge response shows that, the charge has been successfully captured.
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleCaptured(for charge:ChargeProtocol?) {
        // First let us inform the caller app that the charge/authorization had been done successfully
        if let charge:Charge = charge as? Charge {
            tapCheckoutScreenDelegate?.checkoutCaptured?(with: charge)
        }else if let authorize:Authorize = charge as? Authorize {
            tapCheckoutScreenDelegate?.checkoutCaptured?(with: authorize)
        }
        // Now it is time to safely dismiss ourselves showing a green tick :)
        dismissCheckout(with: true)
    }
    
    /**
     Will be called once the charge response shows that, the authorize has been successfully captured.
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleAuthorized(for charge:ChargeProtocol?) {
        
    }
    
    /**
     Will be called once the charge response shows that, the charge has hailed
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleFailed(for charge:ChargeProtocol?) {
        // First let us inform the caller app that the charge/authorization had failed
        if let charge:Charge = charge as? Charge {
            tapCheckoutScreenDelegate?.checkoutFailed?(with: charge)
        }else if let authorize:Authorize = charge as? Authorize {
            tapCheckoutScreenDelegate?.checkoutFailed?(with: authorize)
        }
        // Now it is time to safely dismiss ourselves showing a green tick :)
        dismissCheckout(with: false)
    }
    
    /**
     Will be called once the charge response shows that, the charge has been initiated and we need to do more actions to complete it like 3ds
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleInitated(for charge:ChargeProtocol?) {
        // We need to do the logic based on the initiate charge type.
        
        // Case 1: Redirection // Check if we need to make a redirection
        if let redirectionURL:URL = charge?.transactionDetails.url {
            showWebView(with: redirectionURL)
        }
        
        // Case 2: Authentication
        if let authentication:Authentication = charge?.authentication {
            showAuthentication(with: authentication)
        }
    }
    
    /**
     Handles the logic needed to open the webview
     - PArameter with url: The url to be opened
     */
    func showWebView(with url:URL) {
        DispatchQueue.main.async{ [weak self] in
            // Instruct the view to open a web view with the redirection url
            guard let nonNullSelf = self else { return }
            nonNullSelf.UIDelegate?.showWebView(with: url,and: nonNullSelf)
        }
    }
    
    /**
     Will be called once the charge response shows that, the charge has been cancelled
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleCancelled(for charge:ChargeProtocol?) {
        handleFailed(for: charge)
    }
    
    
    // MARK:- Card saving based methods
    /**
     Performs the logic post verifying a card
     - Parameter with cardVerifyResponse: The cardVerifyResponse response we want to analyse and decide the next action based on it
     */
    func handleCardVerify(with cardVerifyResponse:TapCreateCardVerificationResponseModel) {
        // Based in the card verify response we will proceed
        let verifyStatus = cardVerifyResponse.status
        switch verifyStatus {
        case .valid:
            handleCardSaveValid(for:cardVerifyResponse)
            break
        case .invalid:
            handleCardSaveInValid(for:cardVerifyResponse)
            break
        case .initiated:
            handleCardSaveInitiated(for:cardVerifyResponse)
            break
        }
    }
    
    
    /**
     Will be called once the save card response shows that, the saving has been successfully done.
     - Parameter for cardVerifyResponse: The save card object that has all the details
     */
    func handleCardSaveValid(for cardVerifyResponse:TapCreateCardVerificationResponseModel) {
        // First let us inform the caller app that the save card had been done successfully
        tapCheckoutScreenDelegate?.saveCardSuccessfull?(with: cardVerifyResponse)
        // Now it is time to safely dismiss ourselves showing a green tick :)
        dismissCheckout(with: true)
    }
    
    /**
     Will be called once the save card response shows that, the saving has failed.
     - Parameter for cardVerifyResponse: The save card object that has all the details
     */
    func handleCardSaveInValid(for cardVerifyResponse:TapCreateCardVerificationResponseModel) {
        // First let us inform the caller app that the save card had failed
        tapCheckoutScreenDelegate?.saveCardFailed?(with: cardVerifyResponse)
        // Now it is time to safely dismiss ourselves showing a green tick :)
        dismissCheckout(with: false)
    }
    
    /**
     Will be called once the save card response shows that, the saving has started, most probapy it has 3ds.
     - Parameter for cardVerifyResponse: The save card object that has all the details
     */
    func handleCardSaveInitiated(for cardVerifyResponse:TapCreateCardVerificationResponseModel) {
        // Check if we need to make a redirection
        if let redirectionURL:URL = cardVerifyResponse.transactionDetails.url {
            showWebView(with: redirectionURL)
        }
    }
    
    
    // MARK:- Saved Card Methods
    
    
    /**
     Used to call the correct checkout logic for the web based payment options
     - Parameter with paymentOption: The payment option to start the checkout process with
     - Parameter and card: The card object to be used in the transaction.
     */
    func startSavedCardPayment(with paymentOption:PaymentOption? = nil) {
        // Make sure we have the saved card info in place and stored
        guard let paymentOption:PaymentOption = paymentOption,
              let selectedSavedCard:SavedCard = paymentOption.savedCard else {
            handleError(error: "UnExpected error, paying with a saved card while missing saved card data")
            return
        }
        // Change the action button to loading status
        TapCheckout.sharedCheckoutManager().dataHolder.viewModels.tapActionButtonViewModel.startLoading()
        
        // Create a saved card tokenization api to start with and call it
        guard let createSavedCardTokenRequest:TapCreateTokenRequest = createSavedCardTokenRequestModel(for: selectedSavedCard) else {
            handleError(error: "Unexpected error while creating TapCreateTokenRequest")
            return
        }
        
        // Call the token api with the saved card token data
        callCardTokenAPI(cardTokenRequestModel: createSavedCardTokenRequest) { (token) in
            DispatchQueue.main.async{ [weak self] in
                // Process the token we got from the server
                guard let nonNullSelf = self else { return }
                nonNullSelf.handleToken(with: token,for: paymentOption)
            }
        } onErrorOccured: { [weak self] (error) in
            self?.handleError(error: error)
        }
    }
    
    /**
     Handles the logic needed to start an authentication process
     - Parameter with authentication: The authentication type we need to process
     */
    func showAuthentication(with authentication:Authentication) {
        // Based on the authentication type we decide what to do
        switch authentication.type {
        case .otp:
            showOTP(with: authentication)
        default:
            handleError(error: "Unexpected error, cannot handle authentication of type \(authentication.type)")
        }
    }
    
    /**
     Handles the logic needed to start an OTP authentication process
     - Parameter with authentication: The OTP authentication we need to process
     */
    func showOTP(with authentication:Authentication) {
        // Changed the action button to expand and set its state to invalid CONFIRM state
        dataHolder.viewModels.tapActionButtonViewModel.expandButton()
        dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .InvalidConfirm
        
        // Double check the current authentication is of a correct type
        guard authentication.type == .otp else {
            handleError(error: "Unexpected error, non OTP authentication in showOTP method")
            return
        }
        
        // All good we need to start the OTP process
        UIDelegate?.showSavedCardOTPView(with: authentication.identifier)
    }
    
    
    // MARK:- Apple pay related methods

    /**
     Used to call the correct checkout logic for the web based payment options
     - Parameter with paymentOption: The payment option to start the checkout process with
     - Parameter andtapApplePayToken: The tap apple pay token associated with the payment option if any
     */
    func startApplePayPayment(with paymentOption:PaymentOption? = nil, and tapApplePayToken:TapApplePayToken? = nil) {
        // Make sure all needed data are passed correctly
        guard let paymentOption = paymentOption, let tapApplePayToken = tapApplePayToken else {
            handleError(error: "Cannot start apple pay payment without its payment option and the iOS authorization token")
            return
        }
        
        // Change the action button to loading status
        TapCheckout.sharedCheckoutManager().dataHolder.viewModels.tapActionButtonViewModel.startLoading()
        
        // Create an apple pay token tokenization api to start with and call it
        guard let createAppleTokenRequest:TapCreateTokenRequest = createApplePayTokenRequestModel(for: tapApplePayToken) else {
            return
        }
        
        // Call the token api with the apple pay token data
        callCardTokenAPI(cardTokenRequestModel: createAppleTokenRequest) { (token) in
            DispatchQueue.main.async{ [weak self] in
                // Process the token we got from the server
                guard let nonNullSelf = self else { return }
                nonNullSelf.handleToken(with: token,for: paymentOption)
            }
        } onErrorOccured: { [weak self] (error) in
            self?.handleError(error: error)
        }
        
    }
}
