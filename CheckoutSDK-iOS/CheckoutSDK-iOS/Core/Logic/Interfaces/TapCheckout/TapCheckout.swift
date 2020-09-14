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
import class RxSwift.DisposeBag
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
    func dismissMySelfClicked()
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
    /// A reference to the TapCheckoutController that will present the TapSheet
    internal var tapCheckoutControllerViewController:TapBottomCheckoutControllerViewController?
    /// A RX garbage collector
    internal let disposeBag:DisposeBag = .init()
    
    // MARK:- Public varibales
    /// A protocol to communicate with the Presente tap sheet controller
    @objc public var tapCheckoutScreenDelegate:CheckoutScreenDelegate?
    /// Indicates what to do when using RTL languages
    @objc public static var flippingStatus:TapCheckoutFlipStatus = .FlipOnLoadWithFlippingBack
    /// The ISO 639-1 Code language identefier, please note if the passed locale is wrong or not found in the localisation files, we will show the keys instead of the values
    @objc public static var localeIdentifier:String = "en"
    
    // MARK:- Internal functions
    
    
    // MARK:- Public functions
    /**
     Defines the tap checkout bottom sheet controller
     - Parameter localiseFile: Please pass the name of the custom localisation file if needed. If not set, the normal and default TAP localisations will be used
     - Parameter customTheme: Please pass the tap checkout theme object with the names of your custom theme files if needed. If not set, the normal and default TAP theme will be used
     - Parameter delegate: A protocol to communicate with the Presente tap sheet controller
     - Parameter currency: Represents the original transaction currency stated by the merchant on checkout start
     - Parameter amount: Represents the original total transaction amount stated by the merchant on checkout start
     - Parameter items: Represents the List of payment items if any. If no items are provided one will be created by default as PAY TO [MERCHANT NAME] -- Total value
     - Parameter applePayMerchantID: The Apple pay merchant id to be used inside the apple pay kit
     - Parameter onCheckOutReady: This will be called once the checkout is ready so you can use it to present it or cancel it
     - Parameter swipeDownToDismiss: If it is set then when the user swipes down the payment will close, otherwise, there will be a shown button to dismiss the screen. Default is false
     - Parameter paymentTypes: The allowed payment types inclyding cards, apple pay, web and telecom
     */
    public func build(localiseFile:String? = nil,customTheme:TapCheckOutTheme? = nil,delegate: CheckoutScreenDelegate? = nil,currency:TapCurrencyCode = .USD,amount:Double = 1,items:[ItemModel] = [],applePayMerchantID:String = "merchant.tap.gosell",swipeDownToDismiss:Bool = true, paymentTypes:[TapPaymentType] = [.All], onCheckOutReady: @escaping (TapCheckout) -> () = {_ in}){
        TapCheckoutSharedManager.destroy()
        tapCheckoutScreenDelegate = delegate
        configureLocalisationManager(localiseFile: localiseFile)
        configureThemeManager(customTheme:customTheme)
        
        NetworkManager.shared.makeApiCall(routing: .IntentAPI, resultType: TapIntentResponseModel.self) { (session, result, error) in
            guard let intentModel:TapIntentResponseModel = result as? TapIntentResponseModel else { return }
            self.configureSharedManager(currency:currency, amount:amount,items:items,applePayMerchantID:applePayMerchantID,intentModel:intentModel,swipeDownToDismiss:swipeDownToDismiss,paymentTypes:paymentTypes)
            self.configureBottomSheet()
            onCheckOutReady(self)
        }
    }
    
    
    /**
     Defines the tap checkout bottom sheet controller
     - Parameter localiseFile: Please pass the name of the custom localisation file if needed. If not set, the normal and default TAP localisations will be used
     - Parameter customTheme: Please pass the tap checkout theme object with the names of your custom theme files if needed. If not set, the normal and default TAP theme will be used
     - Parameter delegate: A protocol to communicate with the Presente tap sheet controller
     - Parameter currency: Represents the original transaction currency stated by the merchant on checkout start
     - Parameter amount: Represents the original total transaction amount stated by the merchant on checkout start
     - Parameter items: Represents the List of payment items if any. If no items are provided one will be created by default as PAY TO [MERCHANT NAME] -- Total value
     - Parameter applePayMerchantID: The Apple pay merchant id to be used inside the apple pay kit
     - Parameter onCheckOutReady: This will be called once the checkout is ready so you can use it to present it or cancel it
     - Parameter swipeDownToDismiss: If it is set then when the user swipes down the payment will close, otherwise, there will be a shown button to dismiss the screen. Default is false
     - Parameter paymentTypes: The allowed payment types inclyding cards, apple pay, web and telecom
     */
    @objc public func buildCheckout(localiseFile:String? = nil,customTheme:TapCheckOutTheme? = nil,delegate: CheckoutScreenDelegate? = nil,currency:TapCurrencyCode = .USD,amount:Double = 1,items:[ItemModel] = [],applePayMerchantID:String = "merchant.tap.gosell",swipeDownToDismiss:Bool = false, paymentTypes:[Int] = [TapPaymentType.All.rawValue], onCheckOutReady: @escaping (TapCheckout) -> () = {_ in}) {
        
        self.build(localiseFile: localiseFile, customTheme: customTheme, delegate: delegate, currency: currency, amount: amount, items: items, applePayMerchantID: applePayMerchantID, swipeDownToDismiss: swipeDownToDismiss, paymentTypes: paymentTypes.map{ TapPaymentType.init(rawValue: $0)! }, onCheckOutReady: onCheckOutReady)
    }
    
    
    /**
     Starts the TapCheckout UIView in the required viewcontroller
     - Parameter controller: This is th view controller you want to show the tap checkout in
     */
    @objc public func start(presentIn controller:UIViewController?) {
        guard let controller = controller else { return }
        DispatchQueue.main.async { [weak self] in
            controller.present(self!.bottomSheetController, animated: true, completion: nil)
        }
    }
}

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
        tapCheckoutScreenDelegate?.tapBottomSheetPresented?()
    }
    
    public func tapBottomSheetWillDismiss() {
        // If it is allowed, then we need to start the dismissing of the checkout screen
        if TapCheckout.flippingStatus == .FlipOnLoadWithFlippingBack {
            MOLH.setLanguageTo("en")
        }
        tapCheckoutScreenDelegate?.tapBottomSheetWillDismiss?()
    }
    
    
    public func shallSwipeToDismiss() -> Bool {
        // Make sure if the swipe down is enabled or not
        let sharedManager = TapCheckoutSharedManager.sharedCheckoutManager()
        return sharedManager.swipeDownToDismiss
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
        bottomSheetController.dismissTheController()
    }
    
    func changeHeight(to newHeight: CGFloat) {
        bottomSheetController.changeHeight(to: newHeight)
    }
}
