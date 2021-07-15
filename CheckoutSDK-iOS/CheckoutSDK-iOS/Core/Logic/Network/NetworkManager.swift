//
//  NetworkManager.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/20/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import TapNetworkKit_iOS
import TapApplicationV2
import CoreTelephony

/// The shared network manager related to configure the network/api class between the SDK and the Server
internal class NetworkManager: NSObject {
    /// The singletong network manager
    static let shared = NetworkManager()
    /// The static headers to be sent with every call/request
    private var headers:[String:String] {
      return  NetworkManager.staticHTTPHeaders
    }
    private var networkManager: TapNetworkManager
    /// The server base url
    private let baseURL = "https://api.tap.company/v2/"
    public var enableLogging = false
    
    internal var loggedApis:[String] {
        return networkManager.loggedInApiCalls
    }
    
    private override init () {
        networkManager = TapNetworkManager(baseURL: URL(string: baseURL)!)
    }
    
    /**
     Used to dispatch a network call with the needed configurations
     - Parameter routing: The path the request should hit.
     - Parameter resultType: A generic decodable class that the result will be parsed into.
     - Parameter body: A dictionay to pass any more data you want to pass as a body of the request.
     - Parameter httpMethod: The type of the http request.
     - Parameter completion: A block to be executed upon finishing the network call
     - Parameter onError: A block to be executed upon error
     */
    internal func makeApiCall<T:Decodable>(routing: TapNetworkPath, resultType:T.Type,body:TapBodyModel? = .none, httpMethod: TapHTTPMethod = .GET, urlModel:TapURLModel? = .none, completion: TapNetworkManager.RequestCompletionClosure?,onError:TapNetworkManager.RequestCompletionClosure?) {
        // Inform th network manager if we are going to log or not
        networkManager.isRequestLoggingEnabled = enableLogging
        
        // Group all the configurations and pass it to the network manager
        let requestOperation = TapNetworkRequestOperation(path: "\(baseURL)\(routing.rawValue)", method: httpMethod, headers: headers, urlModel: urlModel, bodyModel: body, responseType: .json)
        
        // Perform the actual request
        networkManager.performRequest(requestOperation, completion: { (session, result, error) in
            //print("result is: \(String(describing: result))")
            //print("error: \(String(describing: error))")
        
            //Check for errors
            if let error = error {
                onError?(session,result,error)
                return
            }
            // Check we need to do the on error callbak or not
            guard let correctParsing = result as? T else {
                guard let detectedError = self.detectError(from: result, and: error) else {
                    return
                }
                onError?(session,result,detectedError)
                return
            }
            completion?(session, correctParsing, error)
            
        }, codableType: resultType)
    }
    
    
    /**
     Used to detect if an error occured whether a straight forward error like invalid parsing or a backend error
     - Parameter response: The data came from the backend, to check if itself has a backend error like "Invalid api key", this will have the highest prioirty to display
     - Parameter error: The error if any came from the network manager parser like invalid json, malformed data, etc.
     - Returns: An error that will have response error as a priority and nil of non of them containted a valid error
     */
    internal func detectError(from response:Any?,and error:Error?) -> Error? {
        // First check the error coming from backend
        if let response = response {
            // Try to parse it into our error backend model
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
                let decodedErrorResponse:ApiErrorModel = try JSONDecoder().decode(ApiErrorModel.self, from: jsonData)
                // Check if an error from backend was actually sent
                if !decodedErrorResponse.errors.isEmpty {
                    return decodedErrorResponse.errors[0].description
                }
            }catch{}
        }else if let error = error {
            // Now as there is no a backend error, time to check if there was a local error by parsing the json data
            return error
        }
        // All good!
        return nil
    }
}
