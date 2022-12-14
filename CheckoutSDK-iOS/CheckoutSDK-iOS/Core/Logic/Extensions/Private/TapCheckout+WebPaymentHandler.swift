//
//  TapCheckoutManager+WebPaymentHandler.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/18/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import TapUIKit_iOS
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
        
        //@available(*, unavailable) private init() { fatalError("This struct cannot be instantiated.") }
    }
    
    /**
     Handles the logic to be executed when redirection is finished
     - Parameter with tapID: The tap id of the object (e.g charge, authorization etc.) generated from the backend in the URL
     */
    func webPaymentProcessFinished<T: ChargeProtocol>(with tapID:String,of type: T.Type) {
        // Hide the webview
        TapCheckout.sharedCheckoutManager().chanegActionButton(status: .ValidPayment, actionBlock: nil)
        UIDelegate?.closeWebView()
        // Show the button in a loading state
        dataHolder.viewModels.tapActionButtonViewModel.startLoading()
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
}

extension TapCheckout:TapWebViewModelDelegate {
    public func webViewCanceled() {
        
    }
    
    
    public func willLoad(request: URLRequest) -> WKNavigationActionPolicy {
        // Double check, there is a url to load :)
        guard let url = request.url else {
            return(.cancel)
        }
        
        // First get the decision based on the loaded url
        let decision = navigationDecision(forWebPayment: url)
        
        // If the redirection finished we need to fetch the object id from the url to further process it
        if decision.redirectionFinished, let tapID = decision.tapID {
            
            // Process the web payment upon getting the transaction ID from the backend url based on the transaction mode Charge or Authorize
            if(dataHolder.transactionData.transactionMode == .purchase) {
                webPaymentProcessFinished(with: tapID, of: Charge.self)
            }else if(dataHolder.transactionData.transactionMode == .authorizeCapture) {
                webPaymentProcessFinished(with: tapID, of: Authorize.self)
            }else if(dataHolder.transactionData.transactionMode == .cardSaving) {
                cardPaymentProcessFinished(with: tapID)
            }
        }else if decision.shouldCloseWebPaymentScreen {
            // The backend told us we need to close the web view :)
            TapCheckout.sharedCheckoutManager().chanegActionButton(status: .ValidPayment, actionBlock: nil)
            self.UIDelegate?.closeWebView()
        }
        
        return decision.shouldLoad ? .allow : .cancel
    }
    
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
        // Detect if the url is the return url (stop redirecting.)
        let urlIsReturnURL = url.absoluteString.starts(with: WebPaymentHandlerConstants.returnURL.absoluteString)
        
        let shouldLoad = !urlIsReturnURL
        let redirectionFinished = urlIsReturnURL
        // Check if the backend passed the ID of the object (charge or authorize)
        let tapID = url[WebPaymentHandlerConstants.tapIDKey]
        let shouldCloseWebPaymentScreen = redirectionFinished// && self.dataHolder.transactionData.selectedPaymentOption?.paymentType == .Card
        
        return WebPaymentURLDecision(shouldLoad: shouldLoad, shouldCloseWebPaymentScreen: shouldCloseWebPaymentScreen, redirectionFinished: redirectionFinished, tapID: tapID)
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
}
