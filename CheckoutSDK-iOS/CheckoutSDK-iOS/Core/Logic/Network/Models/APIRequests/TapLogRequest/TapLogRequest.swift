//
//  TapLogRequest.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/29/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import CommonDataModelsKit_iOS
import CoreTelephony
import TapApplicationV2
/// TapLogRequestModel model.
internal struct TapLogRequestModel {
}





/*
// MARK: - Equatable
extension TapBinResponseModel: Equatable {
    
    internal static func == (lhs: TapBinResponseModel, rhs: TapBinResponseModel) -> Bool {
        
        return lhs.binNumber == rhs.binNumber
    }
}

// MARK: - Decodable
extension TapBinResponseModel: Decodable {
    
    internal init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let isAddressRequired   = try container.decodeIfPresent(Bool.self, forKey: .isAddressRequired) ?? false
        let bank                = try container.decodeIfPresent(String.self, forKey: .bank)
        let bankLogoURL         = container.decodeURLIfPresent(for: .bankLogoURL)
        let binNumber           = try container.decode(String.self, forKey: .binNumber)
        let cardBrand           = try container.decodeIfPresent(CardBrand.self, forKey: .cardBrand) ?? .unknown
        let cardType            = CardType(cardTypeString:try container.decodeIfPresent(String.self, forKey: .cardType) ?? "")
        let scheme              = try container.decodeIfPresent(CardScheme.self, forKey: .scheme)
        
        var country: Country? = nil
        if let countryString = try container.decodeIfPresent(String.self, forKey: .country), !countryString.isEmpty {
            
            country = try container.decodeIfPresent(Country.self, forKey: .country)
        }
        
        self.init(isAddressRequired: isAddressRequired, bank: bank, bankLogoURL: bankLogoURL, binNumber: binNumber, cardBrand: cardBrand, scheme: scheme, country: country, cardType: cardType)
    }
}*/
