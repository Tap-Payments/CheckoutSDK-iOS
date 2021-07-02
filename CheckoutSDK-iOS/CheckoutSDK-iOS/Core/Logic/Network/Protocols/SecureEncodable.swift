//
//  SecureEncodable.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/2/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// Secure Encodable protocol.
internal protocol SecureEncodable: Encodable { }

internal extension SecureEncodable {
    
    // MARK: - Internal -
    // MARK: Methods
    
    /// Secure encodes the model.
    ///
    /// - Parameter encoder: Encoder to use.
    /// - Returns: Secure encoded model.
    /// - Throws: Either encoding error or serialization error.
    func secureEncoded(using encoder: JSONEncoder = JSONEncoder()) throws -> String {
        
        let jsonData = try encoder.encode(self)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            
            throw "Secure encoding wrong data parsed to string"
        }
        
        guard let encryptionKey = TapCheckout.sharedCheckoutManager().dataHolder.transactionData.intitModelResponse?.data.encryptionKey else {
            
            throw "Secure encoding wrong data missing encryption key"
        }
        
        guard let encrypted = Crypter.encrypt(jsonString, using: encryptionKey) else {
            
            throw "Secure encoding wrong data encrypting with the encryption key"
        }
        
        return encrypted
    }
}
