//
//  TapConfigRequestModel.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 24/03/2022.
//  Copyright © 2022 Tap Payments. All rights reserved.
//

import Foundation

/// Config request model.
internal struct TapConfigRequestModel: Encodable {
    
    // MARK: - Internal -
    // MARK: Properties
    
    /// The actual gateway body model for the request
    internal let gateway: Gateway
    
    // MARK: - Private -
    
    private enum CodingKeys: String, CodingKey {
        case gateway    =   "gateway"
    }
}
