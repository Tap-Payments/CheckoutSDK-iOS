//
//  TapGoPayLoginResponseModel.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/29/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
/// Represents the model to parse the GoPay Loin API response
internal struct TapGoPayLoginResponseModel : Codable {
    /// Represents if the login was done correctly
    let success : Bool
    /// Represents a message to be shown if any
    let message : String
    
    enum CodingKeys: String, CodingKey {
        case success = "success"
        case message = "message"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        success = try values.decodeIfPresent(Bool.self, forKey: .success) ?? false
        message = try values.decodeIfPresent(String.self, forKey: .message) ?? ""
    }
}
