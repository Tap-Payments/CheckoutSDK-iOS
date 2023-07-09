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
        // As per the backend logic, we will have to hit CheckoutProfile api to load merchant & payment options data
        let sharedManager = TapCheckout.sharedCheckoutManager()
        
        // Create the payment option request with the configured data from the user
        let paymentOptionRequest = sharedManager.createPaymentOptionRequestModel()
        
        // Change the model into a dictionary
        guard let bodyDictionary = TapCheckout.convertModelToDictionary(paymentOptionRequest, callingCompletionOnFailure: { error in
            return
        }) else { return }
        
        
        NetworkManager.shared.makeApiCall(routing: .CheckoutProfileApi, resultType: TapInitResponseModel.self, body: .init(body: bodyDictionary), httpMethod: .POST) { [weak self] (session, result, error) in
            guard let initModel:TapInitResponseModel = result as? TapInitResponseModel else { self?.handleError(session: session, result: result, error: "Unexpected error when parsing into TapInitResponseModel")
                return }
            // We will only load the default values if and only if, the already cached and loaded theme and localisation is not the default one and if it is the defailt one we have a different default value
            if self?.shouldLoadDefaultThemeAndLocalisation(lightThemeUrlApi: initModel.assets.theme.lighMobileOnly, darkThemeUrlApi: initModel.assets.theme.darkMobileOnly, localisationUrlApi: initModel.assets.localisation.url) ?? true {
                DispatchQueue.background(background: {
                    // Load the default theme & localisations if the user didn't pass his own custom theme and localisation
                    TapCheckout.PreloadSDKData(localiseFile: self?.dataHolder.themeLocalisationHolder.localiseFile ?? .init(with: URL(string: initModel.assets.localisation.url)!, from: .RemoteJsonFile),
                                               customTheme: self?.dataHolder.themeLocalisationHolder.customTheme ?? .init(with: initModel.assets.theme.light, and: initModel.assets.theme.dark, from: .RemoteJsonFile))
                }, completion:{
                    // when background job finished, do something in main thread
                    print("COMPLETED")
                    self?.handleInitResponse(initModel: initModel)
                    onCheckOutReady()
                })
            }else{
                self?.handleInitResponse(initModel: initModel)
                onCheckOutReady()
            }
        } onError: { (session, result, errorr) in
            self.handleError(session: session, result: result, error: errorr)
        }
    }
    
    
    /// This method will instruct if we need to load the default theme and localisation we got from the checkout profile api or not.
    /// We already preload them before calling the checkout profile api, hence we will return TRUE only if the default urls passed from checkout profile for some reason are different than the ones we loaded
    func shouldLoadDefaultThemeAndLocalisation(lightThemeUrlApi:String, darkThemeUrlApi:String, localisationUrlApi:String) -> Bool {
        // First check if we cached the default theme and localisation and not passed by merchant already
        let sharedManager:TapCheckout = TapCheckout.sharedCheckoutManager()
        guard sharedManager.dataHolder.themeLocalisationHolder.localiseFile?.filePath?.absoluteString == TapCheckout.defaultLocalisationURL,
              sharedManager.dataHolder.themeLocalisationHolder.customTheme?.lightModeThemeFileName == TapCheckout.defaultThemeLightURL else {
            // This means the user didn't pass naything and we cached the default values,
            // now it is time to check if the api sent a different urls for the default values
            guard sharedManager.dataHolder.themeLocalisationHolder.localiseFile?.filePath?.absoluteString == localisationUrlApi,
                  sharedManager.dataHolder.themeLocalisationHolder.customTheme?.lightModeThemeFileName == lightThemeUrlApi else {
                // This means, the backend sent a different urls, and hence, we need to load the new default ones
                return true
            }
            // This means, the backend sent the same default urls we already preloaded, so no need to load it again
            return false
        }
        
        // This means, we already loaded what the user passed as a custom theme and we are not using any default values. Hence, we don't have to load the default theme and localisation now
        return false
    }
    
    /**
     Respinsiboe for calling charge or authorize api
     - Parameter chargeRequestModel: The charge request model to be called with
     - Parameter onResponseReady: A block to call when getting the response
     - Parameter onErrorOccured: A block to call when an error occured
     */
    func callChargeOrAuthorizeAPI(chargeRequestModel:TapChargeRequestModel, onResponeReady: @escaping (ChargeProtocol) -> () = {_ in}, onErrorOccured: @escaping(TapNetworkManager.RequestCompletionClosure)) {
        
        // Change the model into a dictionary
        guard let bodyDictionary = TapCheckout.convertModelToDictionary(chargeRequestModel, callingCompletionOnFailure: { error in
            onErrorOccured(nil,nil,error.debugDescription)
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
    func callCardVerifyAPI(cardVerifyRequestModel:TapCreateCardVerificationRequestModel, onResponeReady: @escaping (TapCreateCardVerificationResponseModel) -> () = {_ in}, onErrorOccured: @escaping(TapNetworkManager.RequestCompletionClosure)) {
        
        // Change the model into a dictionary
        guard let bodyDictionary = TapCheckout.convertModelToDictionary(cardVerifyRequestModel, callingCompletionOnFailure: { error in
            onErrorOccured(nil,nil,error.debugDescription)
            return
        }) else { return }
        
        // Call the corresponding api based on the transaction mode
        // Perform the retrieve request with the computed data
        NetworkManager.shared.makeApiCall(routing: TapNetworkPath.cardVerification, resultType: TapCreateCardVerificationResponseModel.self, body: .init(body: bodyDictionary),httpMethod: .POST, urlModel: .none) { (session, result, error) in
            // Double check all went fine
            guard let parsedResponse:TapCreateCardVerificationResponseModel = result as? TapCreateCardVerificationResponseModel else {
                onErrorOccured(session, result,"Unexpected error parsing into TapCreateCardVerificationResponseModel")
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
     Respinsiboe for calling create token for a card api
     - Parameter cardTokenRequest: The cardToken request model to be called with
     - Parameter onResponseReady: A block to call when getting the response
     - Parameter onErrorOccured: A block to call when an error occured
     */
    func callCardTokenAPI(cardTokenRequestModel:TapCreateTokenRequest, onResponeReady: @escaping (Token) -> () = {_ in}, onErrorOccured: @escaping(TapNetworkManager.RequestCompletionClosure)) {
        
        // Change the model into a dictionary
        guard let bodyDictionary = TapCheckout.convertModelToDictionary(cardTokenRequestModel, callingCompletionOnFailure: { error in
            onErrorOccured(nil,nil,error.debugDescription)
            return
        }) else { return }
        
        // Call the corresponding api based on the transaction mode
        // Perform the retrieve request with the computed data
        NetworkManager.shared.makeApiCall(routing: cardTokenRequestModel.route, resultType: Token.self, body: .init(body: bodyDictionary),httpMethod: .POST, urlModel: .none) { (session, result, error) in
            // Double check all went fine
            guard let parsedResponse:Token = result as? Token else {
                onErrorOccured(session, result, "Unexpected error parsing into token")
                return
            }
            // Execute the on complete block
            onResponeReady(parsedResponse)
        } onError: { (session, result, errorr) in
            // In case of an error we execute the on error block
            onErrorOccured(session, result, errorr.debugDescription)
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
    
    /**
     Respinsiboe for deleting a saved card with saved card api
     - Parameter savedCard: The saved card in interest to delete
     - Parameter onResponseReady: A block to call when getting the response
     - Parameter onErrorOccured: A block to call when an error occured
     */
    func callSavedCardDeletion(for savedCard:SavedCard,  onResponeReady: @escaping (TapDeleteSavedCardResponseModel) -> () = {_ in}, onErrorOccured: @escaping(TapNetworkManager.RequestCompletionClosure)) {
        //Make sure the needed details are in its place
        guard let customerID:String  = dataHolder.transactionData.customer.identifier,
              let savedCardID:String = savedCard.identifier else {
            handleError(session: nil, result: nil, error: "Cannot delete a saved card without a customer id")
            return
        }
        
        // Create the network call details
        let route = TapNetworkPath.card
        let urlModel = TapURLModel.array(parameters: [customerID, savedCardID])
        
        
        // Perform the delete a saved card request with the computed data
        NetworkManager.shared.makeApiCall(routing: route, resultType: TapDeleteSavedCardResponseModel.self, body: nil, httpMethod: .DELETE, urlModel: urlModel) { (session, result, error) in
            // Double check all went fine
            guard let parsedResponse:TapDeleteSavedCardResponseModel = result as? TapDeleteSavedCardResponseModel else {
                onErrorOccured(session, result, "Unexpected error parsing into TapDeleteSavedCardResponseModel")
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
        DispatchQueue.main.async {
            TapCheckout.sharedCheckoutManager().dataHolder.transactionData.paymentOptionsModelResponse = initModel.paymentOptions
        }
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
