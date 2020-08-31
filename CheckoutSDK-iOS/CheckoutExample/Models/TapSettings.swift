//
//  TapSettings.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/17/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//
import class Foundation.NSObject
import CheckoutSDK_iOS

@objc public class TapSettings: NSObject, Codable {    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(language, forKey: .language)
        try container.encode(localisation, forKey: .localisation)
        try container.encode(theme, forKey: .theme)
        try container.encode(currency, forKey: .currency)
        try container.encode(swipeToDismissFeature, forKey: .swipeToDismissFeature)
        try container.encode(paymentTypes, forKey: .paymentTypes)
    }
    
    enum CodingKeys: String, CodingKey {
        case language
        case localisation
        case theme
        case currency
        case swipeToDismissFeature
        case paymentTypes
    }

    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        language = try values.decodeIfPresent(String.self, forKey: .language) ?? ""
        localisation = try values.decodeIfPresent(Bool.self, forKey: .localisation) ?? false
        theme = try values.decodeIfPresent(String.self, forKey: .theme) ?? ""
        currency = try values.decodeIfPresent(TapCurrencyCode.self, forKey: .currency) ?? .KWD
        swipeToDismissFeature = try values.decodeIfPresent(Bool.self, forKey: .swipeToDismissFeature) ?? false
        paymentTypes = try values.decodeIfPresent([TapPaymentType].self, forKey: .paymentTypes) ?? [.All]

    }
    
    
    static let localSavedKey = "localSavedKey_tap_settings"
    var language: String {
        didSet { self.updateSavedData() }
    }
    var localisation: Bool {
        didSet { self.updateSavedData() }
    }
    var theme: String {
        didSet { self.updateSavedData() }
    }
    var currency: TapCurrencyCode {
        didSet { self.updateSavedData() }
    }
    var swipeToDismissFeature: Bool {
        didSet { self.updateSavedData() }
    }
    var paymentTypes: [TapPaymentType] {
        didSet { self.updateSavedData() }
    }
    var onChangeBlock: (() -> ())?
    
    func updateSavedData() {
        self.save()
        self.onChangeBlock?()
    }
    init(language: String, localisation: Bool, theme: String, currency: TapCurrencyCode, swipeToDismissFeature: Bool, paymentTypes: [TapPaymentType]) {
        self.language = language
        self.localisation = localisation
        self.theme = theme
        self.currency = currency
        self.swipeToDismissFeature = swipeToDismissFeature
        self.paymentTypes = paymentTypes
    }
    
    func save() {
        do {
            try UserDefaults.standard.setObject(self, forKey: TapSettings.localSavedKey)
        } catch {
            print("error")
        }
    }
}
