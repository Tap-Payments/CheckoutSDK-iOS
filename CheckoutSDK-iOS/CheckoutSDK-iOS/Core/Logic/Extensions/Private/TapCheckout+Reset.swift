//
//  TapCheckout+Reset.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/20/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import TapCardVlidatorKit_iOS

/// Logic needed for deinit and resetting values, observerables
internal extension TapCheckout {

    /// Resets all the view models and dispose all the active observers
    class func destroy() {
        if privateShared != nil {
            privateShared?.resetViewModels()
            privateShared?.resetObservables()
        }
        privateShared = nil
    }
    
    /// Resetting all view models to the initial state
    func resetViewModels() {
        dataHolder.viewModels = .init()
        NetworkManager.shared.resetStackTrace()
        
    }
    
    /// Resetting and disposing all previous subscribers to the observables
    func resetObservables() {
        dataHolder.transactionData.transactionCurrencyValue = .init(.undefined, 0, "")
        dataHolder.transactionData.transactionUserCurrencyValue = .init(.undefined, 0, "")
        dataHolder.transactionData.transactionItemsValue = []
        CardValidator.favoriteCardBrand = nil
    }
    
}
