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
    func initialiseSDKFromAPI(onCheckOutReady: @escaping () -> () = {}) {
        // As per the backend logic, we will have to hit INIT then Payment options APIs
        NetworkManager.shared.makeApiCall(routing: .InitAPI, resultType: TapInitResponseModel.self) { [weak self] (session, result, error) in
            guard let initModel:TapInitResponseModel = result as? TapInitResponseModel else { self?.handleError(error: "Unexpected error when parsing into TapInitResponseModel")
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
            guard let paymentOptionsResponse:TapPaymentOptionsReponseModel = result as? TapPaymentOptionsReponseModel else { self?.handleError(error: "Unexpected error when parsing TapPaymentOptionsReponseModel")
                return }
            // Let us now load the payment options
            TapCheckout.sharedCheckoutManager().dataHolder.transactionData.paymentOptionsModelResponse = paymentOptionsResponse
            onCheckOutReady()
        } onError: { (session, result, errorr) in
            self.handleError(error: errorr)
        }
    }
    
    
    /**
     Respinsiboe for calling charge or authorize api
     - Parameter chargeRequestModel: The charge request model to be called with
     - Parameter onResponseReady: A block to call when getting the response
     - Parameter onErrorOccured: A block to call when an error occured
     */
    func callChargeOrAuthorizeAPI(chargeRequestModel:TapChargeRequestModel, onResponeReady: @escaping (ChargeProtocol) -> () = {_ in}, onErrorOccured: @escaping(Error)->() = {_ in}) {
        
        // Change the model into a dictionary
        guard let bodyDictionary = TapCheckout.convertModelToDictionary(chargeRequestModel, callingCompletionOnFailure: { error in
            onErrorOccured(error.debugDescription)
            return
        }) else { return }
        
        // Call the corresponding api based on the transaction mode
        if TapCheckout.sharedCheckoutManager().dataHolder.transactionData.transactionMode == .authorizeCapture {
            callAuthorizeAPI(bodyDictionary: bodyDictionary, onResponeReady: onResponeReady, onErrorOccured: onErrorOccured)
        }else{
            callChargeAPI(bodyDictionary: bodyDictionary, onResponeReady: onResponeReady, onErrorOccured: onErrorOccured)
        }
    }
    
    
    /**
     Respinsiboe for calling card verifiy api
     - Parameter cardVerifyRequestModel: The card verificatin request model to be called with
     - Parameter onResponseReady: A block to call when getting the response
     - Parameter onErrorOccured: A block to call when an error occured
     */
    func callCardVerifyAPI(cardVerifyRequestModel:TapCreateCardVerificationRequestModel, onResponeReady: @escaping (TapCreateCardVerificationResponseModel) -> () = {_ in}, onErrorOccured: @escaping(Error)->() = {_ in}) {
        
        // Change the model into a dictionary
        guard let bodyDictionary = TapCheckout.convertModelToDictionary(cardVerifyRequestModel, callingCompletionOnFailure: { error in
            onErrorOccured(error.debugDescription)
            return
        }) else { return }
        
        // Call the corresponding api based on the transaction mode
        // Perform the retrieve request with the computed data
        NetworkManager.shared.makeApiCall(routing: TapNetworkPath.cardVerification, resultType: TapCreateCardVerificationResponseModel.self, body: .init(body: bodyDictionary),httpMethod: .POST, urlModel: .none) { (session, result, error) in
            // Double check all went fine
            guard let parsedResponse:TapCreateCardVerificationResponseModel = result as? TapCreateCardVerificationResponseModel else {
                onErrorOccured("Unexpected error parsing into TapCreateCardVerificationResponseModel")
                return
            }
            // Execute the on complete block
            onResponeReady(parsedResponse)
        } onError: { (session, result, errorr) in
            // In case of an error we execute the on error block
            onErrorOccured(errorr.debugDescription)
        }
    }
    
    
    /**
     Respinsiboe for calling create token for a card api
     - Parameter cardTokenRequest: The cardToken request model to be called with
     - Parameter onResponseReady: A block to call when getting the response
     - Parameter onErrorOccured: A block to call when an error occured
     */
    func callCardTokenAPI(cardTokenRequestModel:TapCreateTokenRequest, onResponeReady: @escaping (Token) -> () = {_ in}, onErrorOccured: @escaping(Error)->() = {_ in}) {
        
        // Change the model into a dictionary
        guard let bodyDictionary = TapCheckout.convertModelToDictionary(cardTokenRequestModel, callingCompletionOnFailure: { error in
            onErrorOccured(error.debugDescription)
            return
        }) else { return }
        
        // Call the corresponding api based on the transaction mode
        // Perform the retrieve request with the computed data
        NetworkManager.shared.makeApiCall(routing: cardTokenRequestModel.route, resultType: Token.self, body: .init(body: bodyDictionary),httpMethod: .POST, urlModel: .none) { (session, result, error) in
            // Double check all went fine
            guard let parsedResponse:Token = result as? Token else {
                onErrorOccured("Unexpected error parsing into token")
                return
            }
            // Execute the on complete block
            onResponeReady(parsedResponse)
        } onError: { (session, result, errorr) in
            // In case of an error we execute the on error block
            onErrorOccured(errorr.debugDescription)
        }
    }
    
    
    /**
     Respinsiboe for calling a get request for a retrivable object (e.g. charge, authorization, etc.) by providing its ID
     - Parameter with identifier: The id of the object we want to retrieve
     - Parameter onResponseReady: A block to call when getting the response
     - Parameter onErrorOccured: A block to call when an error occured
     */
    func retrieveObject<T: Retrievable>(with identifier: String, completion: @escaping Completion<T>, onErrorOccured: @escaping(Error)->() = {_ in}) {
        
        // Create the GET url parameter model
        let urlModel = TapURLModel.array(parameters: [identifier])
        // Fetch the retrieve route based on the type of the object the method called on
        let route = T.retrieveRoute
        
        // Perform the retrieve request with the computed data
        NetworkManager.shared.makeApiCall(routing: route, resultType: T.self, body: .none,httpMethod: .GET, urlModel: urlModel) { (session, result, error) in
            // Double check all went fine
            guard let parsedResponse:T = result as? T else {
                onErrorOccured("Unexpected error parsing into")
                return
            }
            // Execute the on complete block
            completion(parsedResponse,nil)
        } onError: { (session, result, errorr) in
            // In case of an error we execute the on error block
            onErrorOccured(errorr.debugDescription)
        }
    }
    
    
    /// Authenticates an `object` with `details` calling `completion` when request finishes.
    ///
    /// - Parameters:
    ///   - object: Authenticatable object.
    ///   - details: Authentication details.
    ///   - completion: Completion that will be called when request finishes.
    ///   - onErrorOccured: A block to call when an error occured
    func authenticate<T: Authenticatable>(_ object: T, details: TapAuthenticationRequest, onResponeReady: @escaping (T) -> (), onErrorOccured: @escaping(Error)->() = {_ in}) {
        
        // Change the model into a dictionary
        guard let bodyDictionary = TapCheckout.convertModelToDictionary(details, callingCompletionOnFailure: { error in
            onErrorOccured(error.debugDescription)
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
                onErrorOccured("Unexpected error parsing verification of otp authentication details")
                return
            }
            // Execute the on complete block
            onResponeReady(parsedResponse)
        } onError: { (session, result, errorr) in
            // In case of an error we execute the on error block
            onErrorOccured(errorr.debugDescription)
        }
    }
    
    
    /// Retrieves BIN number details for the given `binNumber` and calls `completion` when request finishes.
    ///
    /// - Parameters:
    ///   - binNumber: First 6 digits of the card.
    ///   - completion: Completion that will be called when request finishes.
    func getBINDetails(for binNumber: String, onResponeReady: @escaping (TapBinResponseModel) -> () = {_ in}, onErrorOccured: @escaping(Error)->() = {_ in}) {
        
        let urlModel = TapURLModel.array(parameters: [binNumber])
        
        // Perform the retrieve request with the computed data
        NetworkManager.shared.makeApiCall(routing: TapNetworkPath.bin, resultType: TapBinResponseModel.self, body: .none,httpMethod: .GET, urlModel: urlModel) { (session, result, error) in
            // Double check all went fine
            guard let parsedResponse:TapBinResponseModel = result as? TapBinResponseModel else {
                onErrorOccured("Unexpected error parsing bin details")
                return
            }
            // Execute the on complete block
            onResponeReady(parsedResponse)
        } onError: { (session, result, errorr) in
            // In case of an error we execute the on error block
            onErrorOccured(errorr.debugDescription)
        }
        
    }
    
    
    /**
     Respinsiboe for calling charge
     - Parameter bodyDictionary: The charge request model to be called with
     - Parameter onResponseReady: A block to call when getting the response
     - Parameter onErrorOccured: A block to call when an error occured
     */
    fileprivate func callChargeAPI(bodyDictionary:[String : Any], onResponeReady: @escaping (Charge) -> () = {_ in}, onErrorOccured: @escaping(Error)->() = {_ in}) {
        // Call the charge API
        NetworkManager.shared.makeApiCall(routing: .charges, resultType: Charge.self, body: .init(body: bodyDictionary), httpMethod: .POST) { (session, result, error) in
            if let error = error {
                onErrorOccured(error)
            }else{
                guard let charge:Charge = result as? Charge else { onErrorOccured("Unexpected error parsing into Charge")
                    return }
                // Call success block
                onResponeReady(charge)
            }
        } onError: { (session, result, errorr) in
            onErrorOccured(errorr.debugDescription)
        }
    }
    
    /**
     Respinsiboe for calling authorize
     - Parameter bodyDictionary: The authorize request model to be called with
     - Parameter onResponseReady: A block to call when getting the response
     - Parameter onErrorOccured: A block to call when an error occured
     */
    fileprivate func callAuthorizeAPI(bodyDictionary:[String : Any], onResponeReady: @escaping (Authorize) -> () = {_ in}, onErrorOccured: @escaping(Error)->() = {_ in}) {
        // Call the authorize API
        NetworkManager.shared.makeApiCall(routing: .authorize, resultType: Authorize.self, body: .init(body: bodyDictionary), httpMethod: .POST) { (session, result, error) in
            if let error = error {
                onErrorOccured(error)
            }else{
                guard let authorize:Authorize = result as? Authorize else { onErrorOccured("Unexpected error parsing into Authorize")
                    return }
                // Call success block
                onResponeReady(authorize)
            }
        } onError: { (session, result, errorr) in
            onErrorOccured(errorr.debugDescription)
        }
    }
    
    /**
     Respinsiboe for deleting a saved card with saved card api
     - Parameter savedCard: The saved card in interest to delete
     - Parameter onResponseReady: A block to call when getting the response
     - Parameter onErrorOccured: A block to call when an error occured
     */
    func callSavedCardDeletion(for savedCard:SavedCard,  onResponeReady: @escaping (TapDeleteSavedCardResponseModel) -> () = {_ in}, onErrorOccured: @escaping(Error)->() = {_ in}) {
        //Make sure the needed details are in its place
        guard let customerID:String  = dataHolder.transactionData.customer.identifier,
              let savedCardID:String = savedCard.identifier else {
            handleError(error: "Cannot delete a saved card without a customer id")
            return
        }
        
        // Create the network call details
        let route = TapNetworkPath.card
        #warning("TEST DELETE")
        let urlModel = TapURLModel.array(parameters: [customerID, "adasdasd"])
        
        
        // Perform the delete a saved card request with the computed data
        NetworkManager.shared.makeApiCall(routing: route, resultType: TapDeleteSavedCardResponseModel.self, body: nil, httpMethod: .DELETE, urlModel: urlModel) { (session, result, error) in
            // Double check all went fine
            guard let parsedResponse:TapDeleteSavedCardResponseModel = result as? TapDeleteSavedCardResponseModel else {
                onErrorOccured("Unexpected error parsing into TapDeleteSavedCardResponseModel")
                return
            }
            // Execute the on complete block
            onResponeReady(parsedResponse)
        } onError: { (session, result, errorr) in
            // In case of an error we execute the on error block
            onErrorOccured(errorr.debugDescription)
        }
    }
    
    
    /**
     Respinsiboe for logging all the details when an error occures
     - Parameter loggedData: The data to be logged in
     - Parameter onResponseReady: A block to call when getting the response
     - Parameter onErrorOccured: A block to call when an error occured
     */
    func callLogging(for loggedData:TapLogRequestModel,  onResponeReady: @escaping (String) -> () = {_ in}, onErrorOccured: @escaping(Error)->() = {_ in}) {
        
        // Create the network call details
        let route = TapNetworkPath.logging
        // Change the model into a dictionary
        guard let bodyDictionary = TapCheckout.convertModelToDictionary(loggedData, callingCompletionOnFailure: { error in
            return
        }) else { return }
        
        // Perform the delete a saved card request with the computed data
        NetworkManager.shared.makeApiCall(routing: route, resultType: String.self, body: .init(body: bodyDictionary), httpMethod: .POST, urlModel: nil) { (session, result, error) in
            // Double check all went fine
            guard let _:String = result as? String else {
                //onErrorOccured("Unexpected error parsing into TapDeleteSavedCardResponseModel")
                return
            }
            // Execute the on complete block
            //onResponeReady(parsedResponse)
        } onError: { (session, result, errorr) in
            // In case of an error we execute the on error block
            // onErrorOccured(errorr.debugDescription)
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
