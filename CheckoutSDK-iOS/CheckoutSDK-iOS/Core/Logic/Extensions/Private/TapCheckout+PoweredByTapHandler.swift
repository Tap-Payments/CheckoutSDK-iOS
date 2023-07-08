//
//  TapCheckout+PoweredByTapHandler.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 08/07/2023.
//  Copyright © 2023 Tap Payments. All rights reserved.
//

import Foundation
import TapUIKit_iOS

/// Some methods related to dealing with the powered by tap/back button view
internal extension TapCheckout {
    
    /// Will show/hide the back button
    /// - Parameter to: If true, the back button will be visible and false otherwise.
    /// - Parameter with backActionHandler: The action handler to be called when the back button is clicked
    func changeBackButtonVisibility(to:Bool, with backActionHandler:@escaping ()->() = {}) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue:  TapConstantManager.TapBackButtonVisibilityNotification), object: nil, userInfo: [TapConstantManager.TapBackButtonVisibilityNotification:to] )
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue:  TapConstantManager.TapBackButtonBlockNotification), object: nil, userInfo: [TapConstantManager.TapBackButtonBlockNotification:backActionHandler] )
    }
    
}
