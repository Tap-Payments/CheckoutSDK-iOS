//
//  TapCheckout+Locale.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 11/04/2023.
//  Copyright © 2023 Tap Payments. All rights reserved.
//

import Foundation

internal extension Locale {
    /// Get Currency Symbol based on Country code or Country name using NSLocale
    static let currency: [String: (String?)] = isoRegionCodes.reduce(into: [:]) {
        let locale = Locale(identifier: identifier(fromComponents: [NSLocale.Key.countryCode.rawValue: $1.uppercased()]))
        //$0[$1] = (locale.currencyCode, locale.currencySymbol, locale.localizedString(forCurrencyCode: locale.currencyCode ?? ""))
        $0[$1] = locale.currencyCode
    }
}
