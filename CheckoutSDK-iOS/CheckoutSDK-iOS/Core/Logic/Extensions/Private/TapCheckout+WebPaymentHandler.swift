//
//  TapCheckoutManager+WebPaymentHandler.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/18/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// Logic to handel webviews based gateway
extension TapCheckout {
    
    struct WebPaymentHandlerConstants {
        
        static let returnURL = URL(string: "gosellsdk://return_url")!
        static let tapIDKey = "tap_id"
        
        //@available(*, unavailable) private init() { fatalError("This struct cannot be instantiated.") }
    }
    
    /**
     Handles the logic to be executed when redirection is finished
     - Parameter with tapID: The tap id of the object (e.g charge, authorization etc.) generated from the backend in the URL
     */
    func webPaymentProcessFinished<T: ChargeProtocol>(with tapID:String,of type: T.Type) {
        // Hide the webview
        UIDelegate?.closeWebView()
        // Show the button in a loading state
        dataHolder.viewModels.tapActionButtonViewModel.startLoading()
        // We need to retrieve the object using the passed id and process it afterwards
        TapCheckout.retrieveObject(with: tapID) { [weak self] (returnChargeOrAuthorize: T?, error: TapSDKError?) in
            if let _ = error {
                
            }else if let returnChargeOrAuthorize = returnChargeOrAuthorize {
                // No errors occured we need to process the current charge or authorize
                self?.handleCharge(with: returnChargeOrAuthorize)
            }
        } onErrorOccured: { (error) in
            
        }

    }
}

extension TapCheckout:TapWebViewModelDelegate {
    public func willLoad(request: URLRequest) -> WKNavigationActionPolicy {
        guard let url = request.url else {
            return(.cancel)
        }
        
        let decision = navigationDecision(forWebPayment: url)
        
        if decision.redirectionFinished, let tapID = decision.tapID {
            
            // Process the web payment upon getting the transaction ID from the backend url based on the transaction mode
            if(dataHolder.transactionData.transactionMode == .purchase) {
                webPaymentProcessFinished(with: tapID, of: Charge.self)
            }else{
                webPaymentProcessFinished(with: tapID, of: Authorize.self)
            }
        }else if decision.shouldCloseWebPaymentScreen {
            
            self.UIDelegate?.closeWebView()
        }
        
        return decision.shouldLoad ? .allow : .cancel
    }
    
    public func didLoad(url: URL?) {
        
    }
    
    public func didFail(with error: Error, for url: URL?) {
        
    }
    
    
    internal func navigationDecision(forWebPayment url: URL) -> WebPaymentURLDecision {
        
        let urlIsReturnURL = url.absoluteString.starts(with: WebPaymentHandlerConstants.returnURL.absoluteString)
        
        let shouldLoad = !urlIsReturnURL
        let redirectionFinished = urlIsReturnURL
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
