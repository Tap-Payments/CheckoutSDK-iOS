//
//  CurrencyCardsTelecomModel.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/17/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
import TapUIKit_iOS
import CommonDataModelsKit_iOS
import TapUIKit_iOS
import TapCardVlidatorKit_iOS
/// Represents a model that will link the different Cards and Telecom bar item view models with their approved currencies and countries
internal class CurrencyCardsTelecomModel:Codable {
    
    /// Represents the card/telecom bar item view model itself (Visa, Amex, )
    lazy var tapCardPhoneViewModel:TapCardPhoneIconViewModel = .init(associatedCardBrand: .visa)
    /// Represents the list of currencies the bar item supports or should be visible when selected
    lazy var supportedCurrencies:[TapCurrencyCode] = []
    /// Repreents the country associated with the telecom bar payments if any
    lazy var supportedTelecomCountry:TapCountry? = nil
    /// Represents the payment type
    lazy var paymentType:TapPaymentType = .All
    /// Corresponding PaymentOption model
    lazy var tapPaymentOption:PaymentOption? = nil
    
    /**
     Creates a new instance that links the bar view model with certain currencies
     - Parameter tapCardPhoneViewModel: Represents the card/telecom bar item view model itself (Visa, Amex, )
     - Parameter supportedCurrencies: Represents the list of currencies the bar item supports or should be visible when selected selected
     - Parameter supportedTelecomCountry: Repreents the country associated with the telecom bar payments if any
     - Parameter paymentType:Represents the payment type
     */
    init(tapCardPhoneViewModel:TapCardPhoneIconViewModel, supportedCurrencies:[TapCurrencyCode] = [], supportedTelecomCountry:TapCountry? = nil,paymentType:TapPaymentType = .All) {
        self.tapCardPhoneViewModel = tapCardPhoneViewModel
        self.supportedCurrencies = supportedCurrencies
        self.supportedTelecomCountry = supportedTelecomCountry
        self.paymentType = paymentType
    }
    
    
    
    /**
     Creates a new instance that links the chip model with certain Backend tap payment option
     - Parameter paymentOption:Represnts the payment option model backend
     */
    init(paymentOption:PaymentOption) {
        
        self.tapCardPhoneViewModel = TapCardPhoneIconViewModel.init(associatedCardBrand: paymentOption.brand, tapCardPhoneIconUrl: paymentOption.imageURL.absoluteString, paymentOptionIdentifier: paymentOption.identifier)
        
        self.supportedCurrencies = paymentOption.supportedCurrencies
        self.supportedTelecomCountry = nil
        self.paymentType = paymentOption.paymentType
        self.tapPaymentOption = paymentOption
    }
    
    /**
     Creates a correct chip model with respect to the payment option type
     - Parameter paymentOption:Represnts the payment option model backend
     */
    private func generateCorrectChipType(from paymentOption:PaymentOption) -> GenericTapChipViewModel {
        let genericChipModel:GenericTapChipViewModel = .init(title: paymentOption.title, icon: paymentOption.imageURL.absoluteString)
        switch paymentOption.paymentType {
        case .ApplePay,.Device:
            return ApplePayChipViewCellModel.init(title: paymentOption.title, icon: paymentOption.imageURL.absoluteString)
        case .Card:
            return SavedCardCollectionViewCellModel.init(title: paymentOption.title, icon: paymentOption.imageURL.absoluteString)
        case .Web:
            return GatewayChipViewModel.init(title: paymentOption.title, icon: paymentOption.imageURL.absoluteString)
        default:
            return genericChipModel
        }
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
        case brand = "brand"
        case supportedCurrencies = "currencies"
        case supportedTelecomCountry = "country"
        case brandIcon = "icon"
        case paymentType = "paymentType"
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.supportedCurrencies = try values.decodeIfPresent([TapCurrencyCode].self, forKey: .supportedCurrencies) ?? []
        self.supportedTelecomCountry = try values.decodeIfPresent(TapCountry.self, forKey: .supportedTelecomCountry)
        let cardBrand:CardBrand = try values.decodeIfPresent(CardBrand.self, forKey: .brand) ?? CardBrand.unknown
        let brandIcon:String = try values.decodeIfPresent(String.self, forKey: .brandIcon) ?? ""
        self.tapCardPhoneViewModel = .init(associatedCardBrand: cardBrand, tapCardPhoneIconUrl:brandIcon)
        self.paymentType = try values.decodeIfPresent(TapPaymentType.self, forKey: .paymentType) ?? .All
    }
    
    
    func encode(to encoder: Encoder) throws {
        
    }
    
}

