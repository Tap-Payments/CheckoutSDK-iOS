//
//  TapCheckout.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/3/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation

/// A protocol to communicate with the Presente tap sheet controller
internal protocol  ToPresentAsPopupViewControllerDelegate {
    /**
     Will be fired once the tap sheet content changed its height
     - Parameter newHeight: The new height the content of the Tap sheet has
     */
    func changeHeight(to newHeight:CGFloat)
}


@objc public class TapCheckout: NSObject {
    
    internal var bottomSheetBackgroundColor:UIColor? = .init(white: 0, alpha: 0.5)
    internal var bottomSheetBlurEffect:UIBlurEffect? = nil
    internal var dismissWhenClickOutSide:Bool = false
    internal var initialHeight:CGFloat = 100
    internal var cornerRadius:CGFloat = 12
    internal var bottomSheetController = TapBottomSheetDialogViewController()
    
    /**
     Defines the tap checkout bottom sheet controller
     - Returns: The tap checkout bottom sheet controller you need to show afterwards
     */
    @objc public func startCheckoutSDK() -> UIViewController {
        bottomSheetController = TapBottomSheetDialogViewController()
        bottomSheetController.dataSource = self
        bottomSheetController.delegate = self
        bottomSheetController.modalPresentationStyle = .overCurrentContext
        TapThemeManager.setDefaultTapTheme()
        return bottomSheetController
    }
}

extension TapCheckout:TapBottomSheetDialogDataSource {
    
    public func tapBottomSheetBackGroundColor() -> UIColor? {
        return bottomSheetBackgroundColor
    }
    
    public func tapBottomSheetBlurEffect() -> UIBlurEffect? {
        return bottomSheetBlurEffect
    }
    
    public func tapBottomSheetViewControllerToPresent() -> UIViewController? {
        let controller = TapBottomCheckoutControllerViewController.init()
        controller.delegate = self
        return controller
    }
    
    public func tapBottomSheetShouldAutoDismiss() -> Bool {
        return dismissWhenClickOutSide
    }
    
    
    public func tapBottomSheetInitialHeight() -> CGFloat {
        return initialHeight
    }
    
    public func tapBottomSheetControllerRadious() -> CGFloat {
        return cornerRadius
    }
    
    public func tapBottomSheetRadiousCorners() -> CACornerMask {
        return [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    public func tapBottomSheetStickingPoints() -> [CGFloat] {
        return [20,100,200,300,400,500,600]
    }
}


extension TapCheckout: TapBottomSheetDialogDelegate {
    
    
    public func tapBottomSheetPresented() {
    }
    
    public func tapBottomSheetWillDismiss() {
    }
    
    public func tapBottomSheetDidTapOutside() {
        bottomSheetController.view.endEditing(true)
    }
    
    public func tapBottomSheetHeightChanged(with newHeight: CGFloat) {
    }
    
}


extension TapCheckout : ToPresentAsPopupViewControllerDelegate {
    func changeHeight(to newHeight: CGFloat) {
        bottomSheetController.changeHeight(to: newHeight)
    }
}
