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
    
    /// Defines the details of the application + the SDK
    internal let application: TapLogApplicationModel?
    /// Defines the details of the current customer
    internal let customer:TapCustomer?
    /// Defines the details of the current merchant
    internal let merchant:TapLogMerchantModel?
}

/// Defines the details of the current merchant
internal struct TapLogMerchantModel {
    
    /// Merchant id
    internal let id: String?
    /// Merchant encryption key
    internal let auth_key_type:String?
    /// Merchant sdk mode
    internal let auth_key_mode: String?
    /// Merchant used key
    internal let auth_key_value:String?
    
    init() {
        self.id = TapCheckout.sharedCheckoutManager().dataHolder.transactionData.tapMerchantID
        self.auth_key_type = TapCheckout.sharedCheckoutManager().dataHolder.transactionData.intitModelResponse?.data.encryptionKey
        self.auth_key_mode = TapCheckout.sharedCheckoutManager().dataHolder.transactionData.sdkMode.description
        self.auth_key_value = TapCheckout.secretKey.usedKey
    }
    
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
