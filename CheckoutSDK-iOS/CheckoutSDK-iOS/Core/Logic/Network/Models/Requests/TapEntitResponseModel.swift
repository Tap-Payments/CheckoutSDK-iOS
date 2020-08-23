/* 
Copyright (c) 2020 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

*/

import Foundation
/// Represents the model to parse the Entit API response
internal struct TapEntitResponseModel : Codable {
    /// Represents the merchant header info section
	let merchant : MerchantModel?
    /// Represents the string raw values parsed from the response about the currency codes
    private let stringCurrencies:[String]?
    /// Represents the supported currencies for the logged in merchant
    var currencies: [TapCurrencyCode] {
        return decodeCurrencyList(with: stringCurrencies ?? [])
    }
    /// Represents the supported countries to login to goPay with phone
    let goPayLoginCountries: [TapCountry]?

	enum CodingKeys: String, CodingKey {
		case merchant = "merchant"
        case stringCurrencies = "currencies"
        case goPayLoginCountries = "countries"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		merchant = try values.decodeIfPresent(MerchantModel.self, forKey: .merchant)
        stringCurrencies = try values.decodeIfPresent([String].self, forKey: .stringCurrencies)
        goPayLoginCountries = try values.decodeIfPresent([TapCountry].self, forKey: .goPayLoginCountries)
	}

}

/// Extension to provide all the helper methods in decoding the raw data into the corresponsind models/viewmodels
extension TapEntitResponseModel {
    
    /**
     Helper method that converts a list of strings into the corresponding Tap Currency code enum
     - Parameter stringCodes: The list of raw string currency code in ISO format e.g AED, KWD, EGP, USD, etcl.
     */
    private func decodeCurrencyList(with stringCodes:[String]) -> [TapCurrencyCode] {
        // Convert the passed strings into enums and filter out any wrong passed code
        return stringCodes.map{ (TapCurrencyCode.init(appleRawValue: $0) ?? TapCurrencyCode.undefined)}.filter{ $0 != .undefined}
    }
    
}
