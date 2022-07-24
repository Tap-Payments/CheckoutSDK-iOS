//
//  LocalisationSettingsDelegate.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/12/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//
import Foundation
import CheckoutSDK_iOS

public protocol SettingsDelegate {
    func didUpdateLanguage(with locale: String)
    func didUpdateLocalisation(to enabled: Bool)
    func didChangeTheme(with themeName: String?)
    func didChangeCurrency(with currency: TapCurrencyCode)
    func didChangeCustomer(with customer: TapCustomer)
    func didUpdateSwipeToDismiss(to enabled: Bool)
    func didUpdateCloseButtonTitle(to enabled:Bool)
    func didUpdatePaymentTypes(to types:[TapPaymentType])
}
