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
}
