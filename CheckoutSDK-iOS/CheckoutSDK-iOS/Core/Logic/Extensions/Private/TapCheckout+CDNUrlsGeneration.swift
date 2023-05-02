//
//  TapCheckout+CDNUrlsGeneration.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/16/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import CommonDataModelsKit_iOS

extension PaymentOption {
    /// Computed attribute to get the CDN based URL
    internal var imageURL:URL {
        // Check if it is allowed to load from cdn or it is unreachable
        guard TapCheckout.sharedCheckoutManager().canLoadFromCDN else {
            return correctBackEndImageURL(showMonoForLightMode: TapCheckout.displayMonoLight)
        }
        return URL(string: "https://checkoutsdkios.b-cdn.net/\(CDNPath.PaymentOption.generateCDNPath())/\(identifier).png")!
    }
}

extension SavedCard {
    /// Computed attribute to get the CDN based URL
    internal var image:String {
        // Check if it is allowed to load from cdn or it is unreachable
        guard TapCheckout.sharedCheckoutManager().canLoadFromCDN else {
            return backendImage ?? ""
        }
        return "https://checkoutsdkios.b-cdn.net/\(CDNPath.PaymentOption.generateCDNPath())/\(paymentOptionIdentifier ?? "").png"
    }
}

extension AmountedCurrency {
    /// Computed attribute to get the CDN based URL
    internal var cdnFlag:String {
        // Check if it is allowed to load from cdn or it is unreachable
        guard TapCheckout.sharedCheckoutManager().canLoadFromCDN else {
            return correctBackEndImageURL(showMonoForLightMode: TapCheckout.displayMonoLight).absoluteString
        }
        return "https://checkoutsdkios.b-cdn.net/\(CDNPath.Currency.generateCDNPath())/\(currency.appleRawValue).png"
    }
}

extension TapCheckout {
    /// A method to check if the CDN is availble and reachable and we can load from it or not
    internal func decideIfWeCanLoadAssetsFromCDN() {
        // Default load from backend
        canLoadFromCDN = false
        
        // Call the default image to check if CDN is reachable
        guard let url = URL(string: "https://checkoutsdkios.b-cdn.net/IsAlive.png") else {
            canLoadFromCDN = false
            return
        }
        
        // Make a test request to the test image url
        let request = URLRequest(url: url,timeoutInterval: 1.5)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let _ = error {
                // Error occured like timeout for example
                self?.canLoadFromCDN = false
            }else if let httpResponse = response as? HTTPURLResponse,
                     httpResponse.statusCode == 200,
                     let data = data,
                     let _:UIImage = UIImage(data: data) {
                // This means status code is 200, the url replied with data and this data is a valid image
                self?.canLoadFromCDN = true
            }else{
                // Error occured
                self?.canLoadFromCDN = false
            }
        }.resume()
    }
}

/// An enum to decide what is the pathway for different parts in the checkout sdks
fileprivate enum CDNPath:String {
    
    /// Will hold the path for gateways' and card brands' assets
    case PaymentOption  = "PaymentOption"
    /// Will hold the path for currencies' assets
    case Currency       = "Currency"
    
    /**
     Compute the asset's path depending on the current type and display mode
     - Returns: The pathway for the given type( payment option, currency, etc.) and the current display mode (light or dark)
     */
    func generateCDNPath() -> String {
        // Check first the display mode
        let interfaceStylePath:String = (UIScreen.main.traitCollection.userInterfaceStyle == .light) ? "" : "Dark"
        // Generate the correct path for the current type
        return "\(rawValue)\(interfaceStylePath)"
    }
    
}
