//
//  NetworkManager.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/20/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import TapNetworkKit_iOS
import CheckoutSDK_iOS

@objc public class NetworkManager: NSObject {
    static let shared = NetworkManager()
    private var headers = ["decive_model": "iphone", "os_version": "ios 13"]
    private var networkManager: TapNetworkManager
    private let _baseURL = "https://run.mocky.io/v3/"
    public var enableLogging = false
    
    private override init () {
        networkManager = TapNetworkManager(baseURL: URL(string: _baseURL)!)
    }
    
    public func makeApiCall<T:Decodable>(resultType:T.Type, completion: TapNetworkManager.RequestCompletionClosure?) {
        networkManager.isRequestLoggingEnabled = enableLogging
        let requestOperation = TapNetworkRequestOperation(path: "aaf816bd-4c67-4d9e-acfe-ba35ff919875", method: .GET, headers: headers, urlModel: .none, bodyModel: .none, responseType: .json)
        
        networkManager.performRequest(requestOperation, completion: { (session, result, error) in
            print("result is: \(String(describing: result))")
            print("error: \(String(describing: error))")
            completion?(session, result, error)
        }, codableType: resultType)
    }
}
