//
//  TapCheckout.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/3/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
import LocalisationManagerKit_iOS
import MOLH
/// A protocol to communicate with the Presente tap sheet controller
@objc public protocol CheckoutScreenDelegate {
    /**
     Will be fired just before the sheet is dismissed
     */
    @objc optional func tapBottomSheetWillDismiss()
    /**
     Will be fired once the controller is presented
     */
    @objc optional func tapBottomSheetPresented()
}


/// A protocol to communicate with the Presente tap sheet controller
internal protocol  ToPresentAsPopupViewControllerDelegate {
    /**
     Will be fired once the tap sheet content changed its height
     - Parameter newHeight: The new height the content of the Tap sheet has
     */
    func changeHeight(to newHeight:CGFloat)
}


/// The public interface to deal and start the TapCheckout SDK/UI
@objc public class TapCheckout: NSObject {
    
    // MARK:- Internal varibales
    
    /// Reference to the color of the dimming of the tap sheet controller
    internal var bottomSheetBackgroundColor:UIColor? = .init(white: 0, alpha: 0.5)
    /// Initial height to start the sheet with
    internal var initialHeight:CGFloat = 100
    /// The corner radius of the sheet
    internal var cornerRadius:CGFloat = 12
    /// The tap bottom sheet reference
    internal var bottomSheetController = TapBottomSheetDialogViewController()
    /// A reference to the localisation manager
    internal var sharedLocalisationManager = TapLocalisationManager.shared
    
    
    
    // MARK:- Public varibales
    /// A protocol to communicate with the Presente tap sheet controller
    @objc public var tapCheckoutScreenDelegate:CheckoutScreenDelegate?
    /// Indicates what to do when using RTL languages
    @objc public static var flippingStatus:TapCheckoutFlipStatus = .FlipOnLoadWithFlippingBack
    /// The ISO 639-1 Code language identefier, please note if the passed locale is wrong or not found in the localisation files, we will show the keys instead of the values
    @objc public static var localeIdentifier:String = "en"
    
    // MARK:- Internal functions
    
    /// Configures the bottom sheet by creating one and assigning the correct delegates and datasources
    internal func configureBottomSheet() {
        // Create the sheet itself
        bottomSheetController = TapBottomSheetDialogViewController()
        bottomSheetController.dataSource = self
        bottomSheetController.delegate = self
        bottomSheetController.modalPresentationStyle = .overCurrentContext
        // Make sure the theme is applied or we apply the default theme
        guard let _ = TapThemeManager.currentTheme else {
            TapThemeManager.setDefaultTapTheme()
            return
        }
        
        // Set the required locale
        sharedLocalisationManager.localisationLocale = TapCheckout.localeIdentifier
        // Adjust the flipping
        if TapCheckout.flippingStatus != .NoFlipping {
            MOLH.setLanguageTo(TapCheckout.localeIdentifier)
        }
    }
    
    // MARK:- Public functions
    /**
     Defines the tap checkout bottom sheet controller
     - Returns: The tap checkout bottom sheet controller you need to show afterwards
     */
    @objc public func startCheckoutSDK() -> UIViewController {
        configureBottomSheet()
        return bottomSheetController
    }
}

extension TapCheckout:TapBottomSheetDialogDataSource {
    
    public func tapBottomSheetBackGroundColor() -> UIColor? {
        return bottomSheetBackgroundColor
    }
    
    public func tapBottomSheetViewControllerToPresent() -> UIViewController? {
        let controller = TapBottomCheckoutControllerViewController.init()
        controller.delegate = self
        return controller
    }
    
    public func tapBottomSheetShouldAutoDismiss() -> Bool {
        return false
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
        tapCheckoutScreenDelegate?.tapBottomSheetPresented?()
    }
    
    public func tapBottomSheetWillDismiss() {
        if TapCheckout.flippingStatus == .FlipOnLoadWithFlippingBack {
            MOLH.setLanguageTo("en")
        }
        tapCheckoutScreenDelegate?.tapBottomSheetWillDismiss?()
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
