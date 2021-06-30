//
//  TapCheckoutManager+WebPaymentHandler.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/18/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// Logic to handle webviews based gateway
extension TapCheckout {
    
    struct WebPaymentHandlerConstants {
        
        static let returnURL = URL(string: "gosellsdk://return_url")!
        static let tapIDKey = "tap_id"
        
        //@available(*, unavailable) private init() { fatalError("This struct cannot be instantiated.") }
    }
    
}
