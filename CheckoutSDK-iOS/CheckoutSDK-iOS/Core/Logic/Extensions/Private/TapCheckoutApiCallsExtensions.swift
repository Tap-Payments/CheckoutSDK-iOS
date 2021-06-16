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
    func initialiseSDKFromAPI() {
        // As per the backend logic, we will have to hit INIT then Payment options APIs
        NetworkManager.shared.makeApiCall(routing: .InitAPI, resultType: TapInitResponseModel.self) { [weak self] (session, result, error) in
            guard let initModel:TapInitResponseModel = result as? TapInitResponseModel else { self?.handleError(error: "Unexpected error")
                return }
            self?.handleInitResponse(initModel: initModel)
            // Let us now load the payment options
            self?.callPaymentOptionsAPI()
            
            
        } onError: { (session, result, errorr) in
            self.handleError(error: errorr)
        }
    }
    /// Responsible for making the network call to payment options api
    func callPaymentOptionsAPI() {
        // As per the backend logic, we will have to hit PAYMENT OPTIONS API after the INIT call
        let sharedManager = TapCheckoutSharedManager.sharedCheckoutManager()
        
        // Create the payment option request with the configured data from the user
        let paymentOptionRequest = TapPaymentOptionsRequestModel(transactionMode: sharedManager.transactionMode, amount: sharedManager.transactionTotalAmountValue, items: sharedManager.transactionItemsValue, shipping: sharedManager.shipping, taxes: sharedManager.taxes, currency: sharedManager.transactionCurrencyValue, merchantID: sharedManager.tapMerchantID, customer: sharedManager.customer, destinationGroup: DestinationGroup(destinations: sharedManager.destinations), paymentType: sharedManager.paymentType)
        
        // Change the model into a dictionary
        guard let bodyDictionary = self.convertModelToDictionary(paymentOptionRequest, callingCompletionOnFailure: { error in
            return
        }) else { return }
        
        
        
        NetworkManager.shared.makeApiCall(routing: .PaymentOptionsAPI, resultType: TapPaymentOptionsReponseModel.self, body: bodyDictionary, httpMethod: .POST) { [weak self] (session, result, error) in
            guard let initModel:TapPaymentOptionsReponseModel = result as? TapPaymentOptionsReponseModel else { self?.handleError(error: "Unexpected error")
                return }
            // Let us now load the payment options
                print("OSAMA")
            
        } onError: { (session, result, errorr) in
            self.handleError(error: errorr)
        }
    }
    
    
    //MARK:- Methods for handling API responses
    /**
     Handles the result of the init api by storing it in the right place to be further processed
     - Parameter initModel: The response model from backend we need to deal with
     */
    func handleInitResponse(initModel:TapInitResponseModel) {
        // Store the init model for further access
        TapCheckoutSharedManager.sharedCheckoutManager().intitModelResponse = initModel
    }
    
    
    
    /// Converts Encodable model into its dictionary representation. Calls completion closure in case of failure.
    ///
    /// - Parameters:
    ///   - model: Model to encode.
    ///   - completion: Failure completion closure.
    ///   - response: Response object in case of success. Here - always nil.
    ///   - error: Error in case of failure. If the closure is called it will never become nil.
    /// - Returns: Dictionary.
    func convertModelToDictionary(_ model: Encodable, callingCompletionOnFailure completion: CompletionOnFailure) -> [String: Any]? {
        
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