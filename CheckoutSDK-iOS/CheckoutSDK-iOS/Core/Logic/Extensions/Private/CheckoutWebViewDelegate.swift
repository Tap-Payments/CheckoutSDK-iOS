//
//  CheckoutWebViewDelegate.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 03/05/2023.
//  Copyright © 2023 Tap Payments. All rights reserved.
//

import Foundation
import UIKit
import WebKit

/// The methods used to handle the logic for the web checkout
extension TapCheckout: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        // Double check, there is a url to load :)
        let request = navigationAction.request
        guard let url = request.url else {
            return(.cancel)
        }
        
        // First get the decision based on the loaded url
        let decision = navigationDecision(forWebPayment: url)
        
        // If the redirection finished we need to fetch the object id from the url to further process it
        if decision.redirectionFinished, let tapID = decision.tapID {
            // Process the web payment upon getting the transaction ID from the backend url based on the transaction mode Charge or Authorize
            if(TapCheckout.sharedCheckoutManager().transactionMode == .purchase) {
                webPaymentProcessFinished(with: tapID, of: Charge.self)
            }else if(TapCheckout.sharedCheckoutManager().transactionMode == .authorizeCapture) {
                webPaymentProcessFinished(with: tapID, of: Authorize.self)
            }
        }else if decision.shouldCloseWebPaymentScreen {
            // The backend told us we need to close the web view :)
            /*TapCheckout.sharedCheckoutManager().chanegActionButton(status: .ValidPayment, actionBlock: nil)
            self.UIDelegate?.closeWebView()*/
            TapCheckout.sharedCheckoutManager().dismiss()
        }else if decision.webSDKWillShow {
            TapCheckout.sharedCheckoutManager().webSDKWillShow()
        }else if let redirectionURL = decision.redirectionURL {
            print("REDIRECT \(redirectionURL)")
            TapCheckout.sharedCheckoutManager().willRedirectToFinaliseCharge(with : redirectionURL)
        }
        return decision.shouldLoad ? .allow : .cancel
    }
    
}


/// Struct to hold the constants related to control the flow of the webview by lookin ginto constants into the loaded URL
struct WebPaymentHandlerConstants {
    /// Whenever we find this prefix in the URL, the backend is telling we need to stop redirecting
    static let returnURL = URL(string: "gosellsdk://return_url")!
    /// Whenever we have this key inside the URL we get the ibject id to retrieve it afterwards
    static let tapIDKey = "tap_id"
    
    //@available(*, unavailable) private init() { fatalError("This struct cannot be instantiated.") }
}


