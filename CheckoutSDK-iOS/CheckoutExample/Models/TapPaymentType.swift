//
//  TapPaymentType.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/26/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation

/// Indicates the payment types for checkout sdk
@objc public enum TapPaymentType: Int {
    case All
    case Card
    case Web
    case ApplePay
    case Telecom
}
