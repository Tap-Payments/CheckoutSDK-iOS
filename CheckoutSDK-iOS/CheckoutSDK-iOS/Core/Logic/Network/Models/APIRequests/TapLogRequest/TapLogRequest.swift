//
//  TapLogRequest.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/29/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import CommonDataModelsKit_iOS
import CoreTelephony
import TapApplicationV2
import TapNetworkKit_iOS

/// TapLogRequestModel model.
internal struct TapLogRequestModel: Codable {
    
    /// Defines the details of the application + the SDK
    internal let application: TapLogApplicationModel?
    /// Defines the details of the current customer
    internal let customer:TapCustomer?
    /// Defines the details of the current merchant
    internal let merchant:TapLogMerchantModel?
    /// Defines the list of http calls since the begining of the session till now
    internal var stack_trace:[TapLogStackTraceEntryModel]?
    /// Defines the category of the error occured
    internal let error_catgeroy:String?
    
    /// TapLogRequestModel model.
    ///
    /// - Parameters:
    ///   - application: Defines the details of the application + the SDK
    ///   - customer: Defines the details of the current customer
    ///   - merchant: Defines the details of the current merchant
    ///   - stack_trace: Defines the list of http calls since the begining of the session till now
    ///   - error_category: Defines the category of the error occured
    internal init(application: TapLogApplicationModel?, customer: TapCustomer?, merchant: TapLogMerchantModel?, stack_trace: [TapLogStackTraceEntryModel]?, error_catgeroy: String?) {
        self.application = application
        self.customer = customer
        self.merchant = merchant
        self.stack_trace = stack_trace
        self.error_catgeroy = error_catgeroy
    }
    
    /// TapLogRequestModel model.
    internal init() {
        self.application = .init()
        self.customer = TapCheckout.sharedCheckoutManager().dataHolder.transactionData.customer
        self.merchant = .init()
        self.stack_trace = []
        self.error_catgeroy = nil
    }
}

/// Defines the details of the current merchant
internal struct TapLogMerchantModel: Codable {
    
    /// Merchant id
    internal let id: String?
    /// Merchant encryption key
    internal let auth_key_type:String?
    /// Merchant sdk mode
    internal let auth_key_mode: String?
    /// Merchant used key
    internal let auth_key_value:String?
    
    
    /// Defines the details of the current merchant
    ///
    /// - Parameters:
    ///   - id: Merchant id
    ///   - auth_key_type: Merchant encryption key
    ///   - auth_key_mode: Merchant sdk mode
    ///   - auth_key_value:Merchant used key
    init() {
        self.id = TapCheckout.sharedCheckoutManager().dataHolder.transactionData.tapMerchantID
        self.auth_key_type = TapCheckout.sharedCheckoutManager().dataHolder.transactionData.intitModelResponse?.data.encryptionKey
        self.auth_key_mode = TapCheckout.sharedCheckoutManager().dataHolder.transactionData.sdkMode.description
        self.auth_key_value = TapCheckout.secretKey.usedKey
    }
}
