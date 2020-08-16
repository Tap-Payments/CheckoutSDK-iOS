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
    /// Rerpesents the view model that controls the Merchant header section view
    var tapMerchantViewModel:TapMerchantHeaderViewModel = .init()
    /// Rerpesents the view model that controls the Amount section view
    var tapAmountSectionViewModel:TapAmountSectionViewModel = .init()
    /// Rerpesents the view model that controls the items list view
    var tapItemsTableViewModel:TapGenericTableViewModel = .init()
    
    /// Represents a global accessable common data gathered by the merchant when loading the checkout sdk like amount, currency, etc
    static var sharedCheckoutManager = TapCheckoutSharedManager()
    
    // MARK:- RxSwift Variables
    /// Represents the original transaction currency stated by the merchant on checkout start
    let transactionCurrencyObserver:BehaviorRelay<TapCurrencyCode> = .init(value: .USD)
    /// Represents the transaction currency selected by the user
    let transactionUserCurrencyObserver:BehaviorRelay<TapCurrencyCode> = .init(value: .USD)
    /// Represents the original transaction total amount stated by the merchant on checkout start
    let transactionTotalAmountObserver:BehaviorRelay<Double> = .init(value: 0)
    /// Represents the list of items passed by the merchant on load
    let transactionItemsObserver:BehaviorRelay<[ItemModel]> = .init(value: [])
    // MARK:- Methods
    
    init() {
        // Create default view models
        createTapMerchantHeaderViewModel()
        // Bind the observables
        bindTheObservables()
        
    }
    
    /// Responsible for wiring up the observables to fire the correct methods upon the correct data changes
    private func bindTheObservables() {
        // Listen to the changes in transaction currency
        transactionCurrencyObserver.share().subscribe(onNext: { [weak self] (newTransactionCurrency) in
            self?.transactionCurrencyUpdated()
        }).disposed(by: disposeBag)
        
        // We only create items list when we have both elements, items and original currency
        Observable.zip(transactionTotalAmountObserver, transactionItemsObserver)
            .subscribe(onNext: { [weak self] (currency, items) in
                self?.createTapItemsViewModel()
            }).disposed(by: disposeBag)
        
        // The amount section and items list will be changed if total amount or the selected currency is changed one of them or both
        Observable.combineLatest(transactionTotalAmountObserver, transactionUserCurrencyObserver)
            .share().distinctUntilChanged { (arg0, arg1) -> Bool in
                let (lastAmount, lastUserCurrency) = arg0
                let (newAmount, newUserCurrency) = arg1
                return (lastAmount == newAmount) && (lastUserCurrency == newUserCurrency)
        }.subscribe(onNext: { [weak self] (_,_) in
            self?.updateAmountSection()
            self?.updateItemsList()
        }).disposed(by: disposeBag)
    }
    
    /// Handles the logic needed to create the tap items view model by utilising the original currency and the items list passed by the merchant
    private func createTapItemsViewModel() {
        // Convert the passed items models into the ItemCellViewModels and update the items table view model with the new created list
        let itemsModels:[ItemCellViewModel] = transactionItemsObserver.value.map{ ItemCellViewModel.init(itemModel: $0, originalCurrency:transactionCurrencyObserver.value) }
        tapItemsTableViewModel = .init(dataSource: itemsModels)
        tapAmountSectionViewModel.numberOfItems = transactionItemsObserver.value.count
    }
    
    /// Handles all the logic needed to create and set the data in the merchant header section
    private func createTapMerchantHeaderViewModel() {
        tapMerchantViewModel = .init(subTitle: "Tap Payments", iconURL: "https://avatars3.githubusercontent.com/u/19837565?s=200&v=4")
    }
    
    /// Handles all the logic needed to create and set the data in the merchant header section
    private func createTapAmountHeaderViewModel() {
        tapMerchantViewModel = .init(subTitle: "Tap Payments", iconURL: "https://avatars3.githubusercontent.com/u/19837565?s=200&v=4")
    }
    
    /// Handles all the logic needed when the original transaction currency changed
    private func transactionCurrencyUpdated() {
        // Change in the original transaction currency, means this is the basic configuration called from the merchanr on load, so we initialy set it to be the same as the selected user currency
        transactionUserCurrencyObserver.accept(transactionCurrencyObserver.value)
        
        // Apply the change into the Amount view model
        tapAmountSectionViewModel.originalTransactionCurrency = transactionCurrencyObserver.value
    }
    
    /// Handles all the logic needed when the amount or the user selected currency changed to reflect in the Amount Section View
    private func updateAmountSection() {
        // Apply the changes of user currency and total amount into the Amount view model
        tapAmountSectionViewModel.convertedTransactionCurrency = transactionUserCurrencyObserver.value
        tapAmountSectionViewModel.originalTransactionAmount = transactionTotalAmountObserver.value
    }
    
    
    private func updateItemsList() {
        tapItemsTableViewModel.dataSource.map{ $0 as! ItemCellViewModel }.forEach{ $0.convertCurrency = transactionUserCurrencyObserver.value }
    }
}
