//
//  TapCheckoutManager+WebPaymentHandler.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/18/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// Logic to handle webviews based gateway
extension TapCheckout {
    
    struct WebPaymentHandlerConstants {
        
        static let returnURL = URL(string: "gosellsdk://return_url")!
        static let tapIDKey = "tap_id"
        
        //@available(*, unavailable) private init() { fatalError("This struct cannot be instantiated.") }
    }
}

extension TapCheckout:TapWebViewModelDelegate {
    public func willLoad(request: URLRequest) -> WKNavigationActionPolicy {
        guard let url = request.url else {
            return(.cancel)
        }
        
        let decision = navigationDecision(forWebPayment: url)
        if decision.shouldLoad {
            
            //self.lastAttemptedURL = url
        }
        
        if decision.redirectionFinished, let tapID = decision.tapID {
            
            //Process.shared.webPaymentHandlerInterface.webPaymentProcessFinished(tapID)
            self.UIDelegate?.actionButton(shouldLoad: true,success: false,onComplete: {})
            print("TAP ID : \(tapID)")
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
