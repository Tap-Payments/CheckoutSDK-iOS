//
//  TapPaymentOptionsReponseModel.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/15/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
/// Payment Options Response model.
internal struct TapPaymentOptionsReponseModel: IdentifiableWithString {
    
    // MARK: - Internal -
    // MARK: Properties
    
    /// Object identifier.
    internal let identifier: String
    
    /// Order identifier.
    internal private(set) var orderIdentifier: String?
    
    /// Object type.
    internal let object: String
    
    /// List of available payment options.
    internal let paymentOptions: [PaymentOption]
    
    /// Transaction currency.
    internal let currency: TapCurrencyCode
    
    /// Merchant iso country code.
    internal let merchantCountryCode: String?
    
    /// Amount for different currencies.
    internal let supportedCurrenciesAmounts: [AmountedCurrency]
    
    /// Saved cards.
    internal var savedCards: [SavedCard]?
    
    // MARK: - Private -
    
    private enum CodingKeys: String, CodingKey {
        
        case currency                   = "currency"
        case identifier                 = "id"
        case object                     = "object"
        case paymentOptions             = "payment_methods"
        case supportedCurrenciesAmounts = "supported_currencies"
        
        case orderIdentifier            = "order_id"
        case savedCards                 = "cards"
        
        case merchantCountryCode        = "country"
    }
    
    // MARK: Methods
    
    private init(identifier:                        String,
                 orderIdentifier:                   String?,
                 object:                            String,
                 paymentOptions:                    [PaymentOption],
                 currency:                          TapCurrencyCode,
                 supportedCurrenciesAmounts:        [AmountedCurrency],
                 savedCards:                        [SavedCard]?,
                 merchantCountryCode:               String?) {
        
        self.identifier                     = identifier
        self.orderIdentifier                = orderIdentifier
        self.object                         = object
        self.paymentOptions                 = paymentOptions
        self.currency                       = currency
        self.supportedCurrenciesAmounts     = supportedCurrenciesAmounts
        self.savedCards                     = savedCards
        self.merchantCountryCode            = merchantCountryCode
    }
}

// MARK: - Decodable
extension TapPaymentOptionsReponseModel: Decodable {
    
    internal init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let identifier                      = try container.decode(String.self, forKey: .identifier)
        let orderIdentifier                 = try container.decodeIfPresent(String.self, forKey: .orderIdentifier)
        let object                          = try container.decode(String.self, forKey: .object)
        var paymentOptions                  = try container.decode([PaymentOption].self, forKey: .paymentOptions)
        let currency                        = try container.decode(TapCurrencyCode.self, forKey: .currency)
        let supportedCurrenciesAmounts      = try container.decode([AmountedCurrency].self, forKey: .supportedCurrenciesAmounts)
        var savedCards                      = try container.decodeIfPresent([SavedCard].self, forKey: .savedCards)
        let merchantCountryCode             = try container.decodeIfPresent(String.self, forKey: .merchantCountryCode)
        
        
        paymentOptions = paymentOptions.filter { ($0.brand != .unknown || $0.paymentType == .ApplePay) }
        
        
        // Filter saved cards based on allowed card types passed by the user when loading the SDK session
        let merchnantAllowedCards = TapCheckoutSharedManager.sharedCheckoutManager().allowedCardTypes
        savedCards = savedCards?.filter { (merchnantAllowedCards.contains($0.cardType ?? CardType(cardType: .All))) }
        
        self.init(identifier:                    identifier,
                  orderIdentifier:                orderIdentifier,
                  object:                        object,
                  paymentOptions:                paymentOptions,
                  currency:                        currency,
                  supportedCurrenciesAmounts:    supportedCurrenciesAmounts,
                  savedCards:                    savedCards,
                  merchantCountryCode:          merchantCountryCode)
    }
}
