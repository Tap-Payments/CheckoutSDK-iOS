//
//  CurrencyWidgetPositionEnum.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 11/06/2023.
//  Copyright © 2023 Tap Payments. All rights reserved.
//

import Foundation

/// Indicate which position should we display the currency widget in
internal enum CurrencyWidgetPositionEnum {
    /// This means, we need to show beneath the chips horizontal list
    case PaymentChipsList
    /// This means, we need to show beneath the card element
    case Card
}
