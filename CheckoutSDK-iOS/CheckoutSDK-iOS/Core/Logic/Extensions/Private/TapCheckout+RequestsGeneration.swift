//
//  TapCheckoutManager+RequestsGeneration.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/18/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// Used to do logic for creating the api requests models
extension TapCheckout {
    
    /**
     Creates the payment option api request
     - Returns:The payment option api request
     */
    func createPaymentOptionRequestModel() -> TapPaymentOptionsRequestModel {
        let transactionData:TransactionDataHolder = dataHolder.transactionData
        // Based on the transaction mode we decide the data we pass to the API
        if transactionData.transactionMode == .cardSaving {
            return TapPaymentOptionsRequestModel(customer: transactionData.customer)
        }else{
            return TapPaymentOptionsRequestModel(transactionMode: transactionData.transactionMode, amount: transactionData.transactionTotalAmountValue, items: transactionData.transactionItemsValue, shipping: transactionData.shipping, taxes: transactionData.taxes, currency: transactionData.transactionCurrencyValue.currency, merchantID: transactionData.tapMerchantID, customer: transactionData.customer, destinationGroup: DestinationGroup(destinations: transactionData.destinations), paymentType: transactionData.paymentType)
        }
    }
    
    /**
     Create a card verification api request
     - Parameter for token: The token generated from the previous step which is tokenizing the card
     - Returns: The Card verification api request model
     */
    func createCardVerificationRequestModel(for token:Token) -> TapCreateCardVerificationRequestModel? {
        
        let requires3DSecure    = shouldForce3DS() || dataHolder.transactionData.require3DSecure
        let shouldSaveCard      = true
        let metadata            = dataHolder.transactionData.paymentMetadata
        let source              = SourceRequest(token: token)
        let redirect            = TrackingURL(url: WebPaymentHandlerConstants.returnURL)
        let currency            = dataHolder.transactionData.transactionUserCurrencyValue.currency
        let customer            = dataHolder.transactionData.customer
        
        
        return TapCreateCardVerificationRequestModel                    (is3DSecureRequired:    requires3DSecure,
                                                                        shouldSaveCard:         shouldSaveCard,
                                                                        metadata:               metadata,
                                                                        customer:               customer,
                                                                        currency:               currency,
                                                                        source:                 source,
                                                                        redirect:               redirect)
        
        
    }
    
    
    /**
     Create a verify OTP authentication request
     - Parameter for authentication: Theauthentication object
     - Parameter value: The value that we need to verify
     - Returns: The otp authentication verification api request model
     */
    func createOTPAuthenticationRequest(for authentication:Authentication,and value:String) -> TapAuthenticationRequest? {
        
        let authenticationType  = authentication.type
        
        return TapAuthenticationRequest (type: authenticationType,
                                         value: value)
    }
    
    
    /**
     Create a card token api request
     - Parameter for card: The card we need to generate a token for
     - Parameter address: The address attached to the card if any
     - Returns: The Card create token api request model
     */
    func createCardTokenRequestModel(for card:TapCard,address:Address? = nil) -> TapCreateTokenRequest? {
        do{
            return TapCreateTokenWithCardDataRequest(card: try .init(card: card, address: address))
        }catch{
            handleError(error: error)
        }
        return nil
    }
    
    
    /**
     Create a card token api request
     - Parameter for applePayToken: The native iOS Apple Pay token
     - Returns: The Tokenize apple pay token api request model
     */
    func createApplePayTokenRequestModel(for applePayToken:TapApplePayToken) -> TapCreateTokenRequest? {
        do {
            return TapCreateTokenWithApplePayRequest.init(appleToken: try TapApplePayTokenModel.init(dictionary: applePayToken.jsonAppleToken))
        }catch{
            return nil
        }
    }
    
    
    /**
     Create a saved card token api request
     - Parameter for card: The saved card we need to generate a token for
     - Returns: The Saved Card create token api request model
     */
    func createSavedCardTokenRequestModel(for card:SavedCard) -> TapCreateTokenRequest? {
        // double check, make sure all the data we need are correctly stored and set. Card ID and Customer ID
        guard let savedCardID = card.identifier else {
            handleError(error: "Unexpected error, tokenizing a saved card but cannot find the saved card id")
            return nil
        }
        guard let customerID = dataHolder.transactionData.customer.identifier else {
            handleError(error: "Unexpected error, tokenizing a saved card but cannot find the customer id")
            return nil
        }
        
        // All good, we can now safely create the saved card token request
        return TapCreateTokenWithSavedCardRequest(savedCard: .init(cardIdentifier: savedCardID, customerIdentifier: customerID))
    }
    
    /**
     Creates a charge or authorize api request model
     - Parameter paymentOption: The payment option the user selected
     - Parameter token: The token fromt the card tokenization api
     - Parameter cardBin: The card bin from card info api
     - Parameter saveCard: Used to indicate whether we should activate the save card or not
     */
    func createChargeOrAuthorizeRequestModel (with paymentOption:              PaymentOption,
                                             token:                            Token?,
                                             cardBIN:                          String?,
                                             saveCard:                         Bool? = false) -> TapChargeRequestModel {
        let transactionData:TransactionDataHolder = dataHolder.transactionData
        // Create the source request
        // Decide the source id whether to come from the payment option or from the provided token
        var sourceIdentifier:String = ""
        if let token = token?.identifier {
            sourceIdentifier = token
        }else if let sourceID = paymentOption.sourceIdentifier {
            sourceIdentifier = sourceID
        }else{
            fatalError("No payment source identifier")
        }
        
        let source = SourceRequest(identifier: sourceIdentifier)
        
        // Create the essential data
        
        guard let orderID     = dataHolder.transactionData.paymentOptionsModelResponse?.orderIdentifier else { fatalError("This case should never happen.") }
        
        var post: TrackingURL? = nil
        if let postURL = transactionData.postURL {
            post = TrackingURL(url: postURL)
        }
        
        // the Amounted Currency assigned by the merchant
        let amountedCurrency    =  transactionData.transactionCurrencyValue
        // the Amounted Currency selected by the user
        let amountedSelectedCurrency = transactionData.transactionUserCurrencyValue
        
        let fee                 = calculateExtraFees(for: paymentOption)
        /// the API is using destinationsGroup not destinations
        let destinationsGroup   = (transactionData.destinations?.count ?? 0 > 0) ? DestinationGroup(destinations: transactionData.destinations)!: nil
        
        let order                   = Order(identifier: orderID)
        let redirect                = TrackingURL(url: WebPaymentHandlerConstants.returnURL)
        var shouldSaveCard          = saveCard ?? false
        var requires3DSecure        = transactionData.require3DSecure || shouldForce3DS()
        
        switch paymentOption.threeDLevel {
        case .always:
            requires3DSecure = true
            break
        case .never:
            requires3DSecure = false
            break
        default:
            break
        }
        
        var canSaveCard: Bool
        if let nonnullToken = token, self.shouldSaveCard(with: nonnullToken) {
            canSaveCard = true
        }
        else {
            canSaveCard = false
        }
        
        if !canSaveCard {
            shouldSaveCard = false
        }
        
        
        switch transactionData.transactionMode {
        
        case .purchase:
            
            return TapChargeRequestModel            (amount:                    amountedCurrency.amount,
                                                    selectedAmount:             amountedSelectedCurrency.amount,
                                                    currency:                   amountedCurrency.currency,
                                                    selectedCurrency:           amountedSelectedCurrency.currency,
                                                    customer:                   transactionData.customer,
                                                    merchant:                   dataHolder.transactionData.intitModelResponse?.data.merchant,
                                                    fee:                        fee,
                                                    order:                      order,
                                                    redirect:                   redirect,
                                                    post:                       post,
                                                    source:                     source,
                                                    destinationGroup:           destinationsGroup,
                                                    descriptionText:            transactionData.paymentDescription,
                                                    metadata:                   transactionData.paymentMetadata,
                                                    reference:                  transactionData.paymentReference,
                                                    shouldSaveCard:             shouldSaveCard,
                                                    statementDescriptor:        transactionData.paymentStatementDescriptor,
                                                    requires3DSecure:           requires3DSecure,
                                                    receipt:                    transactionData.receiptSettings)
        case .authorizeCapture:
            //let authorizeAction = dataSource.authorizeAction ?? .default
            
            return TapAuthorizeRequestModel (amount:                     amountedCurrency.amount,
                                             selectedAmount:             amountedSelectedCurrency.amount,
                                             currency:                   amountedCurrency.currency,
                                             selectedCurrency:           amountedSelectedCurrency.currency,
                                             customer:                   transactionData.customer,
                                             merchant:                   dataHolder.transactionData.intitModelResponse?.data.merchant,
                                             fee:                        fee,
                                             order:                      order,
                                             redirect:                   redirect,
                                             post:                       post,
                                             source:                     source,
                                             destinationGroup:           destinationsGroup,
                                             descriptionText:            transactionData.paymentDescription,
                                             metadata:                   transactionData.paymentMetadata,
                                             reference:                  transactionData.paymentReference,
                                             shouldSaveCard:             shouldSaveCard,
                                             statementDescriptor:        transactionData.paymentStatementDescriptor,
                                             requires3DSecure:           requires3DSecure,
                                             receipt:                    transactionData.receiptSettings,
                                             authorizeAction:            transactionData.authorizeAction)
            
        case .cardSaving:
            fatalError("This case should never happen.")
        case .cardTokenization:
            fatalError("This case should never happen.")
        }
    }
    
    
    
}
