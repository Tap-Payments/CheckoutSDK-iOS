//
//  TapDeleteSavedCardResponseModel.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/13/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// The model to represent the delete of saved card api
internal struct TapDeleteSavedCardResponseModel: IdentifiableWithString, Decodable {
    
    // MARK: - Internal -
    // MARK: Properties
    
    internal let isDeleted: Bool
    internal let identifier: String
    
    // MARK: - Private -
    
    private enum CodingKeys: String, CodingKey {
        
        case isDeleted  = "deleted"
        case identifier = "id"
    }
}
