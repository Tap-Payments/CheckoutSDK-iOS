//
//  NetworkManagerExtensions.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/14/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import CoreTelephony
import TapApplicationV2

/// Extension to the network manager when needed. To keep the network manager class itself clean and readable
internal extension NetworkManager {
    
    /// A computed variable that generates at access time the required static headers by the server.
    static func applicationStaticDetails() -> [String: String] {
        
        guard let bundleID = TapApplicationPlistInfo.shared.bundleIdentifier, !bundleID.isEmpty else {
            
            fatalError("Application must have bundle identifier in order to use goSellSDK.")
        }
        
        let sdkPlistInfo = TapBundlePlistInfo(bundle: Bundle(for: TapCheckout.self))
        
        guard let requirerVersion = sdkPlistInfo.shortVersionString, !requirerVersion.isEmpty else {
            
            fatalError("Seems like SDK is not integrated well.")
        }
        let networkInfo = CTTelephonyNetworkInfo()
        let providers = networkInfo.serviceSubscriberCellularProviders
        
        let osName = UIDevice.current.systemName
        let osVersion = UIDevice.current.systemVersion
        let deviceName = UIDevice.current.name
        let deviceNameFiltered =  deviceName.tap_byRemovingAllCharactersExcept("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ123456789")
        let deviceType = UIDevice.current.model
        let deviceModel = UIDevice.current.localizedModel
        var simNetWorkName:String? = ""
        var simCountryISO:String? = ""
        
        if providers?.values.count ?? 0 > 0, let carrier:CTCarrier = providers?.values.first {
            simNetWorkName = carrier.carrierName
            simCountryISO = carrier.isoCountryCode
        }
        
        
        let result: [String: String] = [
            
            Constants.HTTPHeaderValueKey.appID: bundleID,
            Constants.HTTPHeaderValueKey.requirer: Constants.HTTPHeaderValueKey.requirerValue,
            Constants.HTTPHeaderValueKey.requirerVersion: requirerVersion,
            Constants.HTTPHeaderValueKey.requirerOS: osName,
            Constants.HTTPHeaderValueKey.requirerOSVersion: osVersion,
            Constants.HTTPHeaderValueKey.requirerDeviceName: deviceNameFiltered,
            Constants.HTTPHeaderValueKey.requirerDeviceType: deviceType,
            Constants.HTTPHeaderValueKey.requirerDeviceModel: deviceModel,
            Constants.HTTPHeaderValueKey.requirerSimNetworkName: simNetWorkName ?? "",
            Constants.HTTPHeaderValueKey.requirerSimCountryIso: simCountryISO ?? "",
        ]
        
        return result
    }
    
    
    
    struct Constants {
        
        internal static let authenticateParameter = "authenticate"
        
        fileprivate static let timeoutInterval: TimeInterval            = 60.0
        fileprivate static let cachePolicy:     URLRequest.CachePolicy  = .reloadIgnoringCacheData
        
        fileprivate static let successStatusCodes = 200...299
        
        fileprivate struct HTTPHeaderKey {
            
            fileprivate static let authorization    = "Authorization"
            fileprivate static let application      = "application"
            fileprivate static let sessionToken     = "session_token"
            
            //@available(*, unavailable) private init() { }
        }
        
        fileprivate struct HTTPHeaderValueKey {
            
            fileprivate static let appID                = "app_id"
            fileprivate static let appLocale                = "app_locale"
            fileprivate static let deviceID                = "device_id"
            fileprivate static let requirer                = "requirer"
            fileprivate static let requirerOS            = "requirer_os"
            fileprivate static let requirerOSVersion        = "requirer_os_version"
            fileprivate static let requirerValue            = "SDK"
            fileprivate static let requirerVersion        = "requirer_version"
            fileprivate static let requirerDeviceName        = "requirer_device_name"
            fileprivate static let requirerDeviceType        = "requirer_device_type"
            fileprivate static let requirerDeviceModel    = "requirer_device_model"
            fileprivate static let requirerSimNetworkName    = "requirer_sim_network_name"
            fileprivate static let requirerSimCountryIso    = "requirer_sim_country_iso"
            
            //@available(*, unavailable) private init() { }
        }
    }
}
