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
    func initialiseSDKFromAPI(onCheckOutReady: @escaping () -> () = {}) {
        // As per the backend logic, we will have to hit INIT then Payment options APIs
        NetworkManager.shared.makeApiCall(routing: .InitAPI, resultType: TapInitResponseModel.self) { [weak self] (session, result, error) in
            guard let initModel:TapInitResponseModel = result as? TapInitResponseModel else { self?.handleError(error: "Unexpected error")
                return }
            self?.handleInitResponse(initModel: initModel)
            // Let us now load the payment options
            self?.callPaymentOptionsAPI(onCheckOutReady: onCheckOutReady)
            
            
        } onError: { (session, result, errorr) in
            self.handleError(error: errorr)
        }
    }
    /// Responsible for making the network call to payment options api
    func callPaymentOptionsAPI(onCheckOutReady: @escaping () -> () = {}) {
        // As per the backend logic, we will have to hit PAYMENT OPTIONS API after the INIT call
        let sharedManager = TapCheckout.sharedCheckoutManager()
        
        // Create the payment option request with the configured data from the user
        let paymentOptionRequest = sharedManager.createPaymentOptionRequestModel()
        
        // Change the model into a dictionary
        guard let bodyDictionary = TapCheckout.convertModelToDictionary(paymentOptionRequest, callingCompletionOnFailure: { error in
            return
        }) else { return }
        
        
        
        NetworkManager.shared.makeApiCall(routing: .PaymentOptionsAPI, resultType: TapPaymentOptionsReponseModel.self, body: .init(body: bodyDictionary), httpMethod: .POST) { [weak self] (session, result, error) in
            guard let paymentOptionsResponse:TapPaymentOptionsReponseModel = result as? TapPaymentOptionsReponseModel else { self?.handleError(error: "Unexpected error")
                return }
            // Let us now load the payment options
            TapCheckout.sharedCheckoutManager().dataHolder.transactionData.paymentOptionsModelResponse = paymentOptionsResponse
            onCheckOutReady()
        } onError: { (session, result, errorr) in
            self.handleError(error: errorr)
        }
    }
    
    
    /// Responsible for making the network call to payment options api
    static func callChargeOrAuthorizeAPI(chargeRequestModel:TapChargeRequestModel, onResponeReady: @escaping (Charge) -> () = {_ in}, onErrorOccured: @escaping(Error)->() = {_ in}) {
        
        // Change the model into a dictionary
        guard let bodyDictionary = TapCheckout.convertModelToDictionary(chargeRequestModel, callingCompletionOnFailure: { error in
            onErrorOccured(error.debugDescription)
            return
        }) else { return }
        
        
        
        NetworkManager.shared.makeApiCall(routing: .charges, resultType: Charge.self, body: .init(body: bodyDictionary), httpMethod: .POST) { (session, result, error) in
            if let error = error {
                onErrorOccured(error)
            }else{
                guard let paymentOptionsResponse:Charge = result as? Charge else { onErrorOccured("Unexpected error")
                    return }
                // Let us now load the payment options
                print("OSAMA")
            }
            
        } onError: { (session, result, errorr) in
            onErrorOccured(errorr.debugDescription)
        }
    }
    
    
    //MARK:- Methods for handling API responses
    /**
     Handles the result of the init api by storing it in the right place to be further processed
     - Parameter initModel: The response model from backend we need to deal with
     */
    func handleInitResponse(initModel:TapInitResponseModel) {
        // Store the init model for further access
        TapCheckout.sharedCheckoutManager().dataHolder.transactionData.intitModelResponse = initModel
    }
    
    
    
    /// Converts Encodable model into its dictionary representation. Calls completion closure in case of failure.
    ///
    /// - Parameters:
    ///   - model: Model to encode.
    ///   - completion: Failure completion closure.
    ///   - response: Response object in case of success. Here - always nil.
    ///   - error: Error in case of failure. If the closure is called it will never become nil.
    /// - Returns: Dictionary.
    static func convertModelToDictionary(_ model: Encodable, callingCompletionOnFailure completion: CompletionOnFailure) -> [String: Any]? {
        
        var modelDictionary: [String: Any]
        
        do {
            modelDictionary = try model.tap_asDictionary()
        }
        catch let error {
            
            completion(TapSDKKnownError(type: .serialization, error: error, response: nil, body: model))
            return nil
        }
        
        return modelDictionary
    }
    typealias CompletionOnFailure = (TapSDKError?) -> Void
}
