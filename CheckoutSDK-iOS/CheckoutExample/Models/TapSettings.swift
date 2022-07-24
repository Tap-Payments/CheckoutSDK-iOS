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
        try container.encode(customer, forKey: .customer)
    }
    
    enum CodingKeys: String, CodingKey {
        case language
        case localisation
        case theme
        case currency
        case swipeToDismissFeature
        case paymentTypes
        case closeButtonTitleFeature
        case customer
    }

    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        language = try values.decodeIfPresent(String.self, forKey: .language) ?? ""
        localisation = try values.decodeIfPresent(Bool.self, forKey: .localisation) ?? false
        theme = try values.decodeIfPresent(String.self, forKey: .theme) ?? ""
        currency = try values.decodeIfPresent(TapCurrencyCode.self, forKey: .currency) ?? .KWD
        swipeToDismissFeature = try values.decodeIfPresent(Bool.self, forKey: .swipeToDismissFeature) ?? false
        paymentTypes = try values.decodeIfPresent([TapPaymentType].self, forKey: .paymentTypes) ?? [.All]
        closeButtonTitleFeature = try values.decodeIfPresent(Bool.self, forKey: .closeButtonTitleFeature) ?? false
        customer = try values.decodeIfPresent(TapCustomer.self, forKey: .customer) ??  .init(identifier: "cus_TS075220212320q2RD0707283")

    }
    
    
    private let languageSevedKey = "language_settings_key"
    private let localisationSevedKey = "localisation_settings_key"
    private let themeSevedKey = "theme_settings_key"
    private let currencySevedKey = "currency_settings_key"
    private let swipeToDismissFeatureSevedKey = "swipeToDismissFeature_settings_key"
    private let closeButtonTitleFeatureSevedKey = "closeButtonTitleFeatureSevedKey_settings_key"
    private let paymentTypesSevedKey = "paymentTypes_settings_key"
    private let customerSevedKey = "customer_settings_key"

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
    var closeButtonTitleFeature: Bool {
        didSet { self.updateSavedData() }
    }
    var paymentTypes: [TapPaymentType] {
        didSet { self.updateSavedData() }
    }
    
    var customer: TapCustomer {
        didSet { self.updateSavedData() }
    }
    
    var onChangeBlock: (() -> ())?
    
    func updateSavedData() {
        self.onChangeBlock?()
        self.save()
    }
    init(language: String, localisation: Bool, theme: String, currency: TapCurrencyCode, swipeToDismissFeature: Bool, paymentTypes: [TapPaymentType],closeButtonTitleFeature:Bool, customer:TapCustomer) {
        self.language = language
        self.localisation = localisation
        self.theme = theme
        self.currency = currency
        self.swipeToDismissFeature = swipeToDismissFeature
        self.paymentTypes = paymentTypes
        self.closeButtonTitleFeature = closeButtonTitleFeature
        self.customer = customer
    }
    func save() {
        UserDefaults.standard.set(language, forKey: languageSevedKey)
        UserDefaults.standard.set(localisation, forKey: localisationSevedKey)
        UserDefaults.standard.set(theme, forKey: themeSevedKey)
        UserDefaults.standard.set(currency.appleRawValue, forKey: currencySevedKey)
        UserDefaults.standard.set(swipeToDismissFeature, forKey: swipeToDismissFeatureSevedKey)
        UserDefaults.standard.set(closeButtonTitleFeature, forKey: closeButtonTitleFeatureSevedKey)
        UserDefaults.standard.set(try? PropertyListEncoder().encode(customer), forKey: customerSevedKey)
        UserDefaults.standard.set(try? PropertyListEncoder().encode(paymentTypes), forKey: paymentTypesSevedKey)
    }
    func load() {
        language = UserDefaults.standard.value(forKey: languageSevedKey) as? String ?? "English"
        localisation = UserDefaults.standard.value(forKey: localisationSevedKey) as? Bool ?? false
        theme = UserDefaults.standard.value(forKey: themeSevedKey) as? String ?? "Default"
        currency = UserDefaults.standard.value(forKey: currencySevedKey) as? TapCurrencyCode ?? .USD
        swipeToDismissFeature = UserDefaults.standard.value(forKey: swipeToDismissFeatureSevedKey) as? Bool ?? true
        closeButtonTitleFeature = UserDefaults.standard.value(forKey: closeButtonTitleFeatureSevedKey) as? Bool ?? true
//        paymentTypes = UserDefaults.standard.value(forKey: paymentTypesSevedKey) as? [TapPaymentType] ?? [.All]
        
        if let data = UserDefaults.standard.value(forKey:paymentTypesSevedKey) as? Data {
            do {
                paymentTypes = try PropertyListDecoder().decode([TapPaymentType].self, from: data)
            } catch {
                print("error paymentTypes: \(error.localizedDescription)")
                paymentTypes = [.All]
            }
        }
        
        if let data = UserDefaults.standard.value(forKey:customerSevedKey) as? Data {
            do {
                customer = try PropertyListDecoder().decode(TapCustomer.self, from: data)
            } catch {
                print("error paymentTypes: \(error.localizedDescription)")
                customer = try! .init(identifier: "cus_TS075220212320q2RD0707283")
            }
        }
    }
}
