//
//  TapSettings.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/17/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//
import class Foundation.NSObject
import CheckoutSDK_iOS
import CommonDataModelsKit_iOS
import TapUIKit_iOS

@objc public class TapSettings: NSObject, Codable {    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(localisation, forKey: .localisation)
        try container.encode(theme, forKey: .theme)
        try container.encode(currency, forKey: .currency)
        try container.encode(swipeToDismissFeature, forKey: .swipeToDismissFeature)
        try container.encode(addShipingFeature, forKey: .addShipingFeature)
        try container.encode(paymentTypes, forKey: .paymentTypes)
        try container.encode(customer, forKey: .customer)
        try container.encode(transactionMode, forKey: .trxMode)
    }
    
    enum CodingKeys: String, CodingKey {
        case language
        case localisation
        case theme
        case currency
        case swipeToDismissFeature
        case addShipingFeature
        case paymentTypes
        case closeButtonTitleFeature
        case customer
        case trxMode
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        localisation = try values.decodeIfPresent(Bool.self, forKey: .localisation) ?? false
        theme = try values.decodeIfPresent(String.self, forKey: .theme) ?? ""
        currency = try values.decodeIfPresent(TapCurrencyCode.self, forKey: .currency) ?? .KWD
        swipeToDismissFeature = try values.decodeIfPresent(Bool.self, forKey: .swipeToDismissFeature) ?? false
        addShipingFeature = try values.decodeIfPresent(Bool.self, forKey: .addShipingFeature) ?? false
        paymentTypes = try values.decodeIfPresent([TapPaymentType].self, forKey: .paymentTypes) ?? [.All]
        transactionMode = try values.decodeIfPresent(TransactionMode.self, forKey: .trxMode) ?? .purchase
        closeButtonTitleFeature = try values.decodeIfPresent(Bool.self, forKey: .closeButtonTitleFeature) ?? false
        customer = try values.decodeIfPresent(TapCustomer.self, forKey: .customer) ??  .init(identifier: "cus_TS075220212320q2RD0707283")

    }
    
    static let bundleSevedKey = "bundleSeved_key"
    static let sdkModeSevedKey = "sdkModeSevedKey"
    static let liveSevedKey = "liveSevedKey_key"
    static let sandboxSevedKey = "sandboxSevedKey_key"
    static let merchantIDSevedKey = "merchantIDSevedKey"
    private let languageSevedKey = "language_settings_key"
    private let localisationSevedKey = "localisation_settings_key"
    private let themeSevedKey = "theme_settings_key"
    private let currencySevedKey = "currency_settings_key"
    static let isSubsciptionSevedKey = "isSubsciptionSevedKey"
    static let applePayBillingStartDateSevedKey = "applePayBillingStartDateSevedKey"
    static let applePayBillingEndDateSevedKey = "applePayBillingEndDateSevedKey"
    static let applePayNameSevedKey = "applePayNameSevedKey"
    static let applePayBillingCycleSevedKey = "applePayBillingCycleSevedKey"
    static let applePayBillingStartDescSevedKey = "applePayBillingStartDescSevedKey"
    static let localIDSevedKey = "localIDSevedKey"
    static let applePaySubscriptionBillingAgreeSevedKey = "applePaySubscriptionBillingAgreeSevedKey"
    private let swipeToDismissFeatureSevedKey = "swipeToDismissFeature_settings_key"
    private let addShipingFeatureSevedKey = "addShipingFeatureSevedKey"
    static let creditNameFeatureSevedKey = "creditNameFeatureSevedKey"
    static let saveCardFeatureSevedKey = "saveCardFeatureSevedKey"
    private let closeButtonTitleFeatureSevedKey = "closeButtonTitleFeatureSevedKey_settings_key"
    private let paymentTypesSevedKey = "paymentTypes_settings_key"
    private let customerSevedKey = "customer_settings_key"
    static let itemsSaveKey = "itemss_settings_key"
    static let taxesSaveKey = "taxes_settings_key"
    static let transactionModeSaveKey = "transaction_mode_settings_key"
    
    
    
    var merchantID:String {
        return UserDefaults.standard.value(forKey: TapSettings.merchantIDSevedKey) as? String ?? "599424"
    }
    
    var localisation: Bool {
        didSet { UserDefaults.standard.set(localisation, forKey: localisationSevedKey)
            onChangeBlock?()
        }
    }
    var theme: String {
        didSet { UserDefaults.standard.set(theme, forKey: themeSevedKey)
            onChangeBlock?()
        }
    }
    var currency: TapCurrencyCode {
        didSet { UserDefaults.standard.set(currency.appleRawValue, forKey: currencySevedKey)
            onChangeBlock?()
        }
    }
    
    static var isSubsciption: Bool {
        return UserDefaults.standard.bool(forKey: TapSettings.isSubsciptionSevedKey)
    }
    
    static var sdkMode: SDKMode {
        return SDKMode(rawValue: UserDefaults.standard.integer(forKey: TapSettings.sdkModeSevedKey)) ?? .sandbox
    }
    
    static var applePayBillingStartDate:Double {
        let savedDate:Date = Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: TapSettings.applePayBillingStartDateSevedKey))
        return savedDate > Date() ? savedDate.timeIntervalSince1970 : Date().timeIntervalSince1970
    }
    
    static var applePayBillingEndDate:Double {
        if  UserDefaults.standard.double(forKey: TapSettings.applePayBillingEndDateSevedKey) == 0 {
            return Date().addingTimeInterval(24 * 60 * 60 * 365).timeIntervalSince1970
        }else{
            return Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: TapSettings.applePayBillingEndDateSevedKey)).timeIntervalSince1970
        }
    }
    
    
    static var applePaySubscriptionName:String {
        return UserDefaults.standard.string(forKey: TapSettings.applePayNameSevedKey) ?? "My Subscription"
    }
    
    static var applePaySubscriptionDesc:String {
        return UserDefaults.standard.string(forKey: TapSettings.applePayBillingStartDescSevedKey) ?? ""
    }
    
    static var language:String {
        return UserDefaults.standard.string(forKey: TapSettings.localIDSevedKey) ?? "en"
    }
    
    static var applePaySubscriptionBillingAgree:String {
        return UserDefaults.standard.string(forKey: TapSettings.applePaySubscriptionBillingAgreeSevedKey) ?? "You'll be billed $XX every month for the next 12 months. To cancel at any time, go to Account and click 'Cancel Membership.'"
    }
    
    static var applePayBillingCycle:NSCalendar.Unit {
        return NSCalendar.Unit.from(string: UserDefaults.standard.string(forKey: TapSettings.applePayBillingCycleSevedKey) ?? "day")
    }
    
    static var logs:[String] = []
    
    static var saveCardFeature: SaveCardType {
        return SaveCardType(stringValue:  UserDefaults.standard.string(forKey:TapSettings.saveCardFeatureSevedKey) ?? "none")
    }
    
    var swipeToDismissFeature: Bool {
        didSet { UserDefaults.standard.set(swipeToDismissFeature, forKey: swipeToDismissFeatureSevedKey)
            onChangeBlock?()
        }
    }
    
    var addShipingFeature: Bool {
        didSet { UserDefaults.standard.set(addShipingFeature, forKey: addShipingFeatureSevedKey)
            onChangeBlock?()
        }
    }
    
    
    var creditNameFeature: Bool {
        return UserDefaults.standard.value(forKey: TapSettings.creditNameFeatureSevedKey) as? Bool ?? false
    }
    
    var closeButtonTitleFeature: Bool {
        didSet { UserDefaults.standard.set(closeButtonTitleFeature, forKey: closeButtonTitleFeatureSevedKey)
            onChangeBlock?()
        }
    }
    var paymentTypes: [TapPaymentType] {
        didSet { UserDefaults.standard.set(try? PropertyListEncoder().encode(paymentTypes), forKey: paymentTypesSevedKey)
            onChangeBlock?()
        }
    }
    
    var transactionMode: TransactionMode {
        didSet { UserDefaults.standard.set(transactionMode.rawValue, forKey: TapSettings.transactionModeSaveKey)
            onChangeBlock?()
        }
    }
    
    var customer: TapCustomer {
        didSet { UserDefaults.standard.set(try! PropertyListEncoder().encode(customer), forKey: customerSevedKey)
            onChangeBlock?()
        }
    }
    
    var onChangeBlock: (() -> ())?
    
    func updateSavedData() {
        self.onChangeBlock?()
        self.save()
    }
    
    init(localisation: Bool, theme: String, currency: TapCurrencyCode, swipeToDismissFeature: Bool, paymentTypes: [TapPaymentType],closeButtonTitleFeature:Bool, customer:TapCustomer, transactionMode:TransactionMode, addShippingFeature: Bool) {
        self.localisation = localisation
        self.theme = theme
        self.currency = currency
        self.swipeToDismissFeature = swipeToDismissFeature
        self.addShipingFeature = addShippingFeature
        self.paymentTypes = paymentTypes
        self.closeButtonTitleFeature = closeButtonTitleFeature
        self.customer = customer
        self.transactionMode = transactionMode
    }
    func save() {
        UserDefaults.standard.set(localisation, forKey: localisationSevedKey)
        UserDefaults.standard.set(theme, forKey: themeSevedKey)
        UserDefaults.standard.set(currency.appleRawValue, forKey: currencySevedKey)
        UserDefaults.standard.set(swipeToDismissFeature, forKey: swipeToDismissFeatureSevedKey)
        UserDefaults.standard.set(closeButtonTitleFeature, forKey: closeButtonTitleFeatureSevedKey)
        UserDefaults.standard.set(try! PropertyListEncoder().encode(transactionMode), forKey: TapSettings.transactionModeSaveKey)
        UserDefaults.standard.set(try! PropertyListEncoder().encode(customer), forKey: customerSevedKey)
        UserDefaults.standard.set(try? PropertyListEncoder().encode(paymentTypes), forKey: paymentTypesSevedKey)
    }
    func load() {
        TapCheckout.bundleID = UserDefaults.standard.value(forKey: TapSettings.bundleSevedKey) as? String ?? "company.tap.goSellSDKExamplee"
        
        TapCheckout.secretKey = .init(sandbox: UserDefaults.standard.value(forKey: TapSettings.sandboxSevedKey) as? String ?? "sk_test_cvSHaplrPNkJO7dhoUxDYjqA", production: UserDefaults.standard.value(forKey: TapSettings.liveSevedKey) as? String ?? "sk_live_V4UDhitI0r7sFwHCfNB6xMKp")
        
        localisation = UserDefaults.standard.value(forKey: localisationSevedKey) as? Bool ?? false
        theme = UserDefaults.standard.value(forKey: themeSevedKey) as? String ?? "Default"
        currency = TapCurrencyCode(appleRawValue: UserDefaults.standard.value(forKey: currencySevedKey) as? String ?? "KWD") ?? .KWD
        swipeToDismissFeature = UserDefaults.standard.value(forKey: swipeToDismissFeatureSevedKey) as? Bool ?? true
        closeButtonTitleFeature = UserDefaults.standard.value(forKey: closeButtonTitleFeatureSevedKey) as? Bool ?? true
        transactionMode = TransactionMode(rawValue: UserDefaults.standard.value(forKey: TapSettings.transactionModeSaveKey) as? Int ?? 0) ?? .purchase
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
