//
//  TapCheckout+Protocols.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/20/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import LocalisationManagerKit_iOS
//import MOLH
import CommonDataModelsKit_iOS
import TapUIKit_iOS
import TapThemeManager2020

//MARK: TapCheckout Protocols

/// A protocol to communicate with the Presente tap sheet controller
@objc public protocol CheckoutScreenDelegate {
    
    /// Inform the delegate that we may need log some strings for further analysis
    @objc optional func log(string:String)
    
    /**
     Will be fired just before the sheet is dismissed
     */
    @objc optional func tapBottomSheetWillDismiss()
    /**
     Will be fired once the controller is presented
     */
    @objc optional func tapBottomSheetPresented(viewController:UIViewController?)
    /**
     Will be fired once the checkout fails for any error
     */
    @objc optional func checkoutFailed(in session:URLSessionDataTask?, for result:[String:String]?, with error:Error?)
    
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
     Will be fired once apply pay tokenization fails
     */
    @objc optional func applePayTokenizationFailed(in session:URLSessionDataTask?, for result:[String:String]?, with error:Error?)
    
    /**
     Will be fired once card tokenization fails
     */
    @objc optional func cardTokenizationFailed(in session:URLSessionDataTask?, for result:[String:String]?, with error:Error?)
    
    /**
     Will be fired once save card tokenization fails
     */
    @objc optional func saveCardTokenizationFailed(in session:URLSessionDataTask?, for result:[String:String]?, with error:Error?)
    
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
    /**
     Will be fired once the tap sheet content needs to reduce its height in preparing to removing a view
     - Parameter newHeight: The height to be reduced
     */
    func reduceHeight(by newHeight:CGFloat)
    /// Fired whenever we want to dismiss the checkout screen
    func dismissMySelfClicked()
    
}


//MARK: TapCheckout Registered Protocols

extension TapCheckout:TapBottomSheetDialogDataSource {
    
    public func tapBottomSheetBackGroundColor() -> UIColor? {
        return .clear// TapThemeManager.colorValue(for: "TapVerticalView.backgroundOverlayColor") ?? .clear
    }
    
    public func tapBottomSheetBlurEffect() -> UIBlurEffect? {
        return nil//.init(style: .systemUltraThinMaterialDark)
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
    
    
    public func tapBottomSheetPresented(viewController:UIViewController?) {
        TapCheckout.isCheckoutSheenPresented = true
        TapCheckout.sharedCheckoutManager().tapCheckoutScreenDelegate?.tapBottomSheetPresented?(viewController: viewController)
    }
    
    public func tapBottomSheetWillDismiss() {
        TapCheckout.isCheckoutSheenPresented = false
        // If it is allowed, then we need to start the dismissing of the checkout screen
        if TapCheckout.flippingStatus == .FlipOnLoadWithFlippingBack {
            //MOLH.setLanguageTo("en")
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
    
    public func tapBottomSheetDismissed() {
        DispatchQueue.main.async {
            TapCheckout.sharedCheckoutManager().toBeExecutedBlock()
        }
    }
    
    public func tapBottomSheetHeightChanged(with newHeight: CGFloat) {
        // compute the minimum neede height
        let minimumNeededHeight = TapCheckout.sharedCheckoutManager().UIDelegate?.minimumNeededHeight() ?? 400
        // Check if the user moved it to a lower point than the required minimum, then we ask it to bounce back to the minimum height needed
        if newHeight < minimumNeededHeight {
            changeHeight(to: minimumNeededHeight)
        }
    }
}


extension TapCheckout : ToPresentAsPopupViewControllerDelegate {
    func reduceHeight(by newHeight: CGFloat) {
        bottomSheetController.reduceHeight(by: newHeight)
    }
    
    
    func dismissMySelfClicked() {
        //tapCheckoutControllerViewController?.dismiss(animated: true, completion: nil)
        TapCheckout.sharedCheckoutManager().tapCheckoutScreenDelegate?.tapBottomSheetWillDismiss?()
        bottomSheetController.dismissTheController()
    }
    
    func changeHeight(to newHeight: CGFloat) {
        bottomSheetController.changeHeight(to: newHeight)
    }
}
