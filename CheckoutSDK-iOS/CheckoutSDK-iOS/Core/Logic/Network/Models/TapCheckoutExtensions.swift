//
//  TapCheckoutExtensions.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/19/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
import PassKit
import CommonDataModelsKit_iOS

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int?) -> Double {
        guard let places = places else {
            return self
        }

        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}


