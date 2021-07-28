//
//  TapCheckout+Protocols.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/20/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import LocalisationManagerKit_iOS
import MOLH
import CommonDataModelsKit_iOS
import TapUIKit_iOS

//MARK: TapCheckout Protocols

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
    /**
     Will be fired once the checkout fails for any error
     */
    @objc optional func checkoutFailed(with error:Error)
    
    /**
     Will be fired once the charge (CAPTURE) successfully transacted
     */
    @objc(checkoutChargeCaptured:) optional func checkoutCaptured(with charge:Charge)
    
    /**
     Will be fired once the charge (AUTHORIZE) successfully transacted
     */
    @objc(checkoutAuthorizeCaptured:) optional func checkoutCaptured(with authorize:Authorize)
    
    /**
     Will be fired once the charge (CAPTURE) successfully transacted
     */
    @objc(checkoutChargeFailed:) optional func checkoutFailed(with charge:Charge)
    
    /**
     Will be fired once the charge (AUTHORIZE) successfully transacted
     */
    @objc(checkoutAuthorizeFailed:) optional func checkoutFailed(with authorize:Authorize)
    
    
    /**
     Will be fired once the card is succesfully tokenized
     */
    @objc optional func cardTokenized(with token:Token)
    
    
    /**
     Will be fired once the save card is done
     */
    @objc optional func saveCardSuccessfull(with savedCard:TapCreateCardVerificationResponseModel)
    
    /**
     Will be fired once the save card failed
     */
    @objc optional func saveCardFailed(with savedCard:TapCreateCardVerificationResponseModel)
    
}


/// A protocol to communicate with the Presente tap sheet controller
internal protocol  ToPresentAsPopupViewControllerDelegate {
    /**
     Will be fired once the tap sheet content changed its height
     - Parameter newHeight: The new height the content of the Tap sheet has
     */
    func changeHeight(to newHeight:CGFloat)
    /// Fired whenever we want to dismiss the checkout screen
    func dismissMySelfClicked()
    
}


//MARK: TapCheckout Registered Protocols

extension TapCheckout:TapBottomSheetDialogDataSource {
    
    public func tapBottomSheetBackGroundColor() -> UIColor? {
        return bottomSheetBackgroundColor
    }
    
    public func tapBottomSheetViewControllerToPresent() -> UIViewController? {
        tapCheckoutControllerViewController = .init()
        tapCheckoutControllerViewController?.delegate = self
        return tapCheckoutControllerViewController
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
        TapCheckout.isCheckoutSheenPresented = true
        TapCheckout.sharedCheckoutManager().tapCheckoutScreenDelegate?.tapBottomSheetPresented?()
    }
    
    public func tapBottomSheetWillDismiss() {
        TapCheckout.isCheckoutSheenPresented = false
        // If it is allowed, then we need to start the dismissing of the checkout screen
        if TapCheckout.flippingStatus == .FlipOnLoadWithFlippingBack {
            MOLH.setLanguageTo("en")
        }
        TapCheckout.sharedCheckoutManager().tapCheckoutScreenDelegate?.tapBottomSheetWillDismiss?()
    }
    
    
    public func shallSwipeToDismiss() -> Bool {
        // Make sure if the swipe down is enabled or not
        let sharedManager = TapCheckout.sharedCheckoutManager()
        return sharedManager.dataHolder.viewModels.swipeDownToDismiss
    }
    
    public func tapBottomSheetDidTapOutside() {
        bottomSheetController.view.endEditing(true)
    }
    
    public func tapBottomSheetHeightChanged(with newHeight: CGFloat) {
    }
    
}


extension TapCheckout : ToPresentAsPopupViewControllerDelegate {
    
    func dismissMySelfClicked() {
        //tapCheckoutControllerViewController?.dismiss(animated: true, completion: nil)
        TapCheckout.sharedCheckoutManager().tapCheckoutScreenDelegate?.tapBottomSheetWillDismiss?()
        bottomSheetController.dismissTheController()
    }
    
    func changeHeight(to newHeight: CGFloat) {
        bottomSheetController.changeHeight(to: newHeight)
    }
}
