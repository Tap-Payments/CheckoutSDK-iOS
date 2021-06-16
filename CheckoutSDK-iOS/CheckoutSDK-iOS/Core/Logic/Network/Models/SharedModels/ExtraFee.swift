//
//  ExtraFee.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/15/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import CommonDataModelsKit_iOS
/// Represents the extra fees model. This will be used when a user selects a payment option like credit card, he has to know he will be paying some more money for it :)
/// - tag: ExtraFee
internal final class ExtraFee: AmountModificatorModel {
    
    // MARK: - Internal -
    // MARK: Properties
    
    /// Currency code.
    internal let currency: TapCurrencyCode
    
    // MARK: Methods
    
    internal required init(type: AmountModificationType, value: Double, currency: TapCurrencyCode, minFee:Decimal = 0, maxFee:Decimal = 0) {
        self.currency = currency
        super.init(type: type, value: value, minFee: minFee, maxFee: maxFee)
    }
    
    internal required convenience init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try container.decode(AmountModificationType.self, forKey: .type)
        let value = try container.decode(Double.self, forKey: .value)
        let maxFee = try container.decodeIfPresent(Decimal.self, forKey: .maxFee) ?? 0
        let minFee = try container.decodeIfPresent(Decimal.self, forKey: .minFee) ?? 0
        let currency = try container.decode(TapCurrencyCode.self, forKey: .currency)
        
        self.init(type: type, value: value, currency: currency,minFee:minFee, maxFee: maxFee)
    }
    
    // MARK: - Private -
    
    private enum CodingKeys: String, CodingKey {
        
        case type       = "type"
        case value      = "value"
        case currency   = "currency"
        case maxFee     = "maximum_fee"
        case minFee     = "minimum_fee"
    }
}