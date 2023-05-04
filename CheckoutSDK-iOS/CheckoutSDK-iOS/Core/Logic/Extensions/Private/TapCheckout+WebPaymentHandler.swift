//
//  TapCheckoutManager+WebPaymentHandler.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/18/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import CommonDataModelsKit_iOS
import WebKit

/// Logic to handel webviews based gateway
extension TapCheckout {
    
    /// Struct to hold the constants related to control the flow of the webview by lookin ginto constants into the loaded URL
    struct WebPaymentHandlerConstants {
        /// Whenever we find this prefix in the URL, the backend is telling we need to stop redirecting
        static let returnURL = URL(string: "gosellsdk://return_url")!
        /// Whenever we have this key inside the URL we get the ibject id to retrieve it afterwards
        static let tapIDKey = "tap_id"
        /// Whenever we have this key inside the URL we get the url  to retrieve it afterwards
        static let redirectionURLKey = "url"
        
        //@available(*, unavailable) private init() { fatalError("This struct cannot be instantiated.") }
    }
    
    /**
     Handles the logic to be executed when redirection is finished
     - Parameter with tapID: The tap id of the object (e.g charge, authorization etc.) generated from the backend in the URL
     */
    func webPaymentProcessFinished<T: ChargeProtocol>(with tapID:String,of type: T.Type) {
        // We need to retrieve the object using the passed id and process it afterwards
        retrieveObject(with: tapID) { [weak self] (returnChargeOrAuthorize: T?, error: TapSDKError?) in
            if let error = error {
                self?.handleError(session: nil, result: nil, error: error)
            }else if let returnChargeOrAuthorize = returnChargeOrAuthorize {
                // No errors occured we need to process the current charge or authorize
                self?.handleCharge(with: returnChargeOrAuthorize)
            }
        } onErrorOccured: { [weak self] (session, result, error) in
            self?.handleError(session: session, result: result, error: error)
        }
    }
    
    
    // MARK:- Authourize and Charge based methods
    /**
     Handles the charge response to see what should be the next action
     - Parameter with charge: The charge response we want to analyse and decide the next action based on it
     */
    func handleCharge(with chargeOrAuthorize:ChargeProtocol?) {
        // Save the object for further processing
        if chargeOrAuthorize is Charge {
            TapCheckout.sharedCheckoutManager().currentCharge = chargeOrAuthorize as? Charge
        }else if chargeOrAuthorize is Authorize {
            TapCheckout.sharedCheckoutManager().currentAuthorize = chargeOrAuthorize as? Authorize
        }
        
        // Based on the status we will know what to do
        let chargeStatus = chargeOrAuthorize?.status
        switch chargeStatus {
        case .captured:
            handleCaptured(for:chargeOrAuthorize)
            break
        case .authorized:
            handleCaptured(for:chargeOrAuthorize)
            break
        case .failed,.declined:
            handleFailed(for:chargeOrAuthorize)
            break
        case .inProgress:
            handleInProgress(for:chargeOrAuthorize)
        default:
            handleCancelled(for:chargeOrAuthorize)
        }
    }
    
    
    /**
     Will be called once the charge response shows that, the charge has been successfully captured.
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleCaptured(for charge:ChargeProtocol?) {
        // First let us inform the caller app that the charge/authorization had been done successfully
        if let charge:Charge = charge as? Charge {
            TapCheckout.sharedCheckoutManager().delegate?.checkoutCaptured?(with: charge)
        }else if let authorize:Authorize = charge as? Authorize {
            TapCheckout.sharedCheckoutManager().delegate?.checkoutCaptured?(with: authorize)
        }
        // Now it is time to safely dismiss ourselves
        TapCheckout.sharedCheckoutManager().dismiss()
    }
    
    
    /**
     Will be called once the charge response shows that, the charge has hailed
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleFailed(for charge:ChargeProtocol?) {
        // First let us inform the caller app that the charge/authorization had failed
        if let charge:Charge = charge as? Charge {
            TapCheckout.sharedCheckoutManager().delegate?.checkoutFailed?(with: charge)
        }else if let authorize:Authorize = charge as? Authorize {
            TapCheckout.sharedCheckoutManager().delegate?.checkoutFailed?(with: authorize)
        }
        // Now it is time to safely dismiss ourselves
        TapCheckout.sharedCheckoutManager().dismiss()
    }
    
    
    /**
     Will be called once the charge response shows that, the charge has been progress like ASYNC payments
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleInProgress(for charge:ChargeProtocol?) {
        guard let charge:Charge = charge as? Charge else { return }
        TapCheckout.sharedCheckoutManager().delegate?.checkoutCaptured?(with: charge)
    }
    /**
     Will be called once the charge response shows that, the charge has been cancelled
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleCancelled(for charge:ChargeProtocol?) {
        handleFailed(for: charge)
    }
}

extension TapCheckout {
    
    public func didLoad(url: URL?) {}
    
    public func didFail(with error: Error, for url: URL?) {
        // If any error happened, all what we need to do now is to go away :)
        handleError(session: nil, result: nil, error: "Failed to load:\n\(url?.absoluteString ?? "")\nWith Error :\n\(error)")
    }
    
    /**
     Used to decide the decision the web view should do based in the url being requested
     - Parameter forWebPayment url: The url being requested we need to decide the flow based on
     - Returns: The decision based on the url and backend instructions detected inside the url
     */
    internal func navigationDecision(forWebPayment url: URL) -> WebPaymentURLDecision {
        print("URL LOADING : \(url.absoluteString)")
        // First check if the url is one of the communication protocol between the web sdk and the native side
        if let webCommunicationProtocol:CheckoutWebSDKUrlScheme = CheckoutWebSDKUrlScheme.starts(with: url.absoluteString) {
            return navigationDecision(forCommunicationProtocol: webCommunicationProtocol, forWebPayment: url)
        }
        // Detect if the url is the return url (stop redirecting.)
        let urlIsReturnURL = url.absoluteString.starts(with: WebPaymentHandlerConstants.returnURL.absoluteString)
        
        let shouldLoad = !urlIsReturnURL
        let redirectionFinished = urlIsReturnURL
        // Check if the backend passed the ID of the object (charge or authorize)
        let tapID = url[WebPaymentHandlerConstants.tapIDKey]
        let shouldCloseWebPaymentScreen = redirectionFinished
        
        return WebPaymentURLDecision(shouldLoad: shouldLoad, shouldCloseWebPaymentScreen: shouldCloseWebPaymentScreen, redirectionFinished: redirectionFinished, tapID: tapID, webSDKWillShow: false, redirectionURL: nil)
    }
    
    
    /**
     Used to decide the decision the web view should do based in the url being requested
     - Parameter forCommunicationProtocol : The protocol used by the web sdk to tell the native side
     - Parameter forWebPayment url: The url being requested we need to decide the flow based on
     - Returns: The decision based on the url and backend instructions detected inside the url
     */
    internal func navigationDecision(forCommunicationProtocol:CheckoutWebSDKUrlScheme, forWebPayment url: URL) -> WebPaymentURLDecision {
        // In this case, these are url scehemes so we shouldn't allow any loading
        let shouldLoad:Bool = false
        
        var shouldCloseWebPaymentScreen:Bool = false
        // let us check if it is one of the closing cases
        if forCommunicationProtocol == .checkoutIsClosedByUser {
            // The user canceled the checkout so we need to close now
            shouldCloseWebPaymentScreen = true
        }
        // Check if the backend passed the ID of the object (charge or authorize)
        let redirectionUrl = String.fromBase64(url[WebPaymentHandlerConstants.redirectionURLKey])
        
        return WebPaymentURLDecision(shouldLoad: shouldLoad, shouldCloseWebPaymentScreen: shouldCloseWebPaymentScreen, redirectionFinished: false, tapID: nil, webSDKWillShow: forCommunicationProtocol == .checkoutWillPresent, redirectionURL: redirectionUrl)
    }
}

/// Web Payment URL decision.
internal struct WebPaymentURLDecision {
    
    // MARK: - Internal -
    // MARK: Properties
    
    /// Defines if URL should be loaded.
    internal let shouldLoad: Bool
    
    /// Defines if web payment screen should be closed.
    internal let shouldCloseWebPaymentScreen: Bool
    
    /// Defines if web payment flow redirections are finished.
    internal let redirectionFinished: Bool
    
    /// Charge or authorize identifier.
    internal let tapID: String?
    
    /// The web checkout sdk is being displayed now
    internal let webSDKWillShow: Bool
    
    /// The web checkout is instructing us to redirect to a url
    internal let redirectionURL: String?
}
