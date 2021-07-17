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
        // Compute the url based on the current user interface style
        let interfaceStylePath:String = (UIScreen.main.traitCollection.userInterfaceStyle == .light) ? "" : "Dark"
        return URL(string: "https://checkoutsdkios.b-cdn.net/\(CDNPath.PaymentOption.rawValue)/\(identifier)\(interfaceStylePath).png")!
    }
}

fileprivate enum CDNPath:String {
    
    case PaymentOption  = "PaymentOption"
    case Currency       = "Currency"
    
}
