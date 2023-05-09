//
//  TapConfigResponseModel.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 24/03/2022.
//  Copyright © 2022 Tap Payments. All rights reserved.
//

import Foundation
/// Config api response model
public struct TapConfigResponseModel: Codable {
    let redirectURL: String
    public var checkoutURL:String {
        return "\(redirectURL.replacingOccurrences(of: "https://checkout.dev.tap.company/", with: "https://ios-wrapper.netlify.app/"))&fromSDK=true"
    }
    enum CodingKeys: String, CodingKey {
        case redirectURL = "redirect_url"
    }
}

// MARK: Welcome convenience initializers and mutators

extension TapConfigResponseModel {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(TapConfigResponseModel.self, from: data)
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        redirectURL: String? = nil
    ) -> TapConfigResponseModel {
        return TapConfigResponseModel(
            redirectURL: redirectURL ?? self.redirectURL
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}
