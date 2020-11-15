//
//  TapIntentRequestModel.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 11/15/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
struct TapIntentRequestModel : Codable {
    let phone : TapPhone?
    
    enum CodingKeys: String, CodingKey {
        
        case phone = "phone"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        phone = try values.decodeIfPresent(TapPhone.self, forKey: .phone)
    }
    
}
