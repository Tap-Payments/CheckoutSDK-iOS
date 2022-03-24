//
//  TapConfigResponseModel.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 24/03/2022.
//  Copyright © 2022 Tap Payments. All rights reserved.
//

import Foundation
/// Config api response model
internal struct TapConfigResponseModel {
    
    // MARK: - Internal -
    // MARK: Properties
    
    /// The middleware token generated for the user for this session
    internal let token: String?
    
    // MARK: - Private -
    
    private enum CodingKeys: String, CodingKey {
        
        case token  =   "token"
    }
}

// MARK: - Equatable
extension TapConfigResponseModel: Equatable {
    
    internal static func == (lhs: TapConfigResponseModel, rhs: TapConfigResponseModel) -> Bool {
        
        return lhs.token == rhs.token
    }
}

// MARK: - Decodable
extension TapConfigResponseModel: Decodable {
    
    internal init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let token  =   try container.decodeIfPresent(String.self, forKey: .token) ?? ""
        
        self.init(token: token)
    }
}
