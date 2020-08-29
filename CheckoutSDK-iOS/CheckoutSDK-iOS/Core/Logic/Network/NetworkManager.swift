//
//  NetworkManager.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/20/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import TapNetworkKit_iOS

internal class NetworkManager: NSObject {
    static let shared = NetworkManager()
    private var headers = ["decive_model": "iphone", "os_version": "ios 13"]
    private var networkManager: TapNetworkManager
    private let baseURL = "https://run.mocky.io/v3/"
    public var enableLogging = false
    
    private override init () {
        networkManager = TapNetworkManager(baseURL: URL(string: baseURL)!)
    }
    
    internal func makeApiCall<T:Decodable>(routing: TapNetworkPath, resultType:T.Type,body:[String:Any] = [:], completion: TapNetworkManager.RequestCompletionClosure?) {
        networkManager.isRequestLoggingEnabled = enableLogging
        
        let requestOperation = TapNetworkRequestOperation(path: "\(baseURL)\(routing.rawValue)", method: .GET, headers: headers, urlModel: .none, bodyModel: .init(body: body), responseType: .json)
        networkManager.performRequest(requestOperation, completion: { (session, result, error) in
            print("result is: \(String(describing: result))")
            print("error: \(String(describing: error))")
            completion?(session, result, error)
        }, codableType: resultType)
    }
}
