//
//  TapCheckout+Protocols.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/20/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import LocalisationManagerKit_iOS
import CommonDataModelsKit_iOS

//MARK: TapCheckout Protocols

/// A protocol to communicate with the Presente tap sheet controller
@objc public protocol CheckoutScreenDelegate {
    
    /// Inform the delegate that we may need log some strings for further analysis
    @objc optional func log(string:String)
    
    /// This means, that the web checkout did display and slided in the popup. Calling config + checkout profile api is done
    @objc optional func webCheckoutPopupIsDisplayed()
    
    /// This means, the customer did hit on the close button and dismissed the checkout
    @objc optional func webCheckoutClosedByCustomer()
    
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
