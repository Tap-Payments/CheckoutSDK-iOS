//
//  TapPhone.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 11/15/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
/** Represents the model for parsing the phone object coming from Tap backend
 {
    "phone": {
        "country_code": "965",
        "number": "00000000"
    }
 }
 */
struct TapPhone : Codable {
    /// Represents the country code part of the phone
    let country_code : String?
    /// Represents the phone number itself
    let number : String?
    
    enum CodingKeys: String, CodingKey {
        
        case country_code = "country_code"
        case number = "number"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        country_code = try values.decodeIfPresent(String.self, forKey: .country_code)
        number = try values.decodeIfPresent(String.self, forKey: .number)
    }
    
}
