/* 
Copyright (c) 2020 Swift Models Generated from JSON powered by http://www.json4swift.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar

*/

import Foundation
/// Represents the model to parse the Intent API response
internal struct TapIntentResponseModel : Codable {
    /// Represents the merchant header info section
	let merchant : MerchantModel?
    
    /// Represents the saved cards for the logged in customer with goPay
    let goPaySavedCards:[ChipWithCurrencyModel]?
    /// Represents all available payment chips including Apple pay + redirection + saved cards for the logged in customer
    let paymentChips:[ChipWithCurrencyModel]?
    
    /// Represents the supported currencies for the logged in merchant
    var currencies: [TapCurrencyCode] = []
    /// Represents the supported countries to login to goPay with phone
    let goPayLoginCountries: [TapCountry]?

	enum CodingKeys: String, CodingKey {
		case merchant = "merchant"
        case currencies = "currencies"
        case goPayLoginCountries = "goPayCountries"
        case goPaySavedCards = "goPaySavedCards"
        case paymentChips = "savedCards"
	}

	init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		merchant = try values.decodeIfPresent(MerchantModel.self, forKey: .merchant)
        currencies = try values.decodeIfPresent([TapCurrencyCode].self, forKey: .currencies) ?? []
        goPayLoginCountries = try values.decodeIfPresent([TapCountry].self, forKey: .goPayLoginCountries)
        goPaySavedCards = try values.decodeIfPresent([ChipWithCurrencyModel].self, forKey: .goPaySavedCards)
        paymentChips = try values.decodeIfPresent([ChipWithCurrencyModel].self, forKey: .paymentChips)
	}

}

/// Extension to provide all the helper methods in decoding the raw data into the corresponsind models/viewmodels
extension TapIntentResponseModel {
    
    /**
     Helper method that converts a list of strings into the corresponding Tap Currency code enum
     - Parameter stringCodes: The list of raw string currency code in ISO format e.g AED, KWD, EGP, USD, etcl.
     */
    private func decodeCurrencyList(with stringCodes:[String]) -> [TapCurrencyCode] {
        // Convert the passed strings into enums and filter out any wrong passed code
        return stringCodes.map{ (TapCurrencyCode.init(appleRawValue: $0) ?? TapCurrencyCode.undefined)}.filter{ $0 != .undefined}
    }
    
}


/// Making Tap Currency Code codable direct from json data
extension TapCurrencyCode:Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = TapCurrencyCode.init(appleRawValue: rawValue) ??  TapCurrencyCode.undefined
    }
}
