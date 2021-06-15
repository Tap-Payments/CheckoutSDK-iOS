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
import CommonDataModelsKit_iOS
import TapUIKit_iOS
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
    
    // MARK:- Public varibales
    /// A protocol to communicate with the Presente tap sheet controller
    @objc public var tapCheckoutScreenDelegate:CheckoutScreenDelegate?
    /// Indicates what to do when using RTL languages
    @objc public static var flippingStatus:TapCheckoutFlipStatus = .FlipOnLoadWithFlippingBack
    /// The ISO 639-1 Code language identefier, please note if the passed locale is wrong or not found in the localisation files, we will show the keys instead of the values
    @objc public static var localeIdentifier:String = "en"
    /// The secret keys providede to your business from TAP.
    @objc public static var secretKey:SecretKey = .init(sandbox: "", production: "")
    
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
     - Parameter paymentType: The allowed payment type inclyding cards, apple pay, web and telecom or ALL
     - Parameter closeButtonStyle: Defines the required style of the sheet close button
     - Parameter showDragHandler: Decide to show the drag handler or not
     - Parameter transactionMode: Decide which transaction mode will be used in this call. Purchase, Authorization, Card Saving and Toknization. Please check [TransactionMode](x-source-tag://TransactionModeEnum)
     - Parameter customer: Decides which customer is performing this transaction. It will help you as a merchant to define the payer afterwards. Please check [TapCustomer](x-source-tag://TapCustomer)
     - Parameter destinations: Decides which destination(s) this transaction's amount should split to. Please check [Destination](x-source-tag://Destination)
     - Parameter tapMerchantID: Optional. Useful when you have multiple Tap accounts and would like to do the `switch` on the fly within the single app.
     - Parameter taxes: Optional. List of Taxes you want to apply to the order if any.
     - Parameter shipping: Optional. List of Shipping you want to apply to the order if any.
     - Parameter allowedCadTypes: Decides the allowed card types whether Credit or Debit or All. If not set all will be accepeted.
     - Parameter postURL: The URL that will be called by Tap system notifying that payment has succeed or failed.
     - Parameter paymentDescription: Description of the payment to use for further analysis and processing in reports.
     - Parameter TapMetadata: Additional information you would like to pass along with the transaction. Please check [TapMetaData](x-source-tag://TapMetaData)
     - Parameter paymentReference: Implement this property to keep a reference to the transaction on your backend. Please check [Reference](x-source-tag://Reference)
     - Parameter paymentStatementDescriptor: Description of the payment  to appear on your settlemenets statement.
     - Parameter require3DSecure: Defines if you want to apply 3DS for this transaction. By default it is set to true.
     - Parameter receiptSettings: Defines how you want to notify about the status of transaction reciept by email, sms or both. Please check [Receipt](x-source-tag://Receipt)
     - Parameter authorizeAction: Defines what to do with the authorized amount after being authorized for a certain time interval. Please check [AuthorizeAction](x-source-tag://AuthorizeAction)
     - Parameter allowsToSaveSameCardMoreThanOnce: Defines if same card can be saved more than once. Default is `true`.
     - Parameter enableSaveCard: Defines if the customer can save his card for upcoming payments. Default is `true`.
     - Parameter isSaveCardSwitchOnByDefault: Defines if save card switch is on by default.. Default is `true`.
     - Parameter sdkMode: Defines the mode sandbox or production the sdk will perform this transaction on. Please check [SDKMode](x-source-tag://SDKMode)
     */
    @objc public func build(
        localiseFile:String? = nil,
        customTheme:TapCheckOutTheme? = nil,
        delegate: CheckoutScreenDelegate? = nil,
        currency:TapCurrencyCode = .USD,
        amount:Double = 1,
        items:[ItemModel] = [],
        applePayMerchantID:String = "merchant.tap.gosell",
        swipeDownToDismiss:Bool = true,
        paymentType:TapPaymentType = .All,
        closeButtonStyle:CheckoutCloseButtonEnum = .title,
        showDragHandler:Bool = false,
        transactionMode: TransactionMode = .purchase,
        customer: TapCustomer = try! .init(emailAddress: TapEmailAddress(emailAddressString: "taptestingemail@gmail.com"), phoneNumber: nil, name: "Tap Testing Default"),
        destinations: [Destination]? = nil,
        tapMerchantID: String? = nil,
        taxes:[Tax] = [],
        shipping:[Shipping] = [],
        allowedCardTypes: [CardType] = [CardType(cardType: .All)],
        postURL:URL? = nil,
        paymentDescription: String? = nil,
        paymentMetadata: TapMetadata = [:],
        paymentReference: Reference? = nil,
        paymentStatementDescriptor: String? = nil,
        require3DSecure: Bool = true,
        receiptSettings: Receipt? = nil,
        authorizeAction: AuthorizeAction = AuthorizeAction.default,
        allowsToSaveSameCardMoreThanOnce: Bool = true,
        enableSaveCard: Bool = true,
        isSaveCardSwitchOnByDefault: Bool = true,
        sdkMode:SDKMode = .sandbox,
        onCheckOutReady: @escaping (TapCheckout) -> () = {_ in}) {
        
        // Do the pre steps needed before starting a new SDK session
        prepareSDK(with: sdkMode,delegate:delegate, localiseFile:localiseFile,customTheme:customTheme)
        // Store the passed configurations for further processing
        configureSharedManager(currency:currency, amount:amount,items:items,applePayMerchantID:applePayMerchantID,swipeDownToDismiss:swipeDownToDismiss,paymentType:paymentType,closeButtonStyle: closeButtonStyle, showDragHandler: showDragHandler,transactionMode: transactionMode,customer: customer,destinations: destinations,tapMerchantID: tapMerchantID,taxes: taxes, shipping: shipping, allowedCardTypes:allowedCardTypes,postURL: postURL, paymentDescription: paymentDescription, paymentMetadata: paymentMetadata, paymentReference: paymentReference, paymentStatementDescriptor: paymentStatementDescriptor,require3DSecure:require3DSecure,receiptSettings:receiptSettings, authorizeAction: authorizeAction)
        // Initiate the needed calls to server to start the session
        initialiseSDKFromAPI()
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
    
    /**
     Used to do the pre steps before initiating a new SDK session
     - Parameter localiseFile: Please pass the name of the custom localisation file if needed. If not set, the normal and default TAP localisations will be used
     - Parameter customTheme: Please pass the tap checkout theme object with the names of your custom theme files if needed. If not set, the normal and default TAP theme will be used
     - Parameter delegate: A protocol to communicate with the Presente tap sheet controller
     - Parameter sdkMode: Defines the mode sandbox or production the sdk will perform this transaction on. Please check [SDKMode](x-source-tag://SDKMode)
     */
    internal func prepareSDK(with sdkMode:SDKMode = .sandbox,
                             delegate:CheckoutScreenDelegate? = nil,
                             localiseFile:String? = nil,
                             customTheme:TapCheckOutTheme? = nil) {
        
        // remove any pending things from an old session
        TapCheckoutSharedManager.destroy()
        // Set the SDK mode and the delegate
        TapCheckoutSharedManager.sharedCheckoutManager().sdkMode = sdkMode
        tapCheckoutScreenDelegate = delegate
        // Init the localsiation manager
        configureLocalisationManager(localiseFile: localiseFile)
        // Init the theme manager
        configureThemeManager(customTheme:customTheme)
    }
    
    /**
     Used to deal with runtime errors in the SDK
     - Parameter error: The error we need to handle and deal with
     */
    internal func handleError(error:Error?) {
        if tapCheckoutControllerViewController?.isBeingPresented ?? false {
            // The sheet is visible and we need to handle this ourselves
            let tapActionButton = TapCheckoutSharedManager.sharedCheckoutManager().tapActionButtonViewModel
            tapActionButton.endLoading(with: false) {
                self.dismissMySelfClicked()
                self.tapCheckoutScreenDelegate?.checkoutFailed?(with: error!)
            }
        }else{
            // The sheet is not yet presented (propaly error occured on init api)
            tapCheckoutScreenDelegate?.checkoutFailed?(with: error!)
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
