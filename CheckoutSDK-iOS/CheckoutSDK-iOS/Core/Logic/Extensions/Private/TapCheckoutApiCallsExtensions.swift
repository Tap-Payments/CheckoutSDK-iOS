//
//  TapCheckoutApiCallsExtensions.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/15/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// An extension related to handle logic and methods related to API calls within the checkout process
internal extension TapCheckout {
    
    //MARK:- Methods for making the api calls
    
    /// Responsible for making the network calls needed to boot the SDK like init and payment options
    private func initialiseSDKFromApi() {
        // As per the backend logic, we will have to hit INIT then Payment options APIs
        NetworkManager.shared.makeApiCall(routing: .InitAPI, resultType: TapInitResponseModel.self) { [weak self] (session, result, error) in
            guard let initModel:TapInitResponseModel = result as? TapInitResponseModel else { self.handleError(error: "Unexpected error")
                return }
            self?.handleInitResponse(initModel: initModel)
            
        } onError: { (session, result, errorr) in
            self.handleError(error: errorr)
        }
    }
    
    
    //MARK:- Methods for handling API responses
    /**
     Handles the result of the init api by storing it in the right place to be further processed
     - Parameter initModel: The response model from backend we need to deal with
     */
    private func handleInitResponse(initModel:TapInitResponseModel) {
        // Store the init model for further access
        TapCheckoutSharedManager.sharedCheckoutManager().
    }
    
}
