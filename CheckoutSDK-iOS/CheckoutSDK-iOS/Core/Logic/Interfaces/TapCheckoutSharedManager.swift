//
//  TapCheckout+SheetDataSource.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/16/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

/// Represents a global accessable common data gathered by the merchant when loading the checkout sdk like amount, currency, etc
internal class TapCheckoutSharedManager {
    
    // MARK:- Normal Swift Variables
    let disposeBag:DisposeBag = .init()
    
    /// Represents a global accessable common data gathered by the merchant when loading the checkout sdk like amount, currency, etc
    static let sharedCheckoutManager = TapCheckoutSharedManager()
    
    // MARK:- RxSwift Variables
    /// Represents the original transaction currency stated by the merchant on checkout start
    let transactionCurrencyObserver:BehaviorRelay<TapCurrencyCode> = .init(value: .KWD)
    /// Represents the transaction currency selected by the user
    let userSelectedCurrencyObserver:BehaviorRelay<TapCurrencyCode> = .init(value: .KWD)
    
    // MARK:- Methods
    
    init() {
        // Bind the observables
        transactionCurrencyObserver.share().subscribe(onNext: { [weak self] (newTransactionCurrency) in
            self?.transactionCurrencyUpdated()
        }).disposed(by: disposeBag)
    }
    
    /// Handles all the logic needed when the original transaction currency changed
    private func transactionCurrencyUpdated() {
        // Change in the original transaction currency, means this is the basic configuration called from the merchanr on load, so we initialy set it to be the same as the selected user currency
        userSelectedCurrencyObserver.accept(transactionCurrencyObserver.value)
    }
}
