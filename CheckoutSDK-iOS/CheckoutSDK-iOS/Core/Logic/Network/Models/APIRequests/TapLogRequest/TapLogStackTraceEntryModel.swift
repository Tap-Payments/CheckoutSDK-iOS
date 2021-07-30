//
//  TapLogStackTraceModel.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/30/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation


/// Represents a full entry in the stack trace of HTTP request and response
internal struct TapLogStackTraceEntryModel: Codable {
    
    /// Represents the request part
    let request:TapLogStrackTraceRequstModel?
    /// Represents the response part
    let response:TapLogStrackTraceResponseModel?
    
    internal init(request: TapLogStrackTraceRequstModel?, response: TapLogStrackTraceResponseModel?) {
        self.request = request
        self.response = response
    }
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
        self.method     = method
        self.headers    = headers
        self.base_url   = base_url
        self.end_point  = end_point
        self.body       = body
    }
    
}


/// Represents the response model part of a HTTP call stacktrace
internal struct TapLogStrackTraceResponseModel: Codable {
    
    /// The headers in the response
    let headers:String?
    /// The error code coming in the response
    let error_code:String?
    /// The error message coming in the response
    let error_message:String?
    /// The error description coming in the response
    let error_description:String?
    
    
    internal init(headers: String?, error_code: String?, error_message: String?, error_description: String?) {
        self.headers            = headers
        self.error_code         = error_code
        self.error_message      = error_message
        self.error_description  = error_description
    }
    
}
