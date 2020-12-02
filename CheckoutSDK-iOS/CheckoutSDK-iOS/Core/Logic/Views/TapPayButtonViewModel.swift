//
//  TapPayButton.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/24/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
import TapUIKit_iOS

@objc public class TapPayButtonViewModel:TapActionButtonViewModel {
    
    public override init() {
        super.init()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: TapConstantManager.TapActionSheetStatusNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: TapConstantManager.TapActionSheetBlockNotification), object: nil)
    }
}
