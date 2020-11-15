//
//  TapCustomer.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 11/15/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
/** Represents the model for parsing the a customer object coming from Tap backend
 {
 "customer": {
 "id": "cus_xxxxxxxx",
 "first_name": "haitham",
 "middle_name": "mohammad",
 "last_name": "elsheshtawy",
 "email": "haitham@test.com",
 "phone": {
 "country_code": "965",
 "number": "00000000"
 },
 "description": "test",
 "metadata": {
 "udf1": "test"
 },
 "nationality": "KW",
 "currency": "KWD"
 }
 }
 */
struct TapCustomer : Codable {
    /// Represents the tap's customer id
    let id : String?
    /// Represents the customer's first name
    let first_name : String?
    /// Represents the customer's middle name
    let middle_name : String?
    /// Represents the ustomer's last name
    let last_name : String?
    /// Represents the customer's email
    let email : String?
    /// Represents the customer's phone
    let phone : TapPhone?
    /// Represents the customer's descriptioin as stored before by the merchant
    let description : String?
    /// Represents the customer's meta data, which is a value to be used bu the merchant to detect any additional info passed by him for this customer to map it to his own database
    let metadata : TapCustomerMetaData?
    /// Represents the customer's nationality country code, using the format ISO 2 letter coded. [Country Alpha 2 Code list]: https://www.iban.com/country-codes
    let nationality : String?
    /// Represents the customer's preferred currency
    let currency : TapCurrencyCode?
    
    enum CodingKeys: String, CodingKey {
        
        case id = "id"
        case first_name = "first_name"
        case middle_name = "middle_name"
        case last_name = "last_name"
        case email = "email"
        case phone = "phone"
        case description = "description"
        case metadata = "metadata"
        case nationality = "nationality"
        case currency = "currency"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(String.self, forKey: .id)
        first_name = try values.decodeIfPresent(String.self, forKey: .first_name)
        middle_name = try values.decodeIfPresent(String.self, forKey: .middle_name)
        last_name = try values.decodeIfPresent(String.self, forKey: .last_name)
        email = try values.decodeIfPresent(String.self, forKey: .email)
        phone = try values.decodeIfPresent(TapPhone.self, forKey: .phone)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        metadata = try values.decodeIfPresent(TapCustomerMetaData.self, forKey: .metadata)
        nationality = try values.decodeIfPresent(String.self, forKey: .nationality)
        currency = TapCurrencyCode.init(appleRawValue: try values.decodeIfPresent(String.self, forKey: .currency) ?? "")
    }
    
}
