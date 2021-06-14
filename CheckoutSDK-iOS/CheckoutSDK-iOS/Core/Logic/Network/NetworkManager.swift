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
    private var headers:[String:String] = NetworkManager.applicationStaticDetails()
    private var networkManager: TapNetworkManager
    /// The server base url
    private let baseURL = "https://api.tap.company/v2/"
    public var enableLogging = false
    
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
     */
    internal func makeApiCall<T:Decodable>(routing: TapNetworkPath, resultType:T.Type,body:[String:Any] = [:],httpMethod: TapHTTPMethod = .GET, completion: TapNetworkManager.RequestCompletionClosure?) {
        // Inform th network manager if we are going to log or not
        networkManager.isRequestLoggingEnabled = enableLogging
        
        // Group all the configurations and pass it to the network manager
        let requestOperation = TapNetworkRequestOperation(path: "\(baseURL)\(routing.rawValue)", method: httpMethod, headers: headers, urlModel: .none, bodyModel: .none, responseType: .json)
        
        // Perform the actual request
        networkManager.performRequest(requestOperation, completion: { (session, result, error) in
            print("result is: \(String(describing: result))")
            print("error: \(String(describing: error))")
            completion?(session, result, error)
        }, codableType: resultType)
    }
}
