//
//  TapCheckout+UIHandling.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/20/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import TapUIKit_iOS
import CommonDataModelsKit_iOS
import TapCardVlidatorKit_iOS
import PassKit
import TapApplePayKit_iOS
import CoreTelephony
import LocalisationManagerKit_iOS
import Nuke
import TapThemeManager2020
/// Extension to handle logic to update ui view models based on data changes
internal extension TapCheckout {
    /// Handles the logic required to update all required fields and variables upon a change in the current shared data manager state
    func updateManager() {
        updateAmountSection()
        //updateLoyaltySection()
        updateItemsList()
        updateApplePayRequest()
        // check if we need to sort the options or not based on coming from changing currency in widget or from currencies list
        let shouldSortOptions:Bool = !currencyConvertedFromWidget
        updateGatewayChipsList(shouldSort: shouldSortOptions)
        updateCardTelecomIconList(shouldSort: shouldSortOptions)
        updateActionButtonTitle()
    }
    /// Updates the textual title of the action button upon changing the currency.
    /// This will only take effect if the mode is purchase or authorize
    func updateActionButtonTitle() {
        var customAppendedTitle:String = ""
        
        // Only if we are charging or authorizing we need to display ythe currency and the amount
        // For non amount based modes like save or tokenize these values are not needed
        if dataHolder.transactionData.transactionMode == .purchase || dataHolder.transactionData.transactionMode == .authorizeCapture {
            // It is confirmed to be only Pay now without adding the currency & the amount
            customAppendedTitle = TapLocalisationManager.shared.localisedValue(for: "ActionButton.now")
            /*// We need to add the following to the title {CurrencySymbol Amount}
            customAppendedTitle = dataHolder.viewModels.tapAmountSectionViewModel.convertedTransactionCurrency.currency != .undefined ? dataHolder.viewModels.tapAmountSectionViewModel.convertedTransactionAmountFormated : dataHolder.viewModels.tapAmountSectionViewModel.originalTransactionAmountFormated //"\(dataHolder.transactionData.transactionUserCurrencyValue.displaybaleSymbol) \(dataHolder.transactionData.transactionUserCurrencyValue.amount)"*/
            print(customAppendedTitle)
        }
        
        
        dataHolder.viewModels.tapActionButtonViewModel.appendCustomTitle = customAppendedTitle
    }
    
    /// Handles all the logic needed when the amount or the user selected currency changed to reflect in the Amount Section View
    func updateAmountSection() {
        // Apply the changes of user currency and total amount into the Amount view model
        dataHolder.viewModels.tapAmountSectionViewModel.convertedTransactionCurrency = dataHolder.transactionData.transactionUserCurrencyValue
        dataHolder.viewModels.tapAmountSectionViewModel.originalTransactionCurrency  = dataHolder.transactionData.transactionCurrencyValue
        dataHolder.viewModels.tapAmountSectionViewModel.configureItemsLabel()
    }
    
    /// Handles all the logic needed when the amount or the user selected currency changed to reflect in the Loyalty section view
    /*func updateLoyaltySection() {
        // Make sure we have a loyalty view model and it does support the new selected currency first
        guard let nonNullViewModel = dataHolder.viewModels.tapLoyaltyViewModel,
              let supportedLoyaltyCurrencies:[TapCurrencyCode] = nonNullViewModel.loyaltyModel?.supportedCurrencies?.map({ $0.currency?.currency ?? .undefined }),
              supportedLoyaltyCurrencies.contains(dataHolder.viewModels.currentUsedCurrency) else {
            return
        }
        
        // Now it is there, let us update the view model
        nonNullViewModel.change(currency: dataHolder.viewModels.currentUsedCurrency,transactionAmount: dataHolder.transactionData.transactionUserCurrencyValue.amount)
        nonNullViewModel.refreshData()
    }*/
    
    /// Handles all the logic needed when the user selected currency changed to reflect in the items list view
    func updateItemsList() {
        dataHolder.viewModels.tapItemsTableViewModel.dataSource.map{ $0 as! ItemCellViewModel }.forEach{ $0.convertCurrency = dataHolder.transactionData.transactionUserCurrencyValue }
    }
    
    /// This will be used to change the default title of the item we create as a default when the user doesn't pass any items. please check Please check [DefaultItemsCreation](x-source-tag://DefaultItemsCreation)
    func updateDefaultItemTitle() {
        // First check if the current case is the default items creation
        guard let initResponse = dataHolder.transactionData.intitModelResponse,
              let merchantName = initResponse.data.merchant?.name,
              dataHolder.transactionData.transactionItemsValue.count == 1,
              dataHolder.transactionData.transactionItemsValue.first?.title == TapCheckout.defaulItemTitle else { /*Nothing to do*/ return }
        
        // Set the correct title now
        TapCheckout.defaulItemTitle = "PAY TO \(merchantName)"
        dataHolder.transactionData.transactionItemsValue.first?.title       = TapCheckout.defaulItemTitle
        dataHolder.transactionData.transactionItemsValue.first?.totalAmount = dataHolder.transactionData.transactionCurrencyValue.amount
    }
    
    /// Fetch local currency prompt needed data
    func updateDefaultCurrenyPromptData() {
        let (shouldShow, tapCurrency, amountedCurrency) = shouldShowLocalPrompt()
        
        guard shouldShow,
              let nonNullCurrencyCode = tapCurrency,
              let nonNullAmountedCurrency = amountedCurrency else { return }
            
        // Tell the view model to update the currency prompt with the correct local currency values
        dataHolder.viewModels.tapAmountSectionViewModel.configureCurrencyPrompt(with: nonNullCurrencyCode.appleRawValue, and: nonNullAmountedCurrency.correctBackEndImageURL(showMonoForLightMode: TapThemeManager.showMonoForLightMode, showColoredForDarkMode: TapThemeManager.showColoredForDarkMode))
        
    }
    
    /// Decides whether or not we should show the local currency prompt
    func shouldShowLocalPrompt() -> (Bool,TapCurrencyCode?,AmountedCurrency?) {
        // Make sure we have valid detected country and detected currency code
        let tapCurrency:TapCurrencyCode = detectSimCurrencyCode()
        guard tapCurrency != .undefined else { return (false,nil,nil) }
        
        // Make sure detected local currency is one of the supported currencies & it is not the transaction currency itself
        guard dataHolder.transactionData.paymentOptionsModelResponse?.currency != tapCurrency,
              dataHolder.transactionData.transactionUserCurrencyValue.currency != tapCurrency,
              let amountedCurrency = dataHolder.transactionData.paymentOptionsModelResponse?.supportedCurrenciesAmounts.first(where: { $0.currency == tapCurrency }) else { return (false,nil,nil) }
        
        // Make sure detected local currency has at least 1 supported payment method, shouldn't come as supported currency from backend if not but defensive coding won't harm
        guard let _ = dataHolder.transactionData.paymentOptionsModelResponse?.paymentOptions.first(where: { $0.supportedCurrencies.contains(tapCurrency) }) else { return (false,nil,nil) }
        
        return (true, tapCurrency, amountedCurrency)
    }
    
    /// Handles if goPay should be shown if the user is logged in, determine the header of the both gateways cards and goPay cards based on the visibility ot the goPay cards
    func updateGoPayAndGatewayLists() {
        // Check if the user is logged in before or not
        dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.shouldShow = dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.shouldShow && dataHolder.transactionData.loggedInToGoPay
        // Adjust the header of the tapGatewayChipList
        dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.headerType = .GatewayListHeader //dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.shouldShow ? .GateWayListWithGoPayListHeader : .GatewayListHeader
        // Decide if we need to show the edit button, only will be visible when there is at least one saved card
        dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.shouldShowRightButton(show: true)
    }
    
    /// Handles all the logic needed when the user selected currency changed to reflect in the supported cards/telecom tabbar items for the new currency
    func updateCardTelecomList() {
        // Instruct if we have to collect the card name or not
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.collectCardName = dataHolder.viewModels.collectCreditCardName
        // Decides whether or not, the card name field will be editable
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.editCardName = dataHolder.viewModels.creditCardNameEditable
        // Decides whether or not, the card name field should be prefilled
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.preloadCardHolderName = dataHolder.viewModels.creditCardNamePreload
        // Defines if the card info textfields should support RTL in Arabic mode or not
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.shouldFlip = dataHolder.viewModels.shouldFlipCardInfo
        // Defines if the card should theme itself
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.shouldThemeSelf = dataHolder.viewModels.cardShouldThemeItself
        // Decides whether or not, there is other payment methods allowed other than the card form or not
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.cardHeaderType = (dataHolder.viewModels.gatewayChipsViewModel.count > 0 || dataHolder.viewModels.gatewayChipsViewModel.count > 0) ? .CardInputTitleOR : .CardInputTitle
        // Instruct if we have to show save card option or not
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.saveCardType = dataHolder.viewModels.isSaveCardAllowed()
        
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.tapCardPhoneListViewModel = dataHolder.viewModels.tapCardPhoneListViewModel
        // Change the telecom part country to the country of the selected currency
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.changeTapCountry(to: dataHolder.viewModels.tapCardPhoneListDataSource.telecomCountry(for: dataHolder.transactionData.transactionUserCurrencyValue.currency))
        dataHolder.viewModels.updateCardTelecomListEnableStatus()
    }
    
    /// Handles all the logic needed to correctly parse the passed data into a correct Apple Pay request format
    func updateApplePayRequest() {
        // get the apple pay chip view model
        let applePayChips = dataHolder.viewModels.gatewayChipsViewModel.filter{ $0.tapChipViewModel.isKind(of: ApplePayChipViewCellModel.self) }
        // Make sure there is an apple pay payment option from the payment types api
        guard applePayChips.count > 0,
              let applePayChipViewModel:ApplePayChipViewCellModel = applePayChips[0].tapChipViewModel as? ApplePayChipViewCellModel,
              let applePaymentOption:PaymentOption = fetchPaymentOption(with: applePayChipViewModel.paymentOptionIdentifier) else { // meaning no apple pay chip is there
            return }
        
        
        // This means, we have apple pay! let us configyre the apple pay request to reflect the current transaction data like items, user currency, allowed payment networks etc.
        // Decide the style of the apple pay button, whether we need to show as setup or the normal pay with apple button
        let applePayButtonType:TapApplePayButtonType = (PKPaymentAuthorizationController.canMakePayments() && PKPaymentAuthorizationController.canMakePayments(usingNetworks: applePaymentOption.applePayNetworkMapper())) ? dataHolder.transactionData.applePayButtonType : .SetupApplePay
        
        let applePayButtonStyle: TapApplePayButtonStyleOutline = dataHolder.transactionData.applePayButtonStyle == .Auto ?
        self.bottomSheetController.traitCollection.userInterfaceStyle == .dark ? .Black : .White : dataHolder.transactionData.applePayButtonStyle
        
        let applePayItems:[PKPaymentSummaryItem] = generateApplePaymentItems()
        TapApplePay.intitModelResponse = TapCheckout.sharedCheckoutManager().dataHolder.transactionData.intitModelResponse
        
        applePayChipViewModel.configureApplePayRequest(currencyCode: dataHolder.transactionData.transactionUserCurrencyValue.currency,
                                                       paymentNetworks: applePaymentOption.applePayNetworkMapper().map{ $0.rawValue },
                                                       applePayButtonType: applePayButtonType,
                                                       applePayButtonStyle: applePayButtonStyle,
                                                       paymentItems: applePayItems,
                                                       amount: dataHolder.transactionData.transactionUserCurrencyValue.amount,
                                                       merchantID: dataHolder.transactionData.applePayMerchantID,
                                                       recurringPaymentRequest: dataHolder.transactionData.recurringPaymentRequest)
        
    }
    
    /// Converts Tap items, shipping and Taxs to displayable apple pay items
    func generateApplePaymentItems() -> [PKPaymentSummaryItem] {
        // convert the payment items
        var items:[PKPaymentSummaryItem] = dataHolder.transactionData.transactionItemsValue.toApplePayItems(convertFromCurrency: dataHolder.transactionData.transactionCurrencyValue, convertToCurrenct: dataHolder.transactionData.transactionUserCurrencyValue)
        // convert any shipping items if any
        items.append(contentsOf: dataHolder.transactionData.shipping?.toApplePayShipping() ?? [])
        // convert any tax items if any
        //items.append(contentsOf: dataHolder.transactionData.taxes.toApplePayTaxes(convertFromCurrency: dataHolder.transactionData.transactionCurrencyValue, convertToCurrenct: dataHolder.transactionData.transactionUserCurrencyValue))
        return items
    }
    
    
    /// Call it whenever needed to hide the local currency prompt for good
    func hideLocalCurrency() {
        dataHolder.viewModels.tapAmountSectionViewModel.removeCurrencyPrompt()
    }
    
    /// We need to highlight the default currency of the user didn't select a new currency other than the default currency
    func highlightDefaultCurrency() {
        
        DispatchQueue.main.async { [weak self] in
            // Get the index of the selected currency. Which will be the currency set by the merchant or the last selected currency by the user
            let selectedIndex:Int = self?.dataHolder.viewModels.tapCurrienciesChipHorizontalListViewModel.dataSource.map({ (genericTapChipViewModel) -> AmountedCurrency in
                guard let currencyChipModel:CurrencyChipViewModel = genericTapChipViewModel as? CurrencyChipViewModel else { return .init(.KWD, 0, "") }
                return currencyChipModel.currency
            }).firstIndex(of: self!.dataHolder.transactionData.transactionUserCurrencyValue) ?? 0
            
            // Inform the currencies data holder to activate the currency at the selected index
            self?.dataHolder.viewModels.tapCurrienciesChipHorizontalListViewModel.didSelectItem(at: selectedIndex,selectCell: true)
        }
    }
}


extension TapCheckout:TapCheckoutDataHolderDelegate {
    
    func updateCardTelecomIconList(shouldSort:Bool = true) {
        if shouldSort && !currencyConvertedFromWidget {
            // let us get the two lists. 1 for enabled and 1 for disabled sorted then we append them together
            let enabledPaymentOptions = dataHolder.viewModels.tapCardPhoneListDataSource.filter(for: dataHolder.transactionData.transactionUserCurrencyValue.currency)
            let disabledPaymentOptions = dataHolder.viewModels.tapCardPhoneListDataSource.filter(for: dataHolder.transactionData.transactionUserCurrencyValue.currency, and: false)
            // Let us add them
            dataHolder.viewModels.tapCardPhoneListViewModel.dataSource = enabledPaymentOptions + disabledPaymentOptions
            updateCardTelecomList()
        }else{
            // This means, we need only to re-render the cells by keeping the sorting but we change the enabled/disabled status of the chips
            // based on the current selected currency
            // Then let us update the enabled/disabled status for the chips
            currencyConvertedFromWidget = false
            dataHolder.viewModels.updateCardTelecomListEnableStatus()
        }
    }
    
    func updateGatewayChipsList(shouldSort:Bool = true) {
        
        if shouldSort && !currencyConvertedFromWidget {
            // This means, we have changed the currency or we are on load
            // In such a case, we will have to reset everything, deselect everything and sort the chips by putting the enabled payment methods first
            
            // First step to deselect everything selected in the gopay and gateways horizontal chips
            dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.deselectAll()
            
            //TODO: i Think we need to move it to tapGatewayChipHorizontalListViewModel.deselectAll()
            dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.selectedChip = nil
            
            dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.deselectAll()
            // let us get the two lists. 1 for enabled and 1 for disabled sorted then we append them together
            let enabledPaymentOptions  = dataHolder.viewModels.gatewayChipsViewModel.filter(for: dataHolder.transactionData.transactionUserCurrencyValue.currency)
            let disabledPaymentOptions = dataHolder.viewModels.gatewayChipsViewModel.filter(for: dataHolder.transactionData.transactionUserCurrencyValue.currency, and: false)
            // Let us add them
            dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.dataSource = enabledPaymentOptions + disabledPaymentOptions
            dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.scrollTo(index:0)
            // Then let us update the enabled/disabled status for the chips
            dataHolder.viewModels.updatePaymentChipsEnableStatus()
        }else{
            // This means, we need only to re-render the cells by keeping the sorting but we change the enabled/disabled status of the chips
            // based on the current selected currency
            // Then let us update the enabled/disabled status for the chips
            currencyConvertedFromWidget = false
            dataHolder.viewModels.updatePaymentChipsEnableStatus()
        }
        
        updateGoPayAndGatewayLists()
    }
    
    
    /// Handles the logic to fetch different sections from the Init API response
    func parseInitResponse() {
        // Double check..
        guard let initModel = dataHolder.transactionData.intitModelResponse else { return }
        // Based on the transaciton mode we define the header title
        let transactionMode = dataHolder.transactionData.transactionMode
        // Save the encryption for further access
        SharedCommongDataModels.sharedCommongDataModels.encryptionKey = initModel.data.encryptionKey
        
        // Fetch the merchant header info
        DispatchQueue.main.async {
            self.dataHolder.viewModels.tapMerchantViewModel = .init(title: (transactionMode == .cardSaving) ? "SAVE CARD" : nil, subTitle: initModel.data.merchant?.name, iconURL: initModel.data.merchant?.logoURL)
            self.dataHolder.viewModels.tapMerchantViewModel.iconURL = "https://i.ibb.co/9pWFvpt/VND1124340.png"
        }
    }
    
    /** We will accept
     If the merchant wants all.
     If the payment option type all.
     If the payment option matchs the merchant stated type.
     Only accept saved cards if the merchant wants all or wants Cards
     Only accept apple pay if the merchant wants all or device and the user's device is allowed to use Apple pay
     - Parameter paymentOptions: The original payment option response from the payment types API that we will filter from
     */
    fileprivate func fetchGateways(_ paymentOptions: TapPaymentOptionsReponseModel) {
        // Now let us add everything allowed except for saved cards in the next step
        self.dataHolder.viewModels.gatewayChipsViewModel = (
            // Filter out the saved card payment options
            paymentOptions.paymentOptions.filter{ $0.paymentType != .Card }
            // Filter out apple pay if the device is not allowed to perform any apple pay transactions
                .filter{ $0.paymentType != .ApplePay || ($0.paymentType == .ApplePay && PKPaymentAuthorizationController.canMakePayments(usingNetworks: $0.applePayNetworkMapper())) }
            // Filter the matching the payment options
                .filter{ (dataHolder.transactionData.paymentType == .All || dataHolder.transactionData.paymentType == $0.paymentType || $0.paymentType == .All)}).map{ ChipWithCurrencyModel.init(paymentOption: $0) }
        
        // Fetch the merchant saved card if cards are allowed
        if dataHolder.transactionData.paymentType == .All || dataHolder.transactionData.paymentType == .Card {
            self.dataHolder.viewModels.gatewayChipsViewModel.append(contentsOf: (paymentOptions.savedCards ?? []).filter{ dataHolder.transactionData.allowedCardTypes.contains($0.cardType ?? .init(cardType: .All)) }.map{ ChipWithCurrencyModel.init(savedCard: $0) })
        }
    }
    
    /// For some of the gateways, we will set an image background for the action button. It will be good if we cached them, so whenever they are clicked, they will reflect directly on the action button/
    private func cacheActionButtonTitleImages() {
        self.dataHolder.transactionData.paymentOptionsModelResponse?.paymentOptions.forEach({ paymentOption in
            // Check if we have a style passed first,
            // Then there is a valid url to load
            if let buttonStyle:PaymentOptionButtonStyle = paymentOption.buttonStyle,
                  let _ = buttonStyle.titlesAssets,
               let finalURL:URL = URL(string:buttonStyle.paymentOptionImageUrl(for: (UIView().traitCollection.userInterfaceStyle == .dark) ? TapThemeManager.showColoredForDarkMode ? "dark_colored" : "dark" : TapThemeManager.showMonoForLightMode ? "light_mono" : "light", and: TapLocalisationManager.shared.localisationLocale ?? "en", with: ".png")),
               UIApplication.shared.canOpenURL(finalURL) {
                // Let us cache it
                ImagePipeline.shared.loadImage(
                    with: finalURL) { _ in
                        print("LOADED \(finalURL)")
                    }
            }
        })
    }
    
    /** Fetches the loyalty model and updates the loyalty view model if any
     - Parameter paymentOptions: The payment options response we got from payment types api.
     */
    /*fileprivate func fetchLoyaltyModel(_ paymentOptions: TapPaymentOptionsReponseModel) {
        guard let nonNullLoyaltyModel : TapLoyaltyModel = paymentOptions.loyaltyModel else {
            // That means no loyalty found so let us make it nil for now and we show nothing
            dataHolder.viewModels.tapLoyaltyViewModel = nil
            return
        }
        // Otherwise let us update the viewmodel with the new model we got from the backend
        dataHolder.viewModels.tapLoyaltyViewModel?.loyaltyModel = nonNullLoyaltyModel
        //updateLoyaltySection()
    }*/
    
    
    /** Fetches thecustomer collected data if any
     - Parameter paymentOptions: The payment options response we got from payment types api.
     */
    /*fileprivate func fetchCustomerContactDataModel(_ paymentOptions: TapPaymentOptionsReponseModel) {
        // Dummy creation until coming from API
        dataHolder.viewModels.customerDataViewModel = CustomerContactDataCollectionViewModel.init(toBeCollectedData: [.email,.phone], allowedCountries: [.EG,.KW,.SA,.BH,.AE,.OM,.QA,.JO,.LB], selectedCountry: .EG)
        dataHolder.viewModels.customerShippingViewModel = CustomerShippingDataCollectionViewModel.init(allowedCountries: TapCountryCode.allCases, selectedCountry: .EG)
    }*/
    
    /** Update the total payable amount as we got from the backend
     - Parameter paymentOptions: The payment options response we got from payment types api.
     */
    fileprivate func fetchTotalAmount(_ paymentOptions: TapPaymentOptionsReponseModel) {
        // We will get the total amount calcilated from the backend for the original currency the merchant started the transaction with
        let originalCurrency:TapCurrencyCode = paymentOptions.currency
        let backendPayablePrice:Double = paymentOptions.supportedCurrenciesAmounts.filter{ $0.currency == originalCurrency }.first?.amount ?? self.dataHolder.transactionData.transactionTotalAmountValue
        // Now set the total amount from the backend to override any local calculations done before calling the api
        self.dataHolder.transactionData.transactionCurrencyValue.amount         = backendPayablePrice
        self.dataHolder.transactionData.transactionUserCurrencyValue.amount     = backendPayablePrice
    }
    
    /**
     Fetch the list of the goPay supported login countries and the list of goPay saved cards
     - Parameter paymentOptions: The payment options response we got from payment types api.
     */
    fileprivate func fetchGoPayData(_ paymentOptions: TapPaymentOptionsReponseModel) {
        // Fetch the list of the goPay supported login countries
        self.dataHolder.viewModels.goPayLoginCountries = [.init(nameAR: "مصر", nameEN: "Egypt", code: "20", phoneLength: 10)]//paymentOptions.dataHolder.viewModels.goPayLoginCountries ?? []
        self.dataHolder.viewModels.goPayBarViewModel = .init(countries: dataHolder.viewModels.goPayLoginCountries)
        
        // Fetch the list of goPay Saved Cards
        // First check if cards are allowed
        self.dataHolder.viewModels.goPayChipsViewModel = []
    }
    
    /// Resets the entered data in the card form
    /// - Parameter shouldFireCardDataChanged: Indicates whether we neeed to take actions post resetting (e.g. marking the button as invalid.)
    func resetCardData(shouldFireCardDataChanged:Bool = false) {
        // We reset the card form
        
        let currentCardDelegate = dataHolder.viewModels.tapCardTelecomPaymentViewModel.delegate
        if !shouldFireCardDataChanged
        {
            //but we have to first tell the card delegate not to fire events upon resetting card data. As this will be considerd as user input to invalid data overriding the selection of the saved card
            dataHolder.viewModels.tapCardTelecomPaymentViewModel.delegate = nil
        }
        // Reset the data
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.setCard(with: .init(tapCardNumber:"asd"), then: false,for: .NormalCard)
        
        // Assign the delegate back
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.delegate = currentCardDelegate
    }
    
    /// Handles the logic to fetch different sections from the Payment options response
    func parsePaymentOptionsResponse() {
        // Double check
        guard let paymentOptions = dataHolder.transactionData.paymentOptionsModelResponse else { return }
        
        // Set the custom symbols to display with currencies as we got from backend
        TapAmountedCurrencyFormatter.customCurrencySymbols = [:]
        
        paymentOptions.supportedCurrenciesAmounts.forEach { currency in
            TapAmountedCurrencyFormatter.customCurrencySymbols?[currency.currency.rawValue] = currency.displaybaleSymbol
        }
        
        // Set the transction currency to the one matching the object we got from the backend
        if let backendCurrencyModel:AmountedCurrency = paymentOptions.supportedCurrenciesAmounts.first(where: { $0.currency.appleRawValue == self.dataHolder.transactionData.transactionCurrencyValue.currency.appleRawValue }) {
            self.dataHolder.transactionData.transactionCurrencyValue = backendCurrencyModel
        }
        
        // Fetch the list of supported currencies
        self.dataHolder.viewModels.currenciesChipsViewModel = paymentOptions.supportedCurrenciesAmounts.map{ CurrencyChipViewModel.init(currency: $0,icon: $0.cdnFlag) }
        
        // Now after getting the list, let us map them to the currencies chips view model
        self.dataHolder.viewModels.tapCurrienciesChipHorizontalListViewModel = .init(dataSource: dataHolder.viewModels.currenciesChipsViewModel, headerType: .NoHeader,selectedChip: dataHolder.viewModels.currenciesChipsViewModel.filter{ $0.currency == dataHolder.transactionData.transactionUserCurrencyValue }[0])
        
        // Update the total payable amount as we got from the backend
        fetchTotalAmount(paymentOptions)
        
        // Fetch the list of the goPay supported login countries and the list of goPay saved cards
        fetchGoPayData(paymentOptions)
        
        // Fetch the merchant payment gateways, make sure to fetch only the allowed ones as set by the merchant when starting the checkout process
        fetchGateways(paymentOptions)
        
        // Fetch the loyaly model from the payment options if any
        //fetchLoyaltyModel(paymentOptions)
        
        // Fetch the customer data collection if any
        //fetchCustomerContactDataModel(paymentOptions)
        
        // Load the goPayLogin status
        dataHolder.transactionData.loggedInToGoPay = false//UserDefaults.standard.bool(forKey: TapCheckoutConstants.GoPayLoginUserDefaultsKey)
        
        // Fetch the cards + telecom payments options
        self.dataHolder.viewModels.tapCardPhoneListDataSource = paymentOptions.paymentOptions.filter{ (dataHolder.transactionData.paymentType == .Card || dataHolder.transactionData.paymentType == .All) && $0.paymentType == .Card }.map{ CurrencyCardsTelecomModel.init(paymentOption: $0) }
        
        // Fetch local currency prompt needed data
        updateDefaultCurrenyPromptData()
        
        // We need to change the default item title in case the user didn't pass any items to have the correct name of the merchant we just got from the INIT api.
        updateDefaultItemTitle()
        
        // Let us cache the action button different backgrounds for so they reflect directly upon selection
        cacheActionButtonTitleImages()
        
        // Update the values for the views based on the all the fetched data from the api
        updateManager()
    }
    
    /// The method is responsible to do the logic needed after selecting a new payment option
    func postChangingPaymentOptionLogic() {
        // First, update the style for the action button based on the newly selected payment method
        let sharedManager = TapCheckout.sharedCheckoutManager()
        sharedManager.dataHolder.viewModels.tapActionButtonViewModel.buttonStyle = sharedManager.dataHolder.transactionData.selectedPaymentOption?.buttonStyle
    }
    
    /// Update the visibility of the views based on the transaction mode
    func updateViewsVisibility() {
        let sharedManager = TapCheckout.sharedCheckoutManager()
        
        switch sharedManager.dataHolder.transactionData.transactionMode {
            
        case .purchase,.authorizeCapture:
            // nothing to do as we will show all views in those modes
            break
        case .cardSaving:
            // We need to hide amount,goPay cards, gatways and save card switch
            sharedManager.dataHolder.viewModels.tapAmountSectionViewModel.shouldShow = false
            sharedManager.dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.shouldShow = false
            sharedManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.shouldShow = false
            // stop auto dismiss
            sharedManager.dataHolder.viewModels.swipeDownToDismiss = false
            break
        case .cardTokenization:
            // We need to hide amount, and save card switch
            sharedManager.dataHolder.viewModels.tapAmountSectionViewModel.shouldShow = false
            // stop auto dismiss
            sharedManager.dataHolder.viewModels.swipeDownToDismiss = false
            break
        }
    }
    
    
    /**
     Decides whether we shall show an edit button over the gateways chips list.
     - Returns: True if there is 1+ saved card so the user can edit and delete them. False otherwise.
     */
    func shouldShowEditButton() -> Bool {
        return TapCheckout.sharedCheckoutManager().dataHolder.viewModels.gatewayChipsViewModel.filter{$0.tapPaymentOption?.paymentType == .Card}.count > 0
    }
    
    /// Handles the logic to perform parsing for the card data loaded from the bin lookup api
    func parseTapBinResponse() {
        // We need to tell the network manager for further calls that we finished asking for the bin request and we can ask for more later.
        dataHolder.transactionData.currentlyRequestingBinFor = nil
        
        // First, we need to check if the card is one of the allowed types.
        if !shouldAllowCard() {
            // We shall instruct the card form to stop accepting any new data as the entered card prefix indicates an unallowed card type. And to reset itself to the empty card form with only the first 5 digits
            setCardData(with: .init(tapCardNumber:dataHolder.transactionData.currentCard?.tapCardNumber?.tap_substring(to: 5)), then: true,for:.NormalCard, forceNoFocus: forceNoFocusAfterBinLookup)
        }
        
        // Second, we should indicate the card brand detector, that we now have a favorite/preferred brand to select for this card scheme
        
        CardValidator.favoriteCardBrand = fetchSupportedCardSchemes(for: dataHolder.transactionData.binLookUpModelResponse?.scheme?.cardBrand)
        
        // Third instruct the Card form to reselect the correct chip based on the new favorite brand from bin response if any
        guard let currentCard = dataHolder.transactionData.currentCard else { return }
        
        setCardData(with: currentCard, then: (currentCard.tapCardNumber?.count ?? 0) < 12, shouldRemoveCurrentCard:false, for:.NormalCard, forceNoFocus: forceNoFocusAfterBinLookup)
        
        forceNoFocusAfterBinLookup = false
    }
    
    
    /// Handles all the logic needed when the original transaction currency changed
    func transactionCurrencyUpdated() {
        // Change in the original transaction currency, means this is the basic configuration called from the merchanr on load, so we initialy set it to be the same as the selected user currency
        dataHolder.transactionData.transactionUserCurrencyValue = dataHolder.transactionData.transactionCurrencyValue
        
        // Apply the change into the Amount view model
        dataHolder.viewModels.tapAmountSectionViewModel.originalTransactionCurrency = dataHolder.transactionData.transactionCurrencyValue
    }
    
    
    /// The amount section and items list will be changed if total amount or the selected currency is changed one of them or both
    func handleChangeAmountAndCurrency() {
        guard dataHolder.transactionData.transactionTotalAmountValue != 0 && dataHolder.transactionData.transactionUserCurrencyValue.currency != .undefined else { return }
        updateManager()
    }
    
    /**
     Used to calclate the total price to be paid by the user, taking in consideration the items (each item with price. quantity, discounts, taxes) a transaction level shipping and taxes
     - Returns:the total price to be paid by the user, taking in consideration the items (each item with price. quantity, discounts, taxes) a transaction level shipping and taxes
     */
    func calculateFinalAmount() -> Double {
        let sharedManager = TapCheckout.sharedCheckoutManager()
        // If we have the final amounts from the backend we use the backend calculations, otherwise we locally compute it
        if let _ = sharedManager.dataHolder.transactionData.paymentOptionsModelResponse {
            // Then fetch the total amount for the current selected currency
            return dataHolder.transactionData.transactionUserCurrencyValue.amount
        }else{
            // locally computations
            // Get the transaction data like items, shipping and taxs lists
            let items:[ItemModel] = sharedManager.dataHolder.transactionData.transactionItemsValue
            let transactionShipping:Shipping? = sharedManager.dataHolder.transactionData.shipping
            let transactionTaxes:[Tax] = sharedManager.dataHolder.transactionData.taxes ?? []
            
            // First calculate the plain total amount from the items inclyding for each item X : (X's price * Quantity) - X's Discounty + X's Shipping + X's Taxes
            let totalItemsPrices:Double =   items.totalItemsPrices(convertFromCurrency: dataHolder.transactionData.transactionCurrencyValue, convertToCurrenct: dataHolder.transactionData.transactionUserCurrencyValue)
            // Second calculate the total shipping fees for the transaction level
            let shippingFees:Double     =   Double(truncating: (transactionShipping?.amount ?? 0) as NSNumber)
            // Third calculate the total Taxes fees for the transaction level
            let taxesFees = transactionTaxes.reduce(0) { $0 + $1.amount.caluclateActualModificationValue(with: totalItemsPrices+shippingFees) }
            // Now we can get the final amount
            let result = totalItemsPrices + shippingFees + taxesFees
            return result
        }
    }
    
    
    /// Handles the logic needed to create the tap items view model by utilising the original currency and the items list passed by the merchant
    func createTapItemsViewModel() {
        // Convert the passed items models into the ItemCellViewModels and update the items table view model with the new created list
        let itemsModels:[ItemCellViewModel] = dataHolder.transactionData.transactionItemsValue.map{ ItemCellViewModel.init(itemModel: $0, originalCurrency:dataHolder.transactionData.transactionCurrencyValue) }
        dataHolder.viewModels.tapItemsTableViewModel = .init(dataSource: itemsModels)
        dataHolder.viewModels.tapAmountSectionViewModel.numberOfItems = dataHolder.transactionData.transactionItemsValue.count
    }
}


extension TapCheckout:NetworkManagerDelegate {
    func apiCallInProgress(status: Bool) {
        //TapCheckout.sharedCheckoutManager().UIDelegate?.enableInteraction(with: !status)
    }
    
    func log(string: String) {
        tapCheckoutScreenDelegate?.log?(string: string)
    }
}


extension TapCheckout:TapActionButtonViewModelDelegate {
    public func didStartLoading() {
        TapCheckout.sharedCheckoutManager().UIDelegate?.enableInteraction(with: false)
    }
    
    public func didEndLoading() {
        TapCheckout.sharedCheckoutManager().UIDelegate?.enableInteraction(with: true)
    }
    
    
}


internal extension DispatchQueue {
    
    static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }
    
}
