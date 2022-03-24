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
import TapApplicationV2

/// A protocol to comminicate between the UIManager and the data manager
internal protocol TapCheckoutSharedManagerUIDelegate {
    
    /// Inform the ui checkout to dismiss the scanner
    func closeScannerClicked()
    
    /**
     Adds a hint view below a given view
     - Parameter hintView: The hint view to be added
     - Parameter to: The type of the view you want to show the hint below it
     - Parameter animations: A boolean to indicate whether you want to show the hint with animation or right away
     */
    func attach(hintView:TapHintView,to:AnyClass,with animations:Bool)
    
    /**
     Inform the delegate to remove a certain view from the checkout sheet
     - Parameter view: The view required by the data manager to be removed from the checkout sheet
     - Parameter with animation: The animation to remove the view with if any
     */
    func removeView(view:UIView,with animation:TapSheetAnimation?)
    /**
     Inform the delegate to end the loading status of the goPay login
     - Parameter status: If set, means the user has provided correct credentials and is logged in to goPay. Otherwise, he provided wrong ones
     */
    func goPaySignIn(status:Bool)
    
    /**
     Will be fired once the tap sheet content changed its height
     - Parameter newHeight: The new height the content of the Tap sheet has
     */
    func show(alert:UIAlertController)
    
    /**
     Will be fired once we need to ake the button starts/end loading
     - Parameter shouldLoad: True to start loading and false otherwise
     - Parameter success: Will be used in the case of ending loading with the success status
     - Parameter onComplete: Logic block to execute after stopping loading
     */
    func actionButton(shouldLoad:Bool,success:Bool,onComplete:@escaping()->())
    
    /**
     Will be fired once the checkout process faild and we need to dismiss
     - Parameter with error:  The error cause the checkout process to fail
     */
    func dismissCheckout(with error:Error)
    
    /**
     Will be fired when we want the checkout controller to show a webview
     - Parameter with url: The url we want to load
     - Parameter and navigationDelegate: The navigationDelegate to handle the webview navigation flow
     */
    func showWebView(with url:URL,and navigationDelegate:TapWebViewModelDelegate?)
    
    /**
     Will be fired in case we want to close/hide the currently shown web view in the checkout controller
     */
    func closeWebView()
    
    /**
     Will be fired in case we want to show saved card otp view
     - Parameter with authenticationID: The authentication process ID if any
     */
    func showSavedCardOTPView(with authenticationID:String)
    
    /**
     Will be fired in case we want to disable/enable interaction with the checkout sheet itself to prevent actions while calling the api for example
     - Parameter with status: if true then enable if false then disable the checkout's interaction capabilty
     */
    func enableInteraction(with status:Bool)
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
    /// Indicates whether we  can load assets from CDN or not
    internal var canLoadFromCDN:Bool = false
    /// The tap bottom sheet reference
    internal var bottomSheetController = TapBottomSheetDialogViewController()
    /// A reference to the localisation manager
    internal var sharedLocalisationManager = TapLocalisationManager.shared
    /// A reference to the TapCheckoutController that will present the TapSheet
    internal var tapCheckoutControllerViewController:TapBottomCheckoutControllerViewController?
    /// A protocol to comminicate between the UIManager and the data manager
    internal var UIDelegate:TapCheckoutSharedManagerUIDelegate?
    /// Represents a global accessable common data gathered by the merchant when loading the checkout sdk like amount, currency, etc
    internal static var privateShared : TapCheckout?
    /// Represents the default item name. We will use this default item name when the user doesn't pass any items. It is required to have them in the format of items to make it readable by Apple Pay Requests. Please check [DefaultItemsCreation](x-source-tag://DefaultItemsCreation)
    internal static var defaulItemTitle:String = "PAY TO TAP PAYMENTS"
    /// Represents a block to execute after dismissing the sheet if any
    internal var toBeExecutedBlock:()->() = {}
    /// The current SDK version
    internal static var sdkVersion:String? {
        return TapBundlePlistInfo(bundle: Bundle(for: TapCheckout.self)).shortVersionString
    }
    
    // MARK:- View Models Variables
    var dataHolder:DataHolder = .init(viewModels: ViewModelsHolder.init(), transactionData: .init())
    
    // MARK:- Public varibales
    /// A protocol to communicate with the Presente tap sheet controller
    @objc public var tapCheckoutScreenDelegate:CheckoutScreenDelegate?
    /// Indicates whether the checkout sheet is presented or not
    internal static var isCheckoutSheenPresented:Bool = false
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
     - Parameter localiseFile: Please pass the name of the custom localisation file model if needed. If not set, the normal and default TAP localisations will be used
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
     - Parameter enableApiLogging: Defines if you want to print the api calls. This is very helpful for you as a developer
     */
    @objc public func build(
        localiseFile:TapCheckoutLocalisation? = nil,
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
        customer: TapCustomer = try! .init(identifier: "cus_TS031720211012r4RM0403926"),
        destinations: [Destination]? = nil,
        tapMerchantID: String? = nil,
        taxes:[Tax]? = nil,
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
        enableApiLogging:Bool = true,
        onCheckOutReady: @escaping (TapCheckout) -> () = {_ in}) {
        
        // Do the pre steps needed before starting a new SDK session
        prepareSDK(with: sdkMode,delegate:delegate, localiseFile:localiseFile, customTheme:customTheme, enableApiLogging:enableApiLogging)
        // Store the passed configurations for further processing
        configureSharedManager(currency:currency, amount:amount,items:items,applePayMerchantID:applePayMerchantID,swipeDownToDismiss:swipeDownToDismiss,paymentType:paymentType,closeButtonStyle: closeButtonStyle, showDragHandler: showDragHandler,transactionMode: transactionMode,customer: customer,destinations: destinations,tapMerchantID: tapMerchantID,taxes: taxes, shipping: shipping, allowedCardTypes:allowedCardTypes,postURL: postURL, paymentDescription: paymentDescription, paymentMetadata: paymentMetadata, paymentReference: paymentReference, paymentStatementDescriptor: paymentStatementDescriptor,require3DSecure:require3DSecure,receiptSettings:receiptSettings, authorizeAction: authorizeAction,allowsToSaveSameCardMoreThanOnce: allowsToSaveSameCardMoreThanOnce, enableSaveCard: enableSaveCard, isSaveCardSwitchOnByDefault: isSaveCardSwitchOnByDefault)
        
        // Initiate the needed calls to server to start the session
        configSDKFromAPI() {  [weak self] in
            //guard let nonNullSelf = self else { return }
            self!.configureBottomSheet()
            onCheckOutReady(self!)
        }
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
     Creates a shared instance of the CheckoutDataManager
     - Returns: The shared checkout manager
     */
    internal class func sharedCheckoutManager() -> TapCheckout { // change class to final to prevent override
        guard let uwShared = privateShared else {
            privateShared = TapCheckout()
            return privateShared!
        }
        return uwShared
    }
    
    /**
     Used to do the pre steps before initiating a new SDK session
     - Parameter localiseFile: Please pass the name of the custom localisation model if needed. If not set, the normal and default TAP localisations will be used
     - Parameter customTheme: Please pass the tap checkout theme object with the names of your custom theme files if needed. If not set, the normal and default TAP theme will be used
     - Parameter delegate: A protocol to communicate with the Presente tap sheet controller
     - Parameter sdkMode: Defines the mode sandbox or production the sdk will perform this transaction on. Please check [SDKMode](x-source-tag://SDKMode)
     - Parameter enableApiLogging: Defines if you want to print the api calls. This is very helpful for you as a developer
     */
    internal func prepareSDK(with sdkMode:SDKMode = .sandbox,
                             delegate:CheckoutScreenDelegate? = nil,
                             localiseFile:TapCheckoutLocalisation? = nil,
                             customTheme:TapCheckOutTheme? = nil,
                             enableApiLogging:Bool = true) {
        
        // remove any pending things from an old session
        TapCheckout.destroy()
        // Decide the availability of the CDN
        TapCheckout.sharedCheckoutManager().decideIfWeCanLoadAssetsFromCDN()
        // Set the SDK mode and the delegate
        TapCheckout.sharedCheckoutManager().dataHolder.transactionData.sdkMode = sdkMode
        TapCheckout.sharedCheckoutManager().tapCheckoutScreenDelegate = delegate
        // Init the localsiation manager
        configureLocalisationManager(localiseFile: localiseFile)
        // Init the theme manager
        configureThemeManager(customTheme:customTheme)
        // Listen to events from network manager
        NetworkManager.shared.delegate = TapCheckout.sharedCheckoutManager()
        // Adjust the logging ability
        NetworkManager.shared.enableLogging = enableApiLogging
        NetworkManager.shared.consoleLogging = enableApiLogging
    }
    
    /**
     Used to deal with runtime errors in the SDK
     - Parameter error: The error we need to handle and deal with
     */
    internal func handleError(error:Error?) {
        
        let loggedDataModel:TapLogRequestModel = .init(application: .init(), customer: TapCheckout.sharedCheckoutManager().dataHolder.transactionData.customer, merchant: .init(), stack_trace: NetworkManager.shared.loggedApis, error_catgeroy: error?.localizedDescription)
        
        callLogging(for: loggedDataModel)
        
        TapCheckout.sharedCheckoutManager().toBeExecutedBlock = {
            TapCheckout.sharedCheckoutManager().tapCheckoutScreenDelegate?.checkoutFailed?(with: (error! as NSError))
        }
        
        if TapCheckout.isCheckoutSheenPresented {
            dataHolder.viewModels.tapActionButtonViewModel.endLoading(with: false, completion: {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    self.UIDelegate?.dismissCheckout(with: error ?? "UNKNOWN ERROR OCCURED")
                }
            })
        }else{
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                //self.UIDelegate?.dismissCheckout(with: error ?? "UNKNOWN ERROR OCCURED")
                TapCheckout.sharedCheckoutManager().tapCheckoutScreenDelegate?.tapBottomSheetWillDismiss?()
                TapCheckout.sharedCheckoutManager().tapBottomSheetDismissed()
                self.bottomSheetController.dismissTheController()
            }
        }
    }
}
