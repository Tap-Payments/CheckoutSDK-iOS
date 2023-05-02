//
//  TapCheckoutManager+Calculations.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/18/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import CommonDataModelsKit_iOS
import LocalisationManagerKit_iOS
import CoreTelephony
/// Contains logic that needed to do any computation during the checkout process
internal extension TapCheckout {
    
    /// Detect the country code based on SIM network first/
    func detectSimCountryCode() -> String? {
        let networkInfo = CTTelephonyNetworkInfo()
        let providers = networkInfo.serviceSubscriberCellularProviders
        var simCountryISO:String? = "EG"
        if let nonNullSimCountryIso:String = providers?.values.first(where: {$0.isoCountryCode != nil})?.isoCountryCode {
            simCountryISO = nonNullSimCountryIso
        }
        return simCountryISO
    }
    
    /// Detect the local currency of the user
    func detectSimCurrencyCode() -> TapCurrencyCode {
        guard let nonNullCountryCode:String = detectSimCountryCode()?.uppercased(),
              let nonNullCurrencyCode:String = Locale.currency[nonNullCountryCode] ?? "",
              let tapCurrency:TapCurrencyCode = .init(appleRawValue: nonNullCurrencyCode),
              tapCurrency != .undefined else { return TapCurrencyCode.undefined }
        return tapCurrency
    }
    
}
