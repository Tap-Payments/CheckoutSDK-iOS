//
//  TapCheckout+CommonExtensions.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 03/05/2023.
//  Copyright © 2023 Tap Payments. All rights reserved.
//

import Foundation

internal extension Data {
    /// Same as ``Data(base64Encoded:)``, but adds padding automatically
    /// (if missing, instead of returning `nil`).
    static func fromBase64(_ encoded: String) -> Data? {
        // Prefixes padding-character(s) (if needed).
        var encoded = encoded;
        let remainder = encoded.count % 4
        if remainder > 0 {
            encoded = encoded.padding(
                toLength: encoded.count + 4 - remainder,
                withPad: "=", startingAt: 0);
        }
        
        // Finally, decode.
        return Data(base64Encoded: encoded);
    }
}

internal extension String {
    static func fromBase64(_ encoded: String?) -> String? {
        if let data = Data.fromBase64(encoded ?? "") {
            return String(data: data, encoding: .utf8)
        }
        return nil;
    }
}
