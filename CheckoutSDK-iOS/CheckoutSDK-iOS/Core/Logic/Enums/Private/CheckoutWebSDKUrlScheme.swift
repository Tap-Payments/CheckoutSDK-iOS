//
//  CheckoutWebSDKUrlScheme.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 03/05/2023.
//  Copyright © 2023 Tap Payments. All rights reserved.
//

import Foundation

/// An enum to define the values expected the checkout web sdk will route to, to pass info to the native side
internal enum CheckoutWebSDKUrlScheme:String, CaseIterable {
    /// meaning the web sdk is telling us that the popup is being displayed now
    case checkoutWillPresent = "tapcheckoutsdk://checkoutPopupLoaded"
    /// meaning the web sdk is telling us the user closed the popup sdk
    case checkoutIsClosedByUser = "tapcheckoutsdk://closeCheckout"
    /// meaning the web sdk is telling us it has to redirect
    case checkoutWillRedirect = "tapcheckoutsdk://redirectToUrl"
    
    /// Will return the scheme that has the passed prefix as a string
    /// - Parameter with prefix: The prefix you are looking to match
    /// - Returns: The enum that matches the prefix and null otherwise
    static func starts(with prefix:String) -> CheckoutWebSDKUrlScheme? {
        return CheckoutWebSDKUrlScheme.allCases.first(where: { prefix.starts(with: $0.rawValue) })
    }
    
}
