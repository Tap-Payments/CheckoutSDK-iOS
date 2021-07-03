//
//  TapCreateTokenRequest.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/2/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation


/// A protocol to be implemented by all create token requests, we have till now three different token modes for card, saved card and apple pay token.
internal protocol CreateTokenRequest: Encodable {
    
    var route: TapNetworkPath { get }
}

/// Request model for token creation with card data.
internal struct CreateTokenWithCardDataRequest: CreateTokenRequest {
    
    // MARK: - Internal -
    // MARK: Properties
    
    /// Card to create token for.
    internal let card: CreateTokenCard
    /// The api endpoint path for tokens
    internal let route: TapNetworkPath = .tokens
    
    // MARK: - Internal -
    // MARK: Methods
    
    /// Initializes the request with card.
    ///
    /// - Parameter card: Card.
    internal init(card: CreateTokenCard) {
        
        self.card = card
    }
    
    // MARK: - Private -
    
    private enum CodingKeys: String, CodingKey {
        
        case card = "card"
    }
}



/// Model that holds existing card details for token creation.
internal struct CreateTokenSavedCard: Encodable {
    
    // MARK: - Internal -
    // MARK: Properties
    
    /// Card identifier.
    internal let cardIdentifier: String
    
    /// Customer identifier.
    internal let customerIdentifier: String
    
    // MARK: Methods
    
    /// Initializes the model with card identifier and customer identifier.
    ///
    /// - Parameters:
    ///   - cardIdentifier: Card identifier.
    ///   - customerIdentifier: Customer identifier.
    internal init(cardIdentifier: String, customerIdentifier: String) {
        
        self.cardIdentifier = cardIdentifier
        self.customerIdentifier = customerIdentifier
    }
    
    // MARK: - Private -
    
    private enum CodingKeys: String, CodingKey {
        
        case cardIdentifier     = "card_id"
        case customerIdentifier = "customer_id"
    }
}


