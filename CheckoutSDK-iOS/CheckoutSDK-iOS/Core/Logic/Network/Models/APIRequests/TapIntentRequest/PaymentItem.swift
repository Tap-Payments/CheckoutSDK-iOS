//
//  PaymentItem.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 11/15/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//
/** Represents the model for parsing the a payment item from and to the backend
 {
 "amount": 10,
 "currency": "KWD",
 "description": "test",
 "discount": {
 "type": "P",
 "value": 0
 },
 "image": "",
 "sku":"",
 "name": "test",
 "quantity": 1
 }
 */
@objcMembers public final class PaymentItem:NSObject,Codable {
    /// Represents the amount per unit for this item.
    let amount : Double?
    /// Represents the currency of the item
    let currency : TapCurrencyCode?
    /// Represents the description of the item
    let itemDescription : String?
    /// Represents the discount if any of the item
    let discount : AmountModificator?
    /// Represents the icon of the item
    let image : String?
    /// Represents the sku identifier of the item
    let sku : String?
    /// Represents the title of the item
    let name : String?
    /// Represents the quantity of the item
    let quantity : Double?
    
    enum CodingKeys: String, CodingKey {
        
        case amount = "amount"
        case currency = "currency"
        case itemDescription = "description"
        case discount = "discount"
        case image = "image"
        case sku = "sku"
        case name = "name"
        case quantity = "quantity"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        amount = try values.decodeIfPresent(Double.self, forKey: .amount)
        currency = try values.decodeIfPresent(TapCurrencyCode.self, forKey: .currency)
        itemDescription = try values.decodeIfPresent(String.self, forKey: .itemDescription)
        discount = try values.decodeIfPresent(AmountModificator.self, forKey: .discount)
        image = try values.decodeIfPresent(String.self, forKey: .image)
        sku = try values.decodeIfPresent(String.self, forKey: .sku)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        quantity = try values.decodeIfPresent(Double.self, forKey: .quantity)
    }
}
