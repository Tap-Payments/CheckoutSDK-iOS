//
//  TapPaymentOptionsRequest.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/15/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import CommonDataModelsKit_iOS

internal struct TapPaymentOptionsRequestModel {
    
    // MARK: - Internal -
    // MARK: Properties
    
    /// Transaction mode.
    internal let transactionMode: TransactionMode?
    
    /// Items to pay for.
    internal let items: [ItemModel]?
    
    /// Items shippings.
    internal var shipping: [Shipping]?
    
    /// Taxes.
    internal var taxes: [Tax]?
    
    /// Items currency.
    internal let currency: TapCurrencyCode?
    
    /// Merchant ID.
    internal let merchantID: String?
    
    /// Customer (payer).
    internal var customer: TapCustomer?
    
    /// List of destinations (grouped by "destination" key).
    internal private(set) var destinationGroup: DestinationGroup?
    
    /// Payment type.
    internal private(set) var paymentType: TapPaymentType?
    
    // MARK: Methods
    
    internal init(customer: TapCustomer?) {
        
        self.init(transactionMode: nil, amount: nil, items: nil, shipping: nil, taxes: nil, currency: nil, merchantID: nil, customer: customer, destinationGroup: nil, paymentType: nil)
    }
    
    internal init(transactionMode:      TransactionMode?,
                  amount:               Double?,
                  items:                [ItemModel]?,
                  shipping:             [Shipping]?,
                  taxes:                [Tax]?,
                  currency:             TapCurrencyCode?,
                  merchantID:           String?,
                  customer:             TapCustomer?,
                  destinationGroup:     DestinationGroup?,
                  paymentType:          TapPaymentType?
                  
    ) {
        
        self.transactionMode        = transactionMode
        self.shipping               = shipping
        self.taxes                  = taxes
        self.currency               = currency
        self.merchantID             = merchantID
        self.customer               = customer
        self.destinationGroup       = destinationGroup
        self.paymentType            = paymentType
        
        if let nonnullItems         = items, nonnullItems.count > 0 {
            
            self.items = items
        }
        else {
            
            self.items = nil
        }
        
        self.totalAmount = TapCheckoutSharedManager.sharedCheckoutManager().transactionTotalAmountValue
    }
    
    // MARK: - Private -
    
    private enum CodingKeys: String, CodingKey {
        
        case transactionMode        = "transaction_mode"
        case items                  = "items"
        case shipping               = "shipping"
        case taxes                  = "taxes"
        case currency               = "currency"
        case customer               = "customer"
        case totalAmount            = "total_amount"
        case merchantID             = "merchant_id"
        case destinationGroup       = "destinations"
        case paymentType            = "payment_type"
    }
    
    // MARK: Properties
    
    private let totalAmount: Double
}

// MARK: - Encodable
extension TapPaymentOptionsRequestModel: Encodable {
    
    /// Encodes the contents of the receiver.
    ///
    /// - Parameter encoder: Encoder.
    /// - Throws: EncodingError
    internal func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(self.transactionMode, forKey: .transactionMode)
        try container.encodeIfPresent(self.items, forKey: .items)
        
        if self.shipping?.count ?? 0 > 0 {
            
            try container.encodeIfPresent(self.shipping, forKey: .shipping)
        }
        
        if self.taxes?.count ?? 0 > 0 {
            
            try container.encodeIfPresent(self.taxes, forKey: .taxes)
        }
        
        try container.encodeIfPresent(self.currency, forKey: .currency)
        
        try container.encodeIfPresent(self.merchantID, forKey: .merchantID)
        
        if let customer:TapCustomer = self.customer {
            
            try container.encodeIfPresent(customer, forKey: .customer)
        }
        
        if self.totalAmount > 0.0 {
            
            try container.encodeIfPresent(self.totalAmount, forKey: .totalAmount)
        }
        
        if self.destinationGroup?.destinations?.count ?? 0 > 0 {
            
            try container.encodeIfPresent(self.destinationGroup, forKey: .destinationGroup)
        }
    }
}
