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
    func createConfigRequestModel() -> TapConfigRequestModel {
        // the config request will include the merchant id, secret key and the static headers
        return TapConfigRequestModel(gateway: .init(config: .init(application: NetworkManager.applicationHeaderValue), merchantId: "", publicKey: NetworkManager.secretKey()))
    }
    
}
