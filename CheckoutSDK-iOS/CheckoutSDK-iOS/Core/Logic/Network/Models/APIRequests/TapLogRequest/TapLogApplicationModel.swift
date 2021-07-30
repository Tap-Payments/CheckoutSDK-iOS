//
//  TapLogApplicationModel.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/29/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import CommonDataModelsKit_iOS
import CoreTelephony
import TapApplicationV2


/// The application model inside tap logging model
internal struct TapLogApplicationModel: Codable {
    
    // MARK: - Internal -
    // MARK: Properties
    
    /// Defines the app details
    internal let app: LogAppModel?
    
    /// Defies the plygin details
    internal let plugin: String?
    
    /// Defines the device details
    internal let device: LogDeviceModel?
    
    /// Not related
    internal let browser: String?
    
    /// Not related
    internal let location: String?
    
    /// Defines this SDK details
    internal let entry: LogEntryModel?
    
    /// Defines the SDK details
    internal let requirer: LogRequirerModel?
    
    /// The application model inside tap logging model
    ///
    /// - Parameters:
    ///   - app: Defines the app details
    ///   - plugin: Defies the plygin details
    ///   - device: Defies the device details
    ///   - browser: DDefies the browser details
    ///   - location: Defies the location details
    ///   - entry: Defies the current sdk details
    ///   - requirer: Defies the user details
    internal init(app: LogAppModel?, plugin: String?, device: LogDeviceModel?, browser: String?, location: String?, entry: LogEntryModel?, requirer: LogRequirerModel?) {
        self.app = app
        self.plugin = plugin
        self.device = device
        self.browser = browser
        self.location = location
        self.entry = entry
        self.requirer = requirer
    }
    
    /// The application model inside tap logging model
    internal init() {
        self.app = .init()
        self.plugin = .init()
        self.device = .init()
        self.browser = .init()
        self.location = .init()
        self.entry = .init()
        self.requirer = .init()
    }
}



/// The app model inside the log request model
internal struct LogAppModel: Codable {
    
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
internal struct LogDeviceModel: Codable {
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
        self.id         = UIDevice.current.identifierForVendor?.uuidString
        self.type       = "phone"
        self.brand      = UIDevice.current.model
        self.model      = UIDevice.current.localizedModel
        self.os         = UIDevice.current.systemName
        self.os_version = UIDevice.current.systemVersion
    }
}


/// The entry model inside the log request model
internal struct LogEntryModel: Codable {
    
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
internal struct LogRequirerModel: Codable {
    
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
        self.id                         = Bundle.main.bundleIdentifier
        self.locale                     = TapCheckout.localeIdentifier
        self.requirer                   = "SDK"
        self.requirer_os                = UIDevice.current.systemName
        self.requirer_version           = UIDevice.current.systemVersion
        self.requirer_device_name       = UIDevice.current.name.tap_byRemovingAllCharactersExcept("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ123456789")
        
        self.requirer_device_type       = UIDevice.current.model
        self.requirer_device_model      = UIDevice.current.localizedModel
        var simNetWorkName:String?      = ""
        var simCountryISO:String?       = ""
        
        let networkInfo = CTTelephonyNetworkInfo()
        let providers = networkInfo.serviceSubscriberCellularProviders
        
        if providers?.values.count ?? 0 > 0, let carrier:CTCarrier = providers?.values.first {
            simNetWorkName = carrier.carrierName
            simCountryISO = carrier.isoCountryCode
        }
        self.requirer_sim_network_name  = simNetWorkName
        self.requirer_sim_country_iso   = simCountryISO
        
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
