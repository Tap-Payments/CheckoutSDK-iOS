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
    /// Represents the view model that controls the payment gateway chips list view
    var tapGatewayChipHorizontalListViewModel:TapChipHorizontalListViewModel = .init(dataSource: [], headerType: .GateWayListWithGoPayListHeader)
    /// Represents the view model that controls the gopay gateway chips list view
    var tapGoPayChipsHorizontalListViewModel:TapChipHorizontalListViewModel = .init(dataSource: [], headerType: .GoPayListHeader)
    /// Represents the view model that controls the cards/telecom tabs view
    var tapCardPhoneListViewModel:TapCardPhoneBarListViewModel = .init()
    /// Represents the view model that controls the tabbar view
    var tapCardTelecomPaymentViewModel: TapCardTelecomPaymentViewModel = .init()
    /// Represents the view model that controls the chips list of supported currencies view
    var tapCurrienciesChipHorizontalListViewModel:TapChipHorizontalListViewModel = .init()
    /// Represents the view model that controls the country picker when logging in to goPay using the phone number
    var goPayBarViewModel:TapGoPayLoginBarViewModel?
    
    /// Repreents the list fof supported currencies
    var currenciesChipsViewModel:[CurrencyChipViewModel] = []
    /// Repreents the list fof supported currencies
    var goPayLoginCountries:[TapCountry] = []
    /// Represents the data loaded from the Entit api on checkout start
    var entitModelResponse:TapEntitResponseModel?{
        didSet{
            // Now it is time to fetch needed data from the model parsed
            parseEntitResponse()
        }
    }
    
    /// Represents the list of ALL allowed telecom/cards payments for the logged in merchant
    var tapCardPhoneListDataSource:[CurrencyCardsTelecomModel] = []
    /// Represents the list of ALL allowed payment chips for the logged in merchant
    var gatewayChipsViewModel:[CurrencyChipModel] = []
    /// Represents the list of ALL allowed goPay chips for the logged in customer
    var goPayChipsViewModel:[CurrencyChipModel] = []
    /// Represents The Apple pay merchant id to be used inside the apple pay kit
    var applePayMerchantID:String = ""
    
    /// Represents a global accessable common data gathered by the merchant when loading the checkout sdk like amount, currency, etc
    private static var privateShared : TapCheckoutSharedManager?
    
    // MARK:- RxSwift Variables
    /// Represents the original transaction currency stated by the merchant on checkout start
    var transactionCurrencyObserver:BehaviorRelay<TapCurrencyCode> = .init(value: .undefined)
    /// Represents the transaction currency selected by the user
    var transactionUserCurrencyObserver:BehaviorRelay<TapCurrencyCode> = .init(value: .undefined)
    /// Represents the original transaction total amount stated by the merchant on checkout start
    var transactionTotalAmountObserver:BehaviorRelay<Double> = .init(value: 0)
    /// Represents the list of items passed by the merchant on load
    var transactionItemsObserver:BehaviorRelay<[ItemModel]> = .init(value: [])
    // MARK:- Methods
    /**
     Creates a shared instance of the CheckoutDataManager
     - Returns: The shared checkout manager
     */
    internal class func sharedCheckoutManager() -> TapCheckoutSharedManager { // change class to final to prevent override
        guard let uwShared = privateShared else {
            privateShared = TapCheckoutSharedManager()
            return privateShared!
        }
        return uwShared
    }
    
    /// Resets all the view models and dispose all the active observers
    internal class func destroy() {
        privateShared = nil
    }
    
    private init() {
        print("init singleton")
        // Create default view models
        createGatewayDummyChips()
        createDummyCardTelecomModel()
        // Bind the observables
        bindTheObservables()
    }
    
    deinit {
        print("deinit singleton")
    }
    
    /// Resetting all view models to the initial state
    private func resetViewModels() {
        tapMerchantViewModel = .init()
        tapAmountSectionViewModel = .init()
        tapItemsTableViewModel = .init()
    }
    
    /// Resetting and disposing all previous subscribers to the observables
    private func resetObservables() {
        transactionCurrencyObserver = .init(value: .undefined)
        transactionUserCurrencyObserver = .init(value: .undefined)
        transactionTotalAmountObserver = .init(value: 0)
        transactionItemsObserver = .init(value: [])
    }
    
    /// Responsible for wiring up the observables to fire the correct methods upon the correct data changes
    private func bindTheObservables() {
        // Listen to the changes in transaction currency
        transactionCurrencyObserver
        .filter{ $0 != .undefined }
        .share().subscribe(onNext: { [weak self] (newTransactionCurrency) in
            self?.transactionCurrencyUpdated()
        }).disposed(by: disposeBag)
        
        // We only create items list when we have both elements, items and original currency
        transactionItemsObserver.filter{ $0 != [] }.distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.createTapItemsViewModel()
            }).disposed(by: disposeBag)
        
        // The amount section and items list will be changed if total amount or the selected currency is changed one of them or both
        Observable.combineLatest(transactionTotalAmountObserver, transactionUserCurrencyObserver).share()
            .distinctUntilChanged { (arg0, arg1) -> Bool in
                let (lastAmount, lastUserCurrency) = arg0
                let (newAmount, newUserCurrency) = arg1
                return (lastAmount == newAmount) && (lastUserCurrency == newUserCurrency)
            }.filter{ $0 != 0 && $1 != .undefined }
            .subscribe(onNext: { [weak self] (_,_) in
            self?.updateAmountSection()
            self?.updateItemsList()
            self?.updateGatewayChipsList()
            self?.updateCardTelecomList()
            self?.updateApplePayRequest()
        }).disposed(by: disposeBag)
    }
    
    /// Handles the logic needed to create the tap items view model by utilising the original currency and the items list passed by the merchant
    private func createTapItemsViewModel() {
        // Convert the passed items models into the ItemCellViewModels and update the items table view model with the new created list
        let itemsModels:[ItemCellViewModel] = transactionItemsObserver.value.map{ ItemCellViewModel.init(itemModel: $0, originalCurrency:transactionCurrencyObserver.value) }
        tapItemsTableViewModel = .init(dataSource: itemsModels)
        tapAmountSectionViewModel.numberOfItems = transactionItemsObserver.value.count
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
    
    /// Handles all the logic needed when the user selected currency changed to reflect in the items list view
    private func updateItemsList() {
        tapItemsTableViewModel.dataSource.map{ $0 as! ItemCellViewModel }.forEach{ $0.convertCurrency = transactionUserCurrencyObserver.value }
    }
    
    /// Handles all the logic needed when the user selected currency changed to reflect in the supported gateways chips for the new currency
    private func updateGatewayChipsList() {
        tapGatewayChipHorizontalListViewModel.dataSource = gatewayChipsViewModel.filter(for: transactionUserCurrencyObserver.value)
        tapGoPayChipsHorizontalListViewModel.dataSource = goPayChipsViewModel.filter(for: transactionUserCurrencyObserver.value)
    }
    
    /// Handles all the logic needed when the user selected currency changed to reflect in the supported cards/telecom tabbar items for the new currency
    private func updateCardTelecomList() {
        tapCardPhoneListViewModel.dataSource = tapCardPhoneListDataSource.filter(for: transactionUserCurrencyObserver.value)
        tapCardTelecomPaymentViewModel.tapCardPhoneListViewModel = tapCardPhoneListViewModel
        tapCardTelecomPaymentViewModel.changeTapCountry(to: tapCardPhoneListDataSource.telecomCountry(for: transactionUserCurrencyObserver.value))
    }
    
    /// Handles all the logic needed to correctly parse the passed data into a correct Apple Pay request format
    private func updateApplePayRequest() {
        // get the apple pay chip view modl
        let applePayChips = gatewayChipsViewModel.filter{ $0.tapChipViewModel.isKind(of: ApplePayChipViewCellModel.self) }
        guard applePayChips.count > 0, let applePayChipViewModel:ApplePayChipViewCellModel = applePayChips[0].tapChipViewModel as? ApplePayChipViewCellModel else { // meaning no apple pay chip is there
            return }
        
        applePayChipViewModel.configureApplePayRequest(currencyCode: transactionUserCurrencyObserver.value,paymentItems: transactionItemsObserver.value.toApplePayItems(convertFromCurrency: transactionCurrencyObserver.value, convertToCurrenct: transactionUserCurrencyObserver.value), amount: transactionUserCurrencyObserver.value.convert(from: transactionCurrencyObserver.value, for: transactionTotalAmountObserver.value), merchantID: applePayMerchantID)
        
    }
    
    
    /// Handles the logic to fetch different sections from the Entit API response
    private func parseEntitResponse() {
        
        guard let entitModel = entitModelResponse else { return }
        
        // Fetch the merchant header info
        if let merchantModel:MerchantModel = entitModel.merchant {
            self.tapMerchantViewModel = .init(title: nil, subTitle: merchantModel.name, iconURL: merchantModel.logo)
            
        }
        
        // Fetch the list of supported currencies
        self.currenciesChipsViewModel = entitModel.currencies.map{ CurrencyChipViewModel.init(currency: $0) }
        self.tapCurrienciesChipHorizontalListViewModel = .init(dataSource: currenciesChipsViewModel, headerType: .NoHeader,selectedChip: currenciesChipsViewModel.filter{ $0.currency == transactionUserCurrencyObserver.value }[0])
        
        // Fetch the list of the goPay supported login countries
        self.goPayLoginCountries = entitModel.goPayLoginCountries ?? []
        self.goPayBarViewModel = .init(countries: goPayLoginCountries)
    }
}


// MARK:- extension that includes all methods that will create dummy data, until it is loaded from API calls
extension TapCheckoutSharedManager {
    
    /// Creates a dummy data for the chips and saved card chips
    private func createGatewayDummyChips() {
        let applePayChipViewModel:ApplePayChipViewCellModel = ApplePayChipViewCellModel.init()
        applePayChipViewModel.configureApplePayRequest()
        gatewayChipsViewModel.append(.init(tapChipViewModel: applePayChipViewModel, supportedCurrencies: [.AED,.USD,.SAR]))
        
        gatewayChipsViewModel.append(.init(tapChipViewModel: TapGoPayViewModel.init(title: "GoPay Clicked")))
        
        gatewayChipsViewModel.append(.init(tapChipViewModel: GatewayChipViewModel.init(title: "KNET", icon: "https://meetanshi.com/media/catalog/product/cache/1/image/925f46717e92fbc24a8e2d03b22927e1/m/a/magento-knet-payment-354x.png") , supportedCurrencies: [.KWD]))
        gatewayChipsViewModel.append(.init(tapChipViewModel: GatewayChipViewModel.init(title: "KNET", icon: "https://meetanshi.com/media/catalog/product/cache/1/image/925f46717e92fbc24a8e2d03b22927e1/m/a/magento-knet-payment-354x.png") , supportedCurrencies: [.KWD]))
        
        gatewayChipsViewModel.append(.init(tapChipViewModel: GatewayChipViewModel.init(title: "BENEFIT", icon: "https://media-exp1.licdn.com/dms/image/C510BAQG0Pwkl3gsm2w/company-logo_200_200/0?e=2159024400&v=beta&t=ragD_Mg4TUCAiVGiYOmjT2orY1IKEOOe_JEokwkzvaY") , supportedCurrencies: [.BHD]))
        gatewayChipsViewModel.append(.init(tapChipViewModel: GatewayChipViewModel.init(title: "BENEFIT", icon: "https://media-exp1.licdn.com/dms/image/C510BAQG0Pwkl3gsm2w/company-logo_200_200/0?e=2159024400&v=beta&t=ragD_Mg4TUCAiVGiYOmjT2orY1IKEOOe_JEokwkzvaY") , supportedCurrencies: [.BHD]))
        
        gatewayChipsViewModel.append(.init(tapChipViewModel: GatewayChipViewModel.init(title: "FAWRY", icon: "https://pwstg02.blob.core.windows.net/pwfiles/ContentFiles/8468Image.jpg") , supportedCurrencies: [.EGP]))
        gatewayChipsViewModel.append(.init(tapChipViewModel: GatewayChipViewModel.init(title: "FAWRY", icon: "https://pwstg02.blob.core.windows.net/pwfiles/ContentFiles/8468Image.jpg") , supportedCurrencies: [.EGP]))
        
        gatewayChipsViewModel.append(.init(tapChipViewModel: GatewayChipViewModel.init(title: "SADAD", icon: "https://www.payfort.com/wp-content/uploads/2017/09/go_glocal_mada_logo_en.png") , supportedCurrencies: [.SAR]))
        gatewayChipsViewModel.append(.init(tapChipViewModel: GatewayChipViewModel.init(title: "SADAD", icon: "https://www.payfort.com/wp-content/uploads/2017/09/go_glocal_mada_logo_en.png") , supportedCurrencies: [.SAR]))
        
        gatewayChipsViewModel.append(.init(tapChipViewModel:SavedCardCollectionViewCellModel.init(title: "•••• 1234", icon:"https://img.icons8.com/color/2x/amex.png")))
        gatewayChipsViewModel.append(.init(tapChipViewModel:SavedCardCollectionViewCellModel.init(title: "•••• 5678", icon:"https://img.icons8.com/color/2x/visa.png")))
        gatewayChipsViewModel.append(.init(tapChipViewModel:SavedCardCollectionViewCellModel.init(title: "•••• 9012", icon:"https://img.icons8.com/color/2x/mastercard-logo.png")))
        
        goPayChipsViewModel.append(.init(tapChipViewModel:SavedCardCollectionViewCellModel.init(title: "•••• 3333", icon:"https://img.icons8.com/color/2x/amex.png", listSource: .GoPayListHeader)))
        goPayChipsViewModel.append(.init(tapChipViewModel:SavedCardCollectionViewCellModel.init(title: "•••• 4444", icon:"https://img.icons8.com/color/2x/visa.png", listSource: .GoPayListHeader)))
        goPayChipsViewModel.append(.init(tapChipViewModel:SavedCardCollectionViewCellModel.init(title: "•••• 5555", icon:"https://img.icons8.com/color/2x/mastercard-logo.png", listSource: .GoPayListHeader)))
        goPayChipsViewModel.append(.init(tapChipViewModel:TapLogoutChipViewModel()))
    }
    
    private func createDummyCardTelecomModel() {
        let Kuwait:TapCountry = .init(nameAR: "الكويت", nameEN: "Kuwait", code: "965", phoneLength: 8)
        let Egypt:TapCountry = .init(nameAR: "مصر", nameEN: "Egypt", code: "20", phoneLength: 9)
        
        tapCardPhoneListDataSource.append(.init(tapCardPhoneViewModel: .init(associatedCardBrand: .visa, tapCardPhoneIconUrl: "https://img.icons8.com/color/2x/visa.png")))
        tapCardPhoneListDataSource.append(.init(tapCardPhoneViewModel: .init(associatedCardBrand: .masterCard, tapCardPhoneIconUrl: "https://img.icons8.com/color/2x/mastercard.png")))
        tapCardPhoneListDataSource.append(.init(tapCardPhoneViewModel: .init(associatedCardBrand: .americanExpress, tapCardPhoneIconUrl: "https://img.icons8.com/color/2x/amex.png")))
        tapCardPhoneListDataSource.append(.init(tapCardPhoneViewModel: .init(associatedCardBrand: .mada, tapCardPhoneIconUrl: "https://i.ibb.co/S3VhxmR/796px-Mada-Logo-svg.png"),supportedCurrencies: [.SAR]))
        
        tapCardPhoneListDataSource.append(.init(tapCardPhoneViewModel: .init(associatedCardBrand: .viva, tapCardPhoneIconUrl: "https://i.ibb.co/cw5y89V/unnamed.png"),supportedCurrencies: [.KWD],supportedTelecomCountry: Kuwait))
        tapCardPhoneListDataSource.append(.init(tapCardPhoneViewModel: .init(associatedCardBrand: .wataniya, tapCardPhoneIconUrl: "https://i.ibb.co/PCYd8Xm/ooredoo-3x.png"),supportedCurrencies: [.KWD],supportedTelecomCountry: Kuwait))
        tapCardPhoneListDataSource.append(.init(tapCardPhoneViewModel: .init(associatedCardBrand: .zain, tapCardPhoneIconUrl: "https://i.ibb.co/mvkJXwF/zain-3x.png"),supportedCurrencies: [.KWD],supportedTelecomCountry: Kuwait))
        
        
        tapCardPhoneListDataSource.append(.init(tapCardPhoneViewModel: .init(associatedCardBrand: .orange, tapCardPhoneIconUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/Orange_logo.svg/2560px-Orange_logo.svg.png"),supportedCurrencies: [.EGP],supportedTelecomCountry: Egypt))
        tapCardPhoneListDataSource.append(.init(tapCardPhoneViewModel: .init(associatedCardBrand: .vodafone, tapCardPhoneIconUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Vodafone_icon.svg/1020px-Vodafone_icon.svg.png"),supportedCurrencies: [.EGP],supportedTelecomCountry: Egypt))
        tapCardPhoneListDataSource.append(.init(tapCardPhoneViewModel: .init(associatedCardBrand: .etisalat, tapCardPhoneIconUrl: "https://i.ibb.co/K28R093/1280px-Etisalat-Logo.png"),supportedCurrencies: [.EGP],supportedTelecomCountry: Egypt))
        
        
        tapCardTelecomPaymentViewModel = .init(with: tapCardPhoneListViewModel, and: .init(nameAR: "الكويت", nameEN: "Kuwait", code: "965", phoneLength: 8))
    }
}
