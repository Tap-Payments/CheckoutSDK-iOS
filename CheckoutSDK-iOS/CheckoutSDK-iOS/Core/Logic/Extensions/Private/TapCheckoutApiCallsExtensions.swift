//
//  TapCheckoutApiCallsExtensions.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/15/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import TapNetworkKit_iOS
import CommonDataModelsKit_iOS
/// An extension related to handle logic and methods related to API calls within the checkout process
internal extension TapCheckout {
    
    typealias Completion<Response: Decodable> = (Response?, TapSDKError?) -> Void
    
    //MARK:- Methods for making the api calls
    
    /// Responsible for making the network calls needed to boot the SDK like init and payment options
    func initialiseSDKFromAPI(onCheckOutReady: @escaping (TapConfigResponseModel) -> () = {_ in}) {
        // As per the backend logic, we will have to hit CheckoutProfile api to load merchant & payment options data
        let sharedManager = TapCheckout.sharedCheckoutManager()
        
        // Create the payment option request with the configured data from the user
        let configRequstBody = sharedManager.createConfigRequestModel()
        
        NetworkManager.shared.makeApiCall(routing: .ConfigApi, resultType: TapConfigResponseModel.self, body: .init(body: configRequstBody), httpMethod: .POST) { [weak self] (session, result, error) in
            guard let configModel:TapConfigResponseModel = result as? TapConfigResponseModel else { self?.handleError(session: session, result: result, error: "Unexpected error when parsing into TapConfigResponseModel")
                return }
            onCheckOutReady(configModel)
        } onError: { (session, result, errorr) in
            self.handleError(session: session, result: result, error: errorr)
        }
    }
    
    /**
     Respinsiboe for calling a get request for a retrivable object (e.g. charge, authorization, etc.) by providing its ID
     - Parameter with identifier: The id of the object we want to retrieve
     - Parameter onResponseReady: A block to call when getting the response
     - Parameter onErrorOccured: A block to call when an error occured
     */
    func retrieveObject<T: Retrievable>(with identifier: String, completion: @escaping Completion<T>, onErrorOccured: @escaping(TapNetworkManager.RequestCompletionClosure)) {
        
        // Create the GET url parameter model
        let urlModel = TapURLModel.array(parameters: [identifier])
        // Fetch the retrieve route based on the type of the object the method called on
        let route = T.retrieveRoute
        
        // Perform the retrieve request with the computed data
        NetworkManager.shared.makeApiCall(routing: route, resultType: T.self, body: .none,httpMethod: .GET, urlModel: urlModel) { (session, result, error) in
            // Double check all went fine
            guard let parsedResponse:T = result as? T else {
                onErrorOccured(session, result, "Unexpected error parsing into")
                return
            }
            // Execute the on complete block
            completion(parsedResponse,nil)
        } onError: { (session, result, errorr) in
            // In case of an error we execute the on error block
            onErrorOccured(session, result, errorr)
        }
    }
    
    
    /// Authenticates an `object` with `details` calling `completion` when request finishes.
    ///
    /// - Parameters:
    ///   - object: Authenticatable object.
    ///   - details: Authentication details.
    ///   - completion: Completion that will be called when request finishes.
    ///   - onErrorOccured: A block to call when an error occured
    func authenticate<T: Authenticatable>(_ object: T, details: TapAuthenticationRequest, onResponeReady: @escaping (T) -> (), onErrorOccured: @escaping(TapNetworkManager.RequestCompletionClosure)) {
        
        // Change the model into a dictionary
        guard let bodyDictionary = TapCheckout.convertModelToDictionary(details, callingCompletionOnFailure: { error in
            onErrorOccured(nil,nil,error.debugDescription)
            return
        }) else { return }
        
        
        // Create the network call details
        let route = T.authenticationRoute
        let urlModel = TapURLModel.array(parameters: [NetworkManager.Constants.authenticateParameter, object.identifier])
        let bodyModel = TapBodyModel(body: bodyDictionary)

        
        // Perform the retrieve request with the computed data
        NetworkManager.shared.makeApiCall(routing: route, resultType: T.self, body: bodyModel,httpMethod: .POST, urlModel: urlModel) { (session, result, error) in
            // Double check all went fine
            guard let parsedResponse:T = result as? T else {
                onErrorOccured(session, result, "Unexpected error parsing verification of otp authentication details")
                return
            }
            // Execute the on complete block
            onResponeReady(parsedResponse)
        } onError: { (session, result, errorr) in
            // In case of an error we execute the on error block
            onErrorOccured(session, result, errorr)
        }
    }
    
    
    /// Retrieves BIN number details for the given `binNumber` and calls `completion` when request finishes.
    ///
    /// - Parameters:
    ///   - binNumber: First 6 digits of the card.
    ///   - completion: Completion that will be called when request finishes.
    func getBINDetails(for binNumber: String, onResponeReady: @escaping (TapBinResponseModel) -> () = {_ in}, onErrorOccured: @escaping(TapNetworkManager.RequestCompletionClosure)) {
        
        let bodyModel = ["bin":binNumber]
        
        // Perform the retrieve request with the computed data
        NetworkManager.shared.makeApiCall(routing: TapNetworkPath.bin, resultType: TapBinResponseModel.self, body: .init(body: bodyModel), httpMethod: .POST) { (session, result, error) in
            // Double check all went fine
            guard let parsedResponse:TapBinResponseModel = result as? TapBinResponseModel else {
                onErrorOccured(session, result, "Unexpected error parsing bin details")
                return
            }
            // Execute the on complete block
            onResponeReady(parsedResponse)
        } onError: { (session, result, errorr) in
            // In case of an error we execute the on error block
            onErrorOccured(session, result, errorr)
        }
        
    }
    
    
    /**
     Respinsiboe for calling charge
     - Parameter bodyDictionary: The charge request model to be called with
     - Parameter onResponseReady: A block to call when getting the response
     - Parameter onErrorOccured: A block to call when an error occured
     */
    fileprivate func callChargeAPI(bodyDictionary:[String : Any], onResponeReady: @escaping (Charge) -> () = {_ in}, onErrorOccured: @escaping(TapNetworkManager.RequestCompletionClosure)) {
        // Call the charge API
        NetworkManager.shared.makeApiCall(routing: .charges, resultType: Charge.self, body: .init(body: bodyDictionary), httpMethod: .POST) { (session, result, error) in
            if let error = error {
                onErrorOccured(session, result, error)
            }else{
                guard let charge:Charge = result as? Charge else { onErrorOccured(session, result, "Unexpected error parsing into Charge")
                    return }
                // Call success block
                onResponeReady(charge)
            }
        } onError: { (session, result, errorr) in
            onErrorOccured(session, result, errorr)
        }
    }
    
    /**
     Respinsiboe for calling authorize
     - Parameter bodyDictionary: The authorize request model to be called with
     - Parameter onResponseReady: A block to call when getting the response
     - Parameter onErrorOccured: A block to call when an error occured
     */
    fileprivate func callAuthorizeAPI(bodyDictionary:[String : Any], onResponeReady: @escaping (Authorize) -> () = {_ in}, onErrorOccured: @escaping(TapNetworkManager.RequestCompletionClosure)) {
        // Call the authorize API
        NetworkManager.shared.makeApiCall(routing: .authorize, resultType: Authorize.self, body: .init(body: bodyDictionary), httpMethod: .POST) { (session, result, error) in
            if let error = error {
                onErrorOccured(session, result, error)
            }else{
                guard let authorize:Authorize = result as? Authorize else { onErrorOccured(session, result,  "Unexpected error parsing into Authorize")
                    return }
                // Call success block
                onResponeReady(authorize)
            }
        } onError: { (session, result, errorr) in
            onErrorOccured(session, result, errorr)
        }
    }
    
    //MARK:- Methods for handling API responses
    /**
     Handles the result of the config api by storing it in the right place to be further processed
     - Parameter configModel: The response model from backend we need to deal with
     */
    func handleConfigResponse(configModel:TapConfigResponseModel) {
        // Store the init model for further access
        /*TapCheckout.sharedCheckoutManager().dataHolder.transactionData.intitModelResponse = initModel
        DispatchQueue.main.async {
            TapCheckout.sharedCheckoutManager().dataHolder.transactionData.paymentOptionsModelResponse = initModel.paymentOptions
        }*/
        print(configModel.checkoutURL)
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
