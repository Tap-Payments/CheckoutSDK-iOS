//
//  TapCheckoutManager+Utils.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/17/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import CommonDataModelsKit_iOS
import TapCardVlidatorKit_iOS
import CoreTelephony
/// A collection of logic to provide utils and singleton interfaces for multiple required methods
internal extension TapCheckout {
    
    /**
     Gets the related payment option for a saved card
     - Parameter for: The saved card of the needed payment option
     - Returns: Payment option if found with the specified saved card, else nil
     */
    func fetchPaymentOption(for savedCard:SavedCard) -> PaymentOption? {
        guard let paymentOptionsResponse = dataHolder.transactionData.paymentOptionsModelResponse, let paymentOptionIdentifier = savedCard.paymentOptionIdentifier else { return nil }
        return paymentOptionsResponse.fetchPaymentOption(with: paymentOptionIdentifier)
    }
    
    
    /**
     Gets the related payment option by id
     - Parameter with: The id of the needed payment option
     - Returns: Payment option if found with the specified id, else nil
     */
    func fetchPaymentOption(with paymentOptionIdentifier:String) -> PaymentOption? {
        guard let paymentOptionsResponse = dataHolder.transactionData.paymentOptionsModelResponse, let paymentOption:PaymentOption = paymentOptionsResponse.paymentOptions.filter({ $0.identifier == paymentOptionIdentifier }).first else { return nil }
        return paymentOption
    }
    
    
    /**
     Gets the related payment option by supporting a certain card brand
     - Parameter with: The card brand you are looking for
     - Returns: Payment option if found with the specified card brand, else nil
     */
    func fetchPaymentOption(with cardBrand:CardBrand) -> PaymentOption? {
        return dataHolder.viewModels.tapCardPhoneListDataSource.filter{ $0.tapPaymentOption?.brand == cardBrand }.filter{ $0.tapPaymentOption != nil }.map{ $0.tapPaymentOption! }.first
    }
    
    /**
     Gets the list of amounted currencies supported by this payment option.
     - Parameter for paymentOption: The payment option you want to know what are the amounted currencies attached to it
    - returns: List of amounted currencies which are supported by the provided payment option. Default is empty
     */
    func fetchAmountedCurrencies(for paymentOption:PaymentOption, with maxLimit:Int = 3) -> [AmountedCurrency] {
        guard let supportedCurrencies:[AmountedCurrency] = dataHolder.transactionData.paymentOptionsModelResponse?.supportedCurrenciesAmounts else {
            // This means for some reaso, this method is alled without firstly calling the api to get all the supported currencies
            return []
        }
        
        // now let us filter the backend amounted currencies to fetch only the ones supported by the provided pament option
        return Array(supportedCurrencies.filter { amountedCurrency in
            return paymentOption.supportedCurrencies.contains(where: { $0 == amountedCurrency.currency }) }.prefix(maxLimit))
        
    }
    
    
    /**
     Gets the related saved card by id
     - Parameter with: The id of the needed saved card
     - Returns: Saved Card  if found with the specified id, else nil
     */
    func fetchSavedCardOption(with savedCardID:String) -> SavedCard? {
        guard let paymentOptionsResponse = dataHolder.transactionData.paymentOptionsModelResponse, let savedCardOption:SavedCard = paymentOptionsResponse.savedCards?.filter({ $0.identifier == savedCardID }).first else { return nil }
        return savedCardOption
    }
    
    /**
     Gets the transaction total amount for a given currency
     - Parameter for: The currency you want to know the total amount regards
     - Returns: The total amount for the currency as stated in the payment options api response
     */
    func fetchTotalAmount(for currency:TapCurrencyCode) -> Double {
        guard let paymentOptionsResponse = dataHolder.transactionData.paymentOptionsModelResponse else { return 0 }
        
        // get the amounted currency related to tthe tap currency code model
        let filteredCurrenciesList = paymentOptionsResponse.supportedCurrenciesAmounts.filter{ $0.currency == currency }
        guard !filteredCurrenciesList.isEmpty, let amount = filteredCurrenciesList.first?.amount  else { return 0 }
        
        return amount
    }
    
    /**
     Used to fetch the authorization object stored in the current charge or authorization
     - Parameter with authenticationID: The authentication ID we are looking for
     - Returns: Tthe authorization object stored in the current charge or authorization
     */
    func fetchAuthentication(with authenticationID:String) -> Authentication? {
        // Check if we have a charge or authorize response
        if let charge = dataHolder.transactionData.currentCharge {
            // Check if charge object then we try to match the charge id
            guard let authentication = charge.authentication,
                  authentication.identifier == authenticationID else { return nil }
            return authentication
        }else if let authorization = dataHolder.transactionData.currentAuthorize {
            // Check if authorization object then we try to match the authentication id
            guard let authentication = authorization.authentication,
                  authentication.identifier == authenticationID else { return nil }
            return authentication
        }
        return nil
    }
    
    
    /**
     Determines if the checkout process can save card regarding the attributes of the transaction
     - Parameter with token: The token card we need to check allowed to save or not
     - Returns: true if the merchant is allowed to save card && (card was not saved before || ( savedBefore && allowedToSaveMoreOnce ))
     */
    func shouldSaveCard(with token: Token) -> Bool {
        // First check if merchant is allowed to save cards
        guard let permissions = dataHolder.transactionData.intitModelResponse?.data.permissions,
              permissions.contains(.merchantCheckout) else { return false }
        // Check if it is already saved before and if the merchant stated it is allowed for a customer to save the card multiple times
        let existingCardFingerprints = dataHolder.transactionData.paymentOptionsModelResponse?.savedCards?.compactMap { $0.fingerprint }.filter { $0.tap_length > 0 } ?? []
        if !existingCardFingerprints.contains(token.card.fingerprint) {
            // The card is not saved before, hence we can save this card
            return true
        }
        // Otherwise based on the value the merchant stated
        return dataHolder.transactionData.allowsToSaveSameCardMoreThanOnce
    }
    
    /**
     Indicates whether 3ds should be always forced based on the permissions allowed to the merchant from TAP Payments.
     - Returns: True if the merchant is not allowed to override 3ds, false otherwise.
     */
    func shouldForce3DS() -> Bool {
        
        guard let permissions = dataHolder.transactionData.intitModelResponse?.data.permissions,
              permissions.contains(.non3DSecureTransactions) else { return true }
        
        return false
    }
    
    /**
     Fetches the supported card brands for the currently selected currency
     - Returns: the supported card brands for the currently selected currency or empty as default
     */
    func fetchSupportedCardBrands() -> [CardBrand] {
        // Make sure we have a payment option response first
        guard let paymentOptionsResponse = dataHolder.transactionData.paymentOptionsModelResponse else { return [] }
        // Get the card payment options with the selected currency object from the payment option response
        let supportedPaymentOptions = paymentOptionsResponse.paymentOptions.filter { (paymentOption) -> Bool in
            return paymentOption.paymentType == .Card && paymentOption.supportedCurrencies.contains(dataHolder.transactionData.transactionUserCurrencyValue.currency)
        }
        // Return now all the brands that supports the selected currency
        return supportedPaymentOptions.map{ $0.brand }
    }
    
    /// Detect the country code based on SIM network first/
    func detectSimCountryCode() -> String? {
        let networkInfo = CTTelephonyNetworkInfo()
        let providers = networkInfo.serviceSubscriberCellularProviders
        var simCountryISO:String? = "EG"
        if let nonNullSimCountryIso:String = providers?.values.first(where: {$0.isoCountryCode != nil})?.isoCountryCode {
            simCountryISO = nonNullSimCountryIso
        }
        return simCountryISO
    }
    
    /// Detect the local currency of the user
    func detectSimCurrencyCode() -> TapCurrencyCode {
        guard let nonNullCountryCode:String = detectSimCountryCode()?.uppercased(),
              let nonNullCurrencyCode:String = Locale.currency[nonNullCountryCode] ?? "",
              let tapCurrency:TapCurrencyCode = .init(appleRawValue: nonNullCurrencyCode),
              tapCurrency != .undefined else { return TapCurrencyCode.undefined }
        return tapCurrency
    }
}
