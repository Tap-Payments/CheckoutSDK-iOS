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
import TapApplicationV2
import PassKit
import BugfenderSDK


/// The public interface to deal and start the TapCheckout SDK/UI
@objc public class TapCheckout: NSObject {
    
    // MARK:- Internal varibales
    /// Represents a global accessable common data gathered by the merchant when loading the checkout sdk like amount, currency, etc
    internal static var privateShared : TapCheckout?
    internal var canLoadFromCDN:Bool = false
    public static var bundleID:String = ""
    public static var localeIdentifier:String = "en"
    public static var secretKey:SecretKey = .init(sandbox: "", production: "")
    public var sdkMode:SDKMode = .sandbox
    public static var displayMonoLight:Bool = false
    // MARK:- Internal functions
    /// Configures and start sthe session with the bug finder logging platform
    internal func configureBugFinder() {
        // Log session start
        Bugfender.activateLogger("722zS708zuKi2owFgjUpgLYUk12hFwLY")
        Bugfender.enableCrashReporting()
        Bugfender.setPrintToConsole(true)
        Bugfender.setDeviceString(NetworkManager.staticHTTPHeaders.tap_jsonString, forKey: "Static Headers")
        logBF(message: "New Session", tag: .EVENTS)
        if true {
            Bugfender.enableUIEventLogging()
        }

    }
    
    // MARK:- Public functions
   
    /**
     Defines the tap checkout bottom sheet controller
     - Parameter delegate: A protocol to communicate with the Presente tap sheet controller
     - Parameter currency: Represents the original transaction currency stated by the merchant on checkout start
     - Parameter supportedCurrencies: Represents the allowed currencies for the transaction. Leave nil for ALL, pass the 3 digits iso KWD, EGP, etc.
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
        supportedCurrencies:[String]? = nil,
        amount:Double = 1,
        items:[ItemModel] = [],
        applePayMerchantID:String = "merchant.tap.gosell",
        swipeDownToDismiss:Bool = true,
        paymentType:TapPaymentType = .All,
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
            
            initialiseSDKFromAPI { configModel in
                onCheckOutReady(self)
            }
        }
    
    
    /**
     Starts the TapCheckout UIView in the required viewcontroller
     - Parameter controller: This is th view controller you want to show the tap checkout in
     */
    @objc public func start(presentIn controller:UIViewController?) {
        guard let controller = controller else { return }
        DispatchQueue.main.async { [weak self] in
            //controller.present(self!.bottomSheetController, animated: true, completion: nil)
        }
    }
    
    
    /// Sets the customer data for the logging session
    internal func setLoggingCustomerData() {
        /*Bugfender.setDeviceString("Customer ID : \(dataHolder.transactionData.customer.identifier ?? "NA") | Customer name : \(dataHolder.transactionData.customer.firstName ?? "NA") | Customer email : \(dataHolder.transactionData.customer.emailAddress?.value ?? "NA") | Customer phone : \(dataHolder.transactionData.customer.phoneNumber?.phoneNumber ?? "NA")",forKey: "Customer")*/
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
        /*guard (tag == .EVENTS && TapCheckout.sharedCheckoutManager().dataHolder.transactionData.enableApiLogging.contains(.EVENTS)) || (tag == .API && TapCheckout.sharedCheckoutManager().dataHolder.transactionData.enableApiLogging.contains(.API)) else { return }*/
        // Log it happily :)
        bfprint(message, tag: tag.stringValue, level: level)
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
     Used to deal with runtime errors in the SDK
     - Parameter error: The error we need to handle and deal with
     */
    internal func handleError(session:URLSessionDataTask?, result:Any?, error:Error?) {
        
        
    }
}
