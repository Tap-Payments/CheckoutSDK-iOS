//
//  CountryCode.swift
//  goSellSDK
//
//  Copyright © 2019 Tap Payments. All rights reserved.
//

/// Country model.
@objcMembers public final class Country: NSObject {
    
    // MARK: - Public -
    // MARK: Properties
    
    /// Two-letters iso code.
    public let isoCode: String
    
    // MARK: Methods
    
    public static func == (lhs: Country, rhs: Country) -> Bool {
        
        return lhs.isoCode.lowercased() == rhs.isoCode.lowercased()
    }
    
    // MARK: - Internal -
    // MARK: Methods
    
    @objc public init(isoCode: String) throws {
        
        let code = isoCode.uppercased()
        
        if Country.allISOCodes.contains(code) {
            self.isoCode = code
        }else {
            // couldn't find it using the iso code, let us check if we have the country name
            guard let codeFromName:String = Country.locale(for: isoCode) else {
                let userInfo = [ErrorConstants.UserInfoKeys.countryCode: code]
                let underlyingError = NSError(domain: ErrorConstants.internalErrorDomain, code: InternalError.invalidCountryCode.rawValue, userInfo: userInfo)
                throw TapSDKKnownError(type: .internal, error: underlyingError, response: nil, body: nil)
            }
            self.isoCode = codeFromName
        }
    }
    
    /// Tries to detect the iso code for the a given country name
    private static func locale(for fullCountryName : String) -> String? {
        
        for localeCode in NSLocale.isoCountryCodes {
            let identifier = NSLocale(localeIdentifier: "en")
            let countryName = identifier.displayName(forKey: NSLocale.Key.countryCode, value: localeCode)
            if fullCountryName.lowercased() == countryName?.lowercased() ||
                (countryName?.lowercased() ?? "").contains(fullCountryName.lowercased()) {
                return localeCode
            }
        }
        return nil
    }
    
    internal convenience init(_ isoCode: String) throws {
        
        try self.init(isoCode: isoCode)
    }
    
    // MARK: - Private -
    private static let allISOCodes = Locale.isoRegionCodes.map { $0.uppercased() }
}

// MARK: - Decodable
extension Country: Decodable {
    
    public convenience init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        let code = try container.decode(String.self)
        
        try self.init(isoCode: code)
    }
}

// MARK: - Encodable
extension Country: Encodable {
    
    /// Encodes the contents of the receiver.
    ///
    /// - Parameter encoder: Encoder.
    /// - Throws: EncodingError
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.singleValueContainer()
        try container.encode(self.isoCode)
    }
}
