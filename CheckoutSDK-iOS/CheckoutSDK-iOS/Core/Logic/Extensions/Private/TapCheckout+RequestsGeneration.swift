//
//  TapCheckoutManager+RequestsGeneration.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/18/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import CommonDataModelsKit_iOS

/// Used to do logic for creating the api requests models
extension TapCheckout {
    
    
    /**
     Creates the config api request
     - Returns:The config api request
     */
    func createConfigRequestModel() -> [String:Any] {
        // the config request will include the merchant id, secret key and the static headers
        let configString = """
{"open":true,"checkoutMode":"page","paymentType":"ALL","supportedPaymentMethods":"ALL","selectedCurrency":"KWD","supportedCurrencies":"ALL","gateway":{"publicKey":"pk_test_Vlk842B1EA7tDN5QbrfGjYzh","merchantId":""},"customer":{"id":"cus_TS01A5720231124Hj132604096","firstName":"Ahmed","lastName":"Sharkawy","email":"example@gmail.com","phone":{"countryCode":"20","number":"1099137773"}},"transaction":{"mode":"charge","charge":{"saveCard":true,"auto":{"type":"VOID","time":100},"redirect":{"url":"\(WebPaymentHandlerConstants.returnURL)"},"threeDSecure":true}},"amount":0.1,"order":{"items":[{"amount":0.1,"currency":"KWD","name":"Item Title 1","quantity":1,"description":"item description 1"}]},"cardOptions":{"showBrands":true,"showLoadingState":false,"collectHolderName":true,"preLoadCardName":"","cardNameEditable":true,"cardFundingSource":"all","saveCardOption":"all","forceLtr":false}}
"""
        if let data = configString.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any] ?? [:]
                return json
            } catch {
                return [:]
            }
        }
        return [:]
    }
    
}
