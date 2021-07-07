//
//  CreateTokenWithSavedCardRequest.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/7/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// Request model for token creation with existing card data.
internal struct TapCreateTokenWithSavedCardRequest: TapCreateTokenRequest {
    
    // MARK: - Internal -
    // MARK: Properties
    
    /// Saved card details.
    internal let savedCard: CreateTokenSavedCard
    
    internal let route: TapNetworkPath = .tokens
    
    // MARK: Methods
    
    /// Initializes the model with saved card.
    ///
    /// - Parameter savedCard: Saved card.
    internal init(savedCard: CreateTokenSavedCard) {
        
        self.savedCard = savedCard
    }
    
    // MARK: - Private -
    
    private enum CodingKeys: String, CodingKey {
        
        case savedCard = "saved_card"
    }
}

