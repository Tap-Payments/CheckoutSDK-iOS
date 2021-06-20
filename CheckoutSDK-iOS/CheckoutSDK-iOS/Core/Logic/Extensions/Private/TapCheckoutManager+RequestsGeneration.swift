//
//  TapCheckoutManager+RequestsGeneration.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/18/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// Used to do logic for creating the api requests models
extension TapCheckoutSharedManager {
    
    /**
     Creates the payment option api request
     - Returns:The payment option api request
     */
    func createPaymentOptionRequestModel() -> TapPaymentOptionsRequestModel {
        let transactionData:TransactionDataHolder = dataHolder.transactionData
        return TapPaymentOptionsRequestModel(transactionMode: transactionData.transactionMode, amount: transactionData.transactionTotalAmountValue, items: transactionData.transactionItemsValue, shipping: transactionData.shipping, taxes: transactionData.taxes, currency: transactionData.transactionCurrencyValue.currency, merchantID: transactionData.tapMerchantID, customer: transactionData.customer, destinationGroup: DestinationGroup(destinations: transactionData.destinations), paymentType: transactionData.paymentType)
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
        guard let sourceIdentifier = paymentOption.sourceIdentifier else { fatalError("No payment source identifier") }
        let source = SourceRequest(identifier: sourceIdentifier)
        
        // Create the essential data
        //guard let orderID     = paymentOptionsModelResponse?.orderIdentifier else { fatalError("This case should never happen.") }
        let orderID = "ord_TS040120212018Dm431906670"
        
        var post: TrackingURL? = nil
        if let postURL = transactionData.postURL {
            post = TrackingURL(url: postURL)
        }
        
        // the Amounted Currency assigned by the merchant
        var totalAmount:Double = calculateFinalAmount()
        if totalAmount == 0
        {
            totalAmount = transactionData.transactionCurrencyValue.amount
        }
        let amountedCurrency    =  transactionData.transactionCurrencyValue
        // the Amounted Currency selected by the user
        let amountedSelectedCurrency = transactionData.transactionUserCurrencyValue
        
        let fee                 = calculateExtraFees(for: paymentOption)
        /// the API is using destinationsGroup not destinations
        let destinationsGroup   = (transactionData.destinations?.count ?? 0 > 0) ? DestinationGroup(destinations: transactionData.destinations)!: nil
        
        let order                   = Order(identifier: orderID)
        let redirect                = TrackingURL(url: WebPaymentHandlerConstants.returnURL)
        var shouldSaveCard          = saveCard ?? false
        var requires3DSecure        = transactionData.require3DSecure
        
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
            fatalError("This case should never happen.")
        case .cardSaving:
            fatalError("This case should never happen.")
        case .cardTokenization:
            fatalError("This case should never happen.")
        }
    }
    
}
