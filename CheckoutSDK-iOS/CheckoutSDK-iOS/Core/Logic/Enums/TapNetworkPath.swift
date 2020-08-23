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
    /// Loading the merchant info
    case EntitAPI = "a80dc488-2cdd-4e0b-a083-afb269ba89d8"
    case CurrenciesAPI = "e221998f-b505-4131-b236-3aff57043fcc"
}
