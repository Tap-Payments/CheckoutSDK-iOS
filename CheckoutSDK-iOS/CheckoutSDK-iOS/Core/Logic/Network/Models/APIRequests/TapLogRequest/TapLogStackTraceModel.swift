//
//  TapLogStackTraceModel.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/30/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

internal struct TapLogStackTraceModel: Codable {
    
    
}

/// Represents the request model part of a HTTP call stacktrace
internal struct TapLogStrackTraceRequstModel: Codable {
    /// The type of the method
    let method:String?
    /// The headers in the request
    let headers:String?
    /// The base url of the request
    let base_url:String?
    /// The end point called in the request
    let end_point:String?
    /// The body of the request
    let body:String?
    
    
    internal init(method: String?, headers: String?, base_url: String?, end_point: String?, body: String?) {
        self.method = method
        self.headers = headers
        self.base_url = base_url
        self.end_point = end_point
        self.body = body
    }
    
}
