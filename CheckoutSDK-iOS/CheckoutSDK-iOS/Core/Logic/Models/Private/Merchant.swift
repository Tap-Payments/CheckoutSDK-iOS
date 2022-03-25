//
//  Merchant.swift
//  goSellSDK
//
//  Copyright © 2019 Tap Payments. All rights reserved.
//

/// Merchant model.
internal struct Merchant: Codable {
	
    // MARK: - Internal -
    // MARK: Properties
	
	/// Merchant identifier.
	internal private(set) var identifier: String?
	
    /// Merchant name
    internal private(set) var name: String?
    
    /// Merchant logo URL
    internal private(set) var logoURL: String?
	
	// MARK: Methods
	
	/// Initializes merchant with the identifier.
	///
	/// - Parameter identifier: Merchant identifier.
	internal init(identifier: String) {
		
		self.identifier	= identifier
	}
    
    
    /// Initializes merchant with the identifier.
    ///
    /// - Parameter logoURL: Merchant logo url.
    /// - Parameter name: Merchant name
    internal init(logoURL: String, name: String) {
        
        self.name       = name
        self.logoURL    = logoURL
    }
	
    // MARK: - Private -
    
    private enum CodingKeys: String, CodingKey {

		case identifier	= "id"
        case name       = "name"
        case logoURL    = "logo"
    }
}
