//
//  TapCustomerMetaData.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 11/15/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
/** Represents the model for parsing the metdata for a customer object coming from Tap backend
 {
    "metadata": {
        "udf1": "test"
    }
 }
 */
@objc public class TapCustomerMetaData : NSObject,Codable {
    /// this is whatever  metadat merchant can send i.e pspReference: This is a value we send you in the SALE and in the Refunds, under metadata.pspReference.
    @objc public let udf1 : String
    
    enum CodingKeys: String, CodingKey {
        
        case udf1 = "udf1"
    }
    
    @objc public init(udf1: String = "") {
        self.udf1 = udf1
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        udf1 = try values.decodeIfPresent(String.self, forKey: .udf1) ?? ""
    }
    
}
