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

