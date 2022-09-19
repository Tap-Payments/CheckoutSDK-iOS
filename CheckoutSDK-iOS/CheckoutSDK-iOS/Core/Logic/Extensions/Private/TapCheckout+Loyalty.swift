//
//  TapCheckout+Loyalty.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 18/09/2022.
//  Copyright © 2022 Tap Payments. All rights reserved.
//

import Foundation
import TapUIKit_iOS
import CommonDataModelsKit_iOS

/// Logic to handle callbacks from the loyalty widget
extension TapCheckout: TapLoyaltyDelegate {
    public func changeLoyaltyEnablement(to: Bool) {
        guard let nonNullViewModel = dataHolder.viewModels.tapLoyaltyViewModel else {
            return
        }
        if !to {
            UIDelegate?.removeView(view: nonNullViewModel.attachedView, with: nil)
            UIDelegate?.showLoyalty(with: nonNullViewModel,animate: false)
        }else {
            
        }
    }
    
    public func changeLoyaltyAmount(to: Double) {
        
    }
    
}
