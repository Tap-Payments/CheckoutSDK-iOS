//
//  CreateCardVerificationRequest.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/6/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// Create charge request model.
internal struct TapCreateCardVerificationRequestModel: Encodable {
    
    // MARK: - Internal -
    // MARK: Properties
    
    /// Whether we need to activate 3ds or not
    internal let is3DSecureRequired: Bool?
    
    /// Whether we need  to save the card
    internal let shouldSaveCard: Bool
    
    /// Any additional data the merchant wants to attach to
    internal let metadata: TapMetadata?
    
    /// The customer who is saving the card
    internal let customer: TapCustomer
    
    /// The currency for the saved card
    internal let currency: TapCurrencyCode
    
    /// The request source
    internal let source: SourceRequest
    
    /// The url the merchant wants to repost the result to
    internal let redirect: TrackingURL
    
    // MARK: - Private -
    
    private enum CodingKeys: String, CodingKey {
        
        case is3DSecureRequired = "threeDSecure"
        case shouldSaveCard        = "save_card"
        case metadata            = "metadata"
        case customer            = "customer"
        case currency            = "currency"
        case source                = "source"
        case redirect            = "redirect"
    }
}
