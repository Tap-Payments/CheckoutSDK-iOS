//
//  TapLoggedRequestModel.swift
//  TapNetworkKit-iOS
//
//  Created by Osama Rabie on 7/15/21.
//

import Foundation

/// TapLoggedRequestModel model.
public struct TapLoggedResponseRequestModel: Codable {
    
    // MARK: - Internal -
    // MARK: Properties
    
    /// The url of the request/response
    public var url: String = ""
    
    /// The headers of the request/response
    public var headers: String = ""
    
    /// The params of the request/response
    public var params: String = ""
    
    /// The type of the request/response
    public var methodType:String = ""
    
    /// The type of the request/response
    public var response:String = ""
    
    // MARK: Methods
    
    /**
     Creates a new request/response logging model
     - Parameter url:       The url of the request/response
     - Parameter headers:   The headers of the request/response
     - Parameter params:    The params of the request/response
     - Parameter methodType:The type of the request/response
     */
    public init(url:String, headers:String, params:String, methodType:String, response:String) {
        self.url        = url
        self.headers    = headers
        self.params     = params
        self.methodType = methodType
        self.response   = response
    }
    
    // MARK: - Private -
    
    private enum CodingKeys: String, CodingKey {
        
        case url        = "url"
        case headers    = "headers"
        case params     = "params"
        case methodType = "methodType"
        case response   = "response"
    }
}
