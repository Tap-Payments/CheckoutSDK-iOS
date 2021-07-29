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
    
    // MARK: - Internal -
    // MARK: Properties
    
    /// Defines if address is required
    internal let isAddressRequired: Bool
    
    /// Card issuer bank.
    internal let bank: String?
    
    /// Bank logo URL.
    internal let bankLogoURL: URL?
    
    /// Card BIN number.
    internal let binNumber: String
    
    /// Card brand.
    internal let cardBrand: CardBrand
    
    /// Card scheme.
    internal let scheme: CardScheme?
    
    /// Card issuing country.
    internal let country: Country?
    
    /// Card Type.
    internal let cardType: CardType
    
    // MARK: - Private -
    
    private enum CodingKeys: String, CodingKey {
        
        case isAddressRequired  = "address_required"
        case bank               = "bank"
        case bankLogoURL        = "bank_logo"
        case binNumber          = "bin"
        case cardBrand          = "card_brand"
        case scheme             = "card_scheme"
        case country            = "country"
        case cardType           = "card_type"
    }
}


/// The app model inside the log request model
fileprivate struct LogAppModel: Codable {
    
    /// Th bundle id of the app
    let id:String?
    /// The name of the app
    let name:String?
    /// The version of the app
    let version:String?
    
    init() {
        self.id         = Bundle.main.bundleIdentifier
        self.name       = Bundle.main.displayName
        self.version    = Bundle.main.version
    }
}


/// The device model inside the log request model
fileprivate struct LogDeviceModel: Codable {
    /// Th id of the device
    let id:String?
    /// The type of the device (phone)
    let type:String?
    /// The brand of the device (iPhone or iPad or iPod)
    let brand:String?
    /// The model of the device
    let model:String?
    /// The OS
    let os:String?
    /// The OS version
    let os_version:String?
    
    init() {
        self.id = UIDevice.current.identifierForVendor?.uuidString
        self.type       = "phone"
        self.brand      = UIDevice.current.model
        self.model      = UIDevice.current.localizedModel
        self.os         = UIDevice.current.systemName
        self.os_version = UIDevice.current.systemVersion
    }
}


/// The entry model inside the log request model
fileprivate struct LogEntryModel: Codable {
   
    /// App Name or Website Name
    let name:String?
    /// LUGIN, WEB_LIBRARY, APP_LIBRARY, API
    let interface:String?
    /// WEBSITE, IOS, ANDROID, WINDOWS
    let type:String?
    /// SDK version
    let version:String?
    
    init() {
        self.name       = Bundle.main.displayName
        self.interface  = "CheckoutSDK-iOS"
        self.type       = "IOS"
        self.version    = TapCheckout.sdkVersion
    }
}

/// The entry model inside the log request model
fileprivate struct LogRequirerModel: Codable {
    
    /// Requirer device id
    let id:String?
    /// The language used inside the sdk
    let locale:String?
    /// SDK
    let requirer:String?
    /// SDK iOS
    let requirer_os:String?
    /// iOS version
    let requirer_version:String?
    /// device name
    let requirer_device_name:String?
    /// device type
    let requirer_device_type:String?
    /// device model
    let requirer_device_model:String?
    /// sim name
    let requirer_sim_network_name:String?
    /// sim country
    let requirer_sim_country_iso:String?
    
    init() {
        self.id         = Bundle.main.bundleIdentifier
        self.locale  = TapCheckout.localeIdentifier
        self.requirer       = "SDK"
        self.requirer_os    = UIDevice.current.systemName
        self.requirer_version = UIDevice.current.systemVersion
        self.requirer_device_name = UIDevice.current.name.tap_byRemovingAllCharactersExcept("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ123456789")
        
        self.requirer_device_type = UIDevice.current.model
        self.requirer_device_model = UIDevice.current.localizedModel
        var simNetWorkName:String? = ""
        var simCountryISO:String? = ""
        
        let networkInfo = CTTelephonyNetworkInfo()
        let providers = networkInfo.serviceSubscriberCellularProviders
        
        if providers?.values.count ?? 0 > 0, let carrier:CTCarrier = providers?.values.first {
            simNetWorkName = carrier.carrierName
            simCountryISO = carrier.isoCountryCode
        }
        self.requirer_sim_network_name = simNetWorkName
        self.requirer_sim_country_iso = simCountryISO
        
    }
}

fileprivate extension Bundle {
    /// Name of the app - title under the icon.
    var displayName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
            object(forInfoDictionaryKey: "CFBundleName") as? String
    }
    /// The version of the app
    var version:String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
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
