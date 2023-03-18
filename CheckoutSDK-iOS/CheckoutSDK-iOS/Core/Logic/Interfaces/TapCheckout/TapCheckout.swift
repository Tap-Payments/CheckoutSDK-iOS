//
//  TapCheckout.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/3/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
import LocalisationManagerKit_iOS
//import MOLH
import CommonDataModelsKit_iOS
import TapUIKit_iOS
import TapApplicationV2
import PassKit
import TapApplePayKit_iOS
import BugfenderSDK

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
     - Parameter for webViewType: An enum to state all the possible ways to display a web view inside.
     */
    func showWebView(with url:URL,and navigationDelegate:TapWebViewModelDelegate?,for webViewType:WebViewTypeEnum)
    
    /**
     Will be fired when we want the checkout controller to show a async payment view confirmation
     - Parameter merchantModel: The merchant data
     - Parameter chargeModel: The charge data
     */
    func showAsyncView(merchantModel:TapMerchantHeaderViewModel, chargeModel:Charge)
    
    /**
     Will be fired in case we want to close/hide the currently shown web view in the checkout controller
     */
    func closeWebView()
    
    /**
     Will be fired in case we want to close/hide the currently shown web view in the checkout controller
     */
    func cancelWebView(showingFullScreen:Bool)
    
    /**
     Will be fired in case we want to hide/remove a loyalty widget
     */
    func hideLoyalty()
    
    /**
     Will be fired in case we want to hide/remove a customer contact data collection widget
     */
    func hideCustomerContactDataCollection()
    
    /**
     Will be fired in case we want to show  a loyalty widget
     - Parameter with loyaltyViewModel: The view model for the loyalty widget we want to show
     - Parameter animate: If true a fade in animation will be done while inserting the view, otherwise no animation will be used
     */
    func showLoyalty(with loyaltyViewModel: TapLoyaltyViewModel,animate:Bool)
    
    /**
     Will be fired in case we want to show  customer contact data collection
     - Parameter with customerDataViewModel: The view model that controls the customer contact data collection view
     - Parameter and customerShippingViewModel: The view model that controls the customer shipping data collection view
     - Parameter animate: If true a fade in animation will be done while inserting the view, otherwise no animation will be used
     */
    func showCustomerContactDataCollection(with customerDataViewModel: CustomerContactDataCollectionViewModel, and customerShippingViewModel: CustomerShippingDataCollectionViewModel, animate:Bool)
    
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
    
    /// Will be fired in case you want to do the pre-3d animations.
    /// It will remove all other sub views except the card form
    /// It will shrink the card form into the ideal height
    /// It will show loading view inside the card form waiting until the web view is ready from the charge response
    func prepareFor3DSInCardAnimation()
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
    /// Holds the bundle id data
    @objc public static var bundleID:String = TapApplicationPlistInfo.shared.bundleIdentifier ?? ""
    
    /// Tells to demo the loyalty widget or not
    @objc public static var loyaltyEnabled:Bool = false
    
    // MARK:- Internal functions
    /// Configures and start sthe session with the bug finder logging platform
    internal func configureBugFinder() {
        // Log session start
        Bugfender.activateLogger("722zS708zuKi2owFgjUpgLYUk12hFwLY")
        Bugfender.enableCrashReporting()
        Bugfender.setPrintToConsole(TapCheckout.sharedCheckoutManager().dataHolder.transactionData.enableApiLogging.contains(.CONSOLE))
        Bugfender.setDeviceString(NetworkManager.staticHTTPHeaders.tap_jsonString, forKey: "Static Headers")
        logBF(message: "New Session", tag: .EVENTS)
        if TapCheckout.sharedCheckoutManager().dataHolder.transactionData.enableApiLogging.contains(.UI) {
            Bugfender.enableUIEventLogging()
        }

    }
    
    // MARK:- Public functions
    
    /// It is a required method to be called as fast as possible (on app delegate).
    /// This will make sure whever the checkout process is needed, it will be ready and fast for better UX
    /// - Parameter localiseFile: Please pass the name of the custom localisation file model if needed. If not set, the normal and default TAP localisations will be used
    /// - Parameter customTheme: Please pass the tap checkout theme object with the names of your custom theme files if needed. If not set, the normal and default TAP theme will be used
    @objc public static func PreloadSDKData(localiseFile:TapCheckoutLocalisation? = .init(with: URL(string: "https://tapcheckoutsdk.firebaseio.com/TapLocalisation.json")!, from: .RemoteJsonFile),
                                            customTheme:TapCheckOutTheme? = .init(with: "https://tapcheckoutsdk.firebaseio.com/TapThemeMobile/light.json", and: "https://tapcheckoutsdk.firebaseio.com/TapThemeMobile/dark.json", from: .RemoteJsonFile)) {
        // Init the localsiation manager
        TapCheckout.configureLocalisationManager(localiseFile: localiseFile)
        // Init the theme manager
        TapCheckout.configureThemeManager(customTheme:customTheme)
    }
    
    /**
     Defines the tap checkout bottom sheet controller
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
     - Parameter collectCreditCardName: Decides whether or not, the card input should collect the card holder name. Default is false
     - Parameter creditCardNameEditable: Decides whether or not, the card name field will be editable
     - Parameter creditCardNamePreload: Decides whether or not, the card name field should be prefilled
     - Parameter enableApiLogging: Defines which level of logging do you wnt to enable. Please pass the raw value for the enums [TapLoggingType](x-source-tag://TapLoggingType)
     - Parameter isSubscription: Defines if you want to make a subscription based transaction. Default is false
     - Parameter recurringPaymentRequest: Defines the recurring payment request Please check [Apple Pay
     docs](https://developer.apple.com/documentation/passkit/pkrecurringpaymentrequest). NOTE: This will only be availble for iOS 16+ and subscripion parameter is on.
     - Parameter applePayButtonType: Defines the type of the apple pay button like Pay with or Subscripe with  etc. Default is Pay
     - Parameter applePayButtonStyle: Defines the UI of the apple pay button white, black or outlined. Default is black
     - Parameter showSaveCreditCard:Decides whether or not, the card input should show save card option for Tap and Merchant sides. Default is None
     - Parameter shouldFlipCardData: Defines if the card info textfields should support RTL in Arabic mode or not
     - Parameter cardShouldThemeItself: Indicates if the card form shall have its own background theming or it should be clear and reflect whatever is behind it
     */
    @objc public func build(
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
        shipping:Shipping? = nil,
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
        enableApiLogging:[Int] = [TapLoggingType.CONSOLE.rawValue],
        collectCreditCardName:Bool = false,
        creditCardNameEditable:Bool = true,
        creditCardNamePreload:String = "",
        showSaveCreditCard:SaveCardType = .None,
        isSubscription:Bool = false,
        recurringPaymentRequest:Any? = nil,
        applePayButtonType:TapApplePayButtonType = .AppleLogoOnly,
        applePayButtonStyle:TapApplePayButtonStyleOutline = .Black,
        shouldFlipCardData:Bool = true,
        onCheckOutReady: @escaping (TapCheckout) -> () = {_ in}) {
            
            // Do the pre steps needed before starting a new SDK session
            prepareSDK(with: sdkMode,delegate:delegate, enableApiLogging:enableApiLogging.map{ TapLoggingType(rawValue: $0) ?? .CONSOLE })
            
            // Store the passed configurations for further processing
            configureSharedManager(currency:currency, amount:amount,items:items,applePayMerchantID:applePayMerchantID,swipeDownToDismiss:swipeDownToDismiss,paymentType:paymentType,closeButtonStyle: closeButtonStyle, showDragHandler: showDragHandler,transactionMode: transactionMode,customer: customer,destinations: destinations,tapMerchantID: tapMerchantID,taxes: taxes, shipping: shipping, allowedCardTypes:allowedCardTypes,postURL: postURL, paymentDescription: paymentDescription, paymentMetadata: paymentMetadata, paymentReference: paymentReference, paymentStatementDescriptor: paymentStatementDescriptor,require3DSecure:require3DSecure,receiptSettings:receiptSettings, authorizeAction: authorizeAction,allowsToSaveSameCardMoreThanOnce: allowsToSaveSameCardMoreThanOnce, enableSaveCard: enableSaveCard, enableApiLogging: enableApiLogging.map{ TapLoggingType(rawValue: $0) ?? .CONSOLE }, isSaveCardSwitchOnByDefault: isSaveCardSwitchOnByDefault, collectCreditCardName: collectCreditCardName, creditCardNameEditable: creditCardNameEditable, creditCardNamePreload: creditCardNamePreload, showSaveCreditCard:showSaveCreditCard, isSubscription: isSubscription, recurringPaymentRequest: recurringPaymentRequest, applePayButtonType :applePayButtonType, applePayButtonStyle: applePayButtonStyle, shouldFlipCardData: shouldFlipCardData, cardShouldThemeItself: true)
            
            // Initiate the needed calls to server to start the session
            initialiseSDKFromAPI() {  [weak self] in
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
    
    /// Sets the customer data for the logging session
    internal func setLoggingCustomerData() {
        Bugfender.setDeviceString("Customer ID : \(dataHolder.transactionData.customer.identifier ?? "NA") | Customer name : \(dataHolder.transactionData.customer.firstName ?? "NA") | Customer email : \(dataHolder.transactionData.customer.emailAddress?.value ?? "NA") | Customer phone : \(dataHolder.transactionData.customer.phoneNumber?.phoneNumber ?? "NA")",forKey: "Customer")
    }
    
    /**
     Sends a message to the logging platform
     - Parameter message: The message to be dispatched
     - Parameter tag: The tag identigyin the category
     */
    internal func logBF(message:String?, tag:TapLoggingType) {
        // Validate the message
        guard let message = message else { return }
        // Decide the level based on the logging type
        let level:BFLogLevel = (tag == .EVENTS) ? .trace : .default
        // Check if the user allowed to log this type
        guard (tag == .EVENTS && TapCheckout.sharedCheckoutManager().dataHolder.transactionData.enableApiLogging.contains(.EVENTS)) || (tag == .API && TapCheckout.sharedCheckoutManager().dataHolder.transactionData.enableApiLogging.contains(.API)) else { return }
        // Log it happily :)
        bfprint(message, tag: tag.stringValue, level: level)
    }
    /*/// The logger for analytics
    internal func log() -> SwiftyBeaver.Type {
        
        let log = SwiftyBeaver.self
        
        // add log destinations. at least one is needed!
        let console = ConsoleDestination()  // log to Xcode Console
        let googleCloud = GoogleCloudDestination(serviceName: "")
        let cloud = SBPlatformDestination(appID: "r7xElo", appSecret: "1xcyjpgckJGdg5rfckbzfzaih0Znpewf", encryptionKey: "axpogXqu5wey1hjvmTopu1pmeqgfgprJ") // to cloud
        cloud.analyticsUserName = (dataHolder.transactionData.customer.identifier ?? dataHolder.transactionData.customer.firstName) ?? ""
        // use custom format and set console output to short time, log level & message
        console.format = "$J"
        cloud.format = "$DHH:mm:ss$d $N.$F():$l $L: $M"
        // or use this for JSON output: console.format = "$J"
        
        // add the destinations to SwiftyBeaver
        log.addDestination(console)
        log.addDestination(cloud)
        
        return log
    }*/
    
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
     - Parameter enableApiLogging: Defines which level of logging do you wnt to enable.  [TapLoggingType](x-source-tag://TapLoggingType)
     */
    internal func prepareSDK(with sdkMode:SDKMode = .sandbox,
                             delegate:CheckoutScreenDelegate? = nil,
                             localiseFile:TapCheckoutLocalisation? = nil,
                             customTheme:TapCheckOutTheme? = nil,
                             enableApiLogging:[TapLoggingType] = [.CONSOLE]) {
        
        // remove any pending things from an old session
        TapCheckout.destroy()
        // Decide the availability of the CDN
        TapCheckout.sharedCheckoutManager().decideIfWeCanLoadAssetsFromCDN()
        // Set the SDK mode and the delegate
        TapCheckout.sharedCheckoutManager().dataHolder.transactionData.sdkMode = sdkMode
        TapCheckout.sharedCheckoutManager().tapCheckoutScreenDelegate = delegate
        // Listen to events from network manager
        NetworkManager.shared.delegate = TapCheckout.sharedCheckoutManager()
        // Adjust the logging ability
        NetworkManager.shared.enableLogging  = enableApiLogging.contains(.CONSOLE)
        NetworkManager.shared.consoleLogging = enableApiLogging.contains(.CONSOLE)
    }
    
    /**
     Used to deal with runtime errors in the SDK
     - Parameter error: The error we need to handle and deal with
     */
    internal func handleError(session:URLSessionDataTask?, result:Any?, error:Error?) {
        
        /*let loggedDataModel:TapLogRequestModel = .init(application: .init(), customer: TapCheckout.sharedCheckoutManager().dataHolder.transactionData.customer, merchant: .init(), stack_trace: NetworkManager.shared.loggedApis, error_catgeroy: error?.localizedDescription)*/
        
        //callLogging(for: loggedDataModel)
        
        TapCheckout.sharedCheckoutManager().toBeExecutedBlock = {
            TapCheckout.sharedCheckoutManager().tapCheckoutScreenDelegate?.checkoutFailed?(in: session, for: result as? [String:String], with: error)
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
