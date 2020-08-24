//
//  ChipWithCurrencyModel.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/17/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation

/// Represents a model that will link the different chips models with their approved currencies
internal class ChipWithCurrencyModel:Codable {
    
    /// Represents the chip view model itself (Apple, goPay & saved card)
    lazy var tapChipViewModel:GenericTapChipViewModel = .init()
    /// Represents the list of currencies the chip supports or should be visible when selected
    lazy var supportedCurrencies:[TapCurrencyCode] = []
    /// Represents the the country the telecom operator works with
    var supportedCountry:TapCountry?
    
    /**
     Creates a new instance that links the chip model with certain currencies
     - Parameter tapChipViewModel: Represents the chip view model itself (Apple, goPay & saved card)
     - Parameter supportedCurrencies: Represents the list of currencies the chip supports or should be visible when selected
     - Parameter supportedCountry: Represents the the country the telecom operator works with
     */
    init(tapChipViewModel:GenericTapChipViewModel, supportedCurrencies:[TapCurrencyCode] = [],supportedCountry:TapCountry? = nil) {
        self.tapChipViewModel = tapChipViewModel
        self.supportedCurrencies = supportedCurrencies
        self.supportedCountry = supportedCountry
    }
    
    /**
     Determines if the tap chip view model should be visible with a given currency
     - Parameter currency: The currency to deteremine if the chip view model supports or no
     - Returns: True if the list if currencies is empty (means it should be visible always.) or It has the given currency. Returns false otherwise
     */
    func isEnabled(for currency:TapCurrencyCode) -> Bool {
        // Make sure the currency list has values with the given currenct or it supports every currency
        return (supportedCurrencies == []) || (supportedCurrencies.filter{ $0.appleRawValue == currency.appleRawValue } != [])
        
    }
    enum CodingKeys: String, CodingKey {
        case tapChipViewModel = "chip"
        case supportedCurrencies = "currencies"
        case supportedCountry = "country"
        case chipType = "chipType"
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.supportedCurrencies = try values.decodeIfPresent([TapCurrencyCode].self, forKey: .supportedCurrencies) ?? []
        self.supportedCountry = try values.decodeIfPresent(TapCountry.self, forKey: .supportedCountry)
        let chipType:TapChipType = try values.decodeIfPresent(TapChipType.self, forKey: .chipType) ?? .GatewayChip
        switch chipType {
        case .GatewayChip:
            self.tapChipViewModel = try values.decodeIfPresent(GatewayChipViewModel.self, forKey: .tapChipViewModel) ?? .init()
        case .ApplePayChip:
            self.tapChipViewModel = try values.decodeIfPresent(ApplePayChipViewCellModel.self, forKey: .tapChipViewModel) ?? .init()
        case .GoPayChip:
            self.tapChipViewModel = try values.decodeIfPresent(TapGoPayViewModel.self, forKey: .tapChipViewModel) ?? .init()
        case .CurrencyChip:
            self.tapChipViewModel = try values.decodeIfPresent(CurrencyChipViewModel.self, forKey: .tapChipViewModel) ?? .init()
        case .SavedCardChip:
            self.tapChipViewModel = try values.decodeIfPresent(SavedCardCollectionViewCellModel.self, forKey: .tapChipViewModel) ?? .init()
            (self.tapChipViewModel as! SavedCardCollectionViewCellModel).listSource = .GoPayListHeader
        case .LogoutChip:
            self.tapChipViewModel = try values.decodeIfPresent(TapLogoutChipViewModel.self, forKey: .tapChipViewModel) ?? .init()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.tapChipViewModel, forKey: .tapChipViewModel)
        try container.encode(self.supportedCountry, forKey: .supportedCountry)
        try container.encode(self.supportedCurrencies, forKey: .supportedCurrencies)
    }
}


extension TapChipType:Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        switch  rawValue {
        case 1:
            self = .GatewayChip
        case 2:
            self = .ApplePayChip
        case 3:
            self = .GoPayChip
        case 4:
            self = .CurrencyChip
        case 5:
            self = .SavedCardChip
        default:
            self = .GatewayChip
        }
    }
}
