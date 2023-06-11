//
//  TapCurrencyWidgetViewModel.swift
//  TapUIKit-iOS
//
//  Created by MahmoudShaabanAllam on 25/05/2023.
//  Copyright © 2023 Tap Payments. All rights reserved.
//

import Foundation
import LocalisationManagerKit_iOS
import CommonDataModelsKit_iOS

/// An external delegate to listen to events fired from the whole loyalty widget
public protocol TapCurrencyWidgetViewModelDelegate {
    
    /**
     Will be fired when a user click on confirm button
     - Parameter for viewModel: The view model that contains the button which clicked. This will help the delegate to know the data like (selected currency, attached payment option, etc.)
     */
    func confirmClicked(for viewModel:TapCurrencyWidgetViewModel)
    
}

internal protocol TapCurrencyWidgetViewDelegate {
    /// Consolidated one point to reload view
    func reload()
    
    /// Remove any tool tip appear
    func removeTooltip()
}

/// The view model that controls the data shown inside a TapCurrencyWidget
public class TapCurrencyWidgetViewModel:NSObject {
    
    // MARK:- Internal swift variables
    /// Reference to the  currency widget view itself as UI that will be rendered
    internal var tapCurrencyWidgetView:TapCurrencyWidgetView?
    /// Localisation kit key path
    internal var localizationPath = "CurrencyChangeWidget"
    /// Configure the localisation Manager
    internal let sharedLocalisationManager = TapLocalisationManager.shared
    
    internal var viewDelegate:TapCurrencyWidgetViewDelegate?
    
    
    /// The Amount user will pay when choose this payment option
    private var convertedAmounts: [AmountedCurrency]
    /// The  payment option to be shown
    private var paymentOption: PaymentOption
    /// An external delegate to listen to events fired from the currency widget view
    private var delegate:TapCurrencyWidgetViewModelDelegate?
    /// State of currency drop down menu
    private var isCurrencyDropDownShown: Bool = false
    /// The Amount user will pay when choose this payment option
    private var selectedAmountCurrency: AmountedCurrency?

    
    // MARK: - Public normal swift variables
    /// Public reference to the loyalty view itself as UI that will be rendered
    public var attachedView: TapCurrencyWidgetView {
        return tapCurrencyWidgetView ?? .init()
    }
    
    
    
    
    /**
     Init method with the needed data
     - Parameter convertedAmounts: The Amounts user will pay when choose this payment option
     - Parameter paymentOption: The payment option we want to convert to
     */
    public init(convertedAmounts: [AmountedCurrency], paymentOption:PaymentOption) {
        self.convertedAmounts = convertedAmounts
        self.paymentOption = paymentOption
        self.selectedAmountCurrency = convertedAmounts.first
        super.init()
        defer{
            setup()
        }
    }
    
    /**
     Will update the content displayed on the widget with the newly given data
     - Parameter with convertedAmounts: The Amounts user will pay when choose this payment option
     - Parameter and paymentOption: The payment option we want to convert to
     */
    public func updateData(with convertedAmounts: [AmountedCurrency], and paymentOption:PaymentOption) {
        self.convertedAmounts = convertedAmounts
        self.paymentOption = paymentOption
        self.selectedAmountCurrency = convertedAmounts.first
        self.refreshData()
    }
    
    // MARK: - private
    /// function to setup viewmodel
    private func setup() {
        self.tapCurrencyWidgetView = .init()
        self.tapCurrencyWidgetView?.changeViewModel(with: self)
        self.refreshData()
    }
    
    
    // MARK: - Internal functions
    /// Computes the message label value
    internal var messageLabel: String {
        let localisationLocale = sharedLocalisationManager.localisationLocale
        if localisationLocale == "ar" {
            // In case of mixed English and Arabic content in the same label, we will have to use String.localized otherwise, the content will be mixed.
            return String.localizedStringWithFormat("%@ %@", sharedLocalisationManager.localisedValue(for: "\(localizationPath).header", with:TapCommonConstants.pathForDefaultLocalisation()), paymentOption.displayableTitle(for: localisationLocale ?? paymentOption.displayableTitle))
        } else {
            return "\(paymentOption.displayableTitle(for: localisationLocale ?? paymentOption.displayableTitle)) \(sharedLocalisationManager.localisedValue(for: "\(localizationPath).header", with:TapCommonConstants.pathForDefaultLocalisation()))"
        }
        
    }
    /// Computes the confirm button text value
    internal var confirmButtonText: String {
        return "\(sharedLocalisationManager.localisedValue(for: "\(localizationPath).confirmButton", with: TapCommonConstants.pathForDefaultLocalisation()))"
    }
    
    /// Computes the currency text value
    internal var amountLabel: String {
        return "\(selectedAmountCurrency?.currencySymbol ?? "") \(selectedAmountCurrency?.amount ?? 0)"
    }
    /// Computes the currency flag value
    internal var amountFlag: String {
        return selectedAmountCurrency?.flag ?? ""
    }
    
    /// Computes the payment Option logo value
    internal var paymentOptionLogo: URL {
        return paymentOption.correctCurrencyWidgetImageURL()
    }
    
    /// Computes the showing or disable the multiple currencies  option
    internal var showMultipleCurrencyOption: Bool {
       return convertedAmounts.count > 1
    }
    
    ///  State of drop currency down menu
    internal var isCurrencyDropDownExpanded: Bool {
        return isCurrencyDropDownShown;
    }
    
    /// On click on confirm button
    internal func confirmClicked() {
        delegate?.confirmClicked(for: self)
    }
    
    /// On click on currency
    internal func currencyClicked() {
        isCurrencyDropDownShown = !isCurrencyDropDownShown
        refreshData()
    }
    
    internal func getSupportedCurrenciesOptions() -> [AmountedCurrency] {
        return convertedAmounts.filter {
            $0.currency != selectedAmountCurrency?.currency
        }
    }
    
    internal func setSelectedAmountCurrency(selectedAmountCurrency: AmountedCurrency) {
        self.selectedAmountCurrency = selectedAmountCurrency
        tapCurrencyWidgetView?.removeTooltip()
        refreshData()
    }
    
    
    // MARK: - Public
    
    /// Refresh and reload view state
    public func refreshData() {
        // Reload view state
        tapCurrencyWidgetView?.reload()
    }
    
    /// Set view model delegate
    public func setTapCurrencyWidgetViewModelDelegate(delegate:TapCurrencyWidgetViewModelDelegate) {
        self.delegate = delegate
    }
}


    
    
