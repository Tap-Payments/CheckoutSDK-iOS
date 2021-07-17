//
//  TapCheckout+CDNUrlsGeneration.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/16/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation


extension PaymentOption {
    /// Computed attribute to get the CDN based URL
    internal var imageURL:URL {
        return URL(string: "https://checkoutsdkios.b-cdn.net/\(CDNPath.PaymentOption.generateCDNPath())/\(identifier).png")!
    }
}

extension SavedCard {
    /// Computed attribute to get the CDN based URL
    internal var image:String {
        return "https://checkoutsdkios.b-cdn.net/\(CDNPath.PaymentOption.generateCDNPath())/\(paymentOptionIdentifier ?? "").png"
    }
}

extension AmountedCurrency {
    /// Computed attribute to get the CDN based URL
    internal var cdnFlag:String {
        return "https://checkoutsdkios.b-cdn.net/\(CDNPath.Currency.generateCDNPath())/\(currency.appleRawValue).png"
    }
}

/// An enum to decide what is the pathway for different parts in the checkout sdks
fileprivate enum CDNPath:String {
    
    /// Will hold the path for gateways' and card brands' assets
    case PaymentOption  = "PaymentOption"
    /// Will hold the path for currencies' assets
    case Currency       = "Currency"
    
    /**
     Compute the asset's path depending on the current type and display mode
     - Returns: The pathway for the given type( payment option, currency, etc.) and the current display mode (light or dark)
     */
    func generateCDNPath() -> String {
        // Check first the display mode
        let interfaceStylePath:String = (UIScreen.main.traitCollection.userInterfaceStyle == .light) ? "" : "Dark"
        // Generate the correct path for the current type
        return "\(rawValue)\(interfaceStylePath)"
    }
    
}
