//
//  TapNetworkPath.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/22/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation

/// Represents a routing enum, which will has the end point of each needed request
internal enum TapNetworkPath : String {
    /// Loading the Intent API
    case IntentAPI = "5720fa1c-9b7e-4b68-810f-dbb79228405c"
    //case IntentAPI = "7b0b86c3-1e22-40f7-bf28-ad0ae58c391d" // case IntentAPI = "5720fa1c-9b7e-4b68-810f-dbb79228405c"
    /// Login to GoPay
    case GoPayLoginAPI = "7ffceaa7-0b86-4a18-88bb-c157c9a27aae"
    /// Calling INIT api which is the kickstart for a starting a new session and construct a connection with the backend
    case InitAPI                    = "init"
    /// Calling PAYMENT OPTIONS api which is needed to have all the info to configure the view models of the checkout SDK
    case PaymentOptionsAPI          = "payment/types/"
    /// Calling Authorize card api which is needed to authorize a certain card
    case authorize                  = "authorize/"
    /// Calling Billing address card api
    case billingAddress             = "billing_address/"
    /// Calling card bin lookup api which is needed to get info about a card
    case bin                        = "bin/"
    /// Calling card api which is needed to get info about a card
    case card                       = "card/"
    /// Calling card   which is needed to verify the details of a card
    case cardVerification           = "card/verify/"
    /// Calling charges ap   which is needed to execute and perform a certain charge
    case charges                    = "charges/"
    /// Calling customers api   which is needed to get the customers list
    case customers                  = "customers/"
    /// Calling token api to tokenize
    case token                      = "token/"
    /// Calling token api to tokenize
    case tokens                     = "tokens/"
}
