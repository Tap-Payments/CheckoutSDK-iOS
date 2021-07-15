//
//  TapLoggingModel.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/15/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// TapLoggedRequestModel model.
internal struct TapLoggingModel: Codable {
    
    // MARK: - Internal -
    // MARK: Properties
    
    /// The logged in requests and responses
    public var loggedRequests:[String] = [""]
    
    /// The error occureed at the end
    public var error: String = ""
    
    // MARK: Methods
    
    /**
     Creates a new TapLoggedRequestModel model.
     - Parameter loggedRequests:    The logged in requests and responses
     - Parameter error:             The error occureed at the end
     */
    public init(loggedRequests:[String], error:String?) {
        self.loggedRequests = loggedRequests
        self.error          = error ?? ""
    }
    
    // MARK: - Private -
    
    private enum CodingKeys: String, CodingKey {
        
        case loggedRequests = "loggedRequests"
        case error          = "error"
    }
}

