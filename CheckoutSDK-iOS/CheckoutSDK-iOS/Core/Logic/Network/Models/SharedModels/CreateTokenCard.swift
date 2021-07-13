//
//  CreateTokenCard.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/2/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
/// Model that holds card details required for token creation.
internal struct CreateTokenCard {
    
    // MARK: - Internal -
    // MARK: Properties
    
    /// Card address.
    internal private(set) var address: Address?
    /// The card data encrypted
    private let sensitiveCardData: SensitiveCardData
    
    // MARK: Methods
    
    internal init(number: String, expirationMonth: String, expirationYear: String, cvc: String, cardholderName: String, address: Address?) {
        
        self.sensitiveCardData = SensitiveCardData(number: number, month: expirationMonth, year: expirationYear, cvv: cvc, name: cardholderName)
        self.address = address
    }
    
    /// Create TokenedCardRequest from the TapCardModel
    internal init(card:TapCard, address:Address?) throws {
        
        guard let number = card.tapCardNumber, let expirationMonth = card.tapCardExpiryMonth, let expirationYear = card.tapCardExpiryYear, let cvv = card.tapCardCVV else {
            throw "Cannot create a sensitive card without card info"
        }
        
        self.sensitiveCardData = SensitiveCardData(number: number, month: expirationMonth, year: expirationYear, cvv: cvv, name: card.tapCardName ?? "DEFAULT CARD NAME")
        self.address = address
    }
    
    private enum CodingKeys: String, CodingKey {
        
        case sensitiveCardData  = "crypted_data"
        case address            = "address"
    }
}


// MARK: - Fileprivate -
/// A struct that transforms the card details into an encrypted data to be shared securley over the network
fileprivate struct SensitiveCardData: SecureEncodable {
    /**
     Init the encrypter
     - parameter number:    The card number
     - parameter month:     The card expiry month
     - parameter year:      The card expiry year
     - parameter cvv:       The card secure digits
     - parameter name:      The card's holder name
     */
    fileprivate init(number: String, month: String, year: String, cvv: String, name: String) {
        
        self.number = number
        self.expirationMonth = month
        self.expirationYear = year
        self.ccv = cvv
        self.cardholderName = name
    }
    /// The card number
    private let number: String
    /// The card expiry month
    private let expirationMonth: String
    /// The card expiry year
    private let expirationYear: String
    /// The card secure digits
    private let ccv: String
    /// The card's holder name
    private let cardholderName: String
    
    private enum CodingKeys: String, CodingKey {
        
        case number             = "number"
        case expirationMonth    = "exp_month"
        case expirationYear     = "exp_year"
        case ccv                = "cvc"
        case cardholderName     = "name"
    }
}

// MARK: - Encodable
extension CreateTokenCard: Encodable {
    
    /// Encodes the contents of the receiver.
    ///
    /// - Parameter encoder: Encoder.
    /// - Throws: EncodingError
    internal func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode            (try self.sensitiveCardData.secureEncoded(),    forKey: .sensitiveCardData)
        try container.encodeIfPresent   (self.address,                                  forKey: .address)
    }
}
