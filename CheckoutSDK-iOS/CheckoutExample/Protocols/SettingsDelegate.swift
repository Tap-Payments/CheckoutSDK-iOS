//
//  LocalisationSettingsDelegate.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/12/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//
import Foundation
import CheckoutSDK_iOS
import CommonDataModelsKit_iOS
import TapUIKit_iOS

public protocol SettingsDelegate {
    func didUpdateLanguage(with locale: String)
    func didUpdateLocalisation(to enabled: Bool)
    func didChangeTheme(with themeName: String?)
    func didChangeCurrency(with currency: TapCurrencyCode)
    func didChangeCustomer(with customer: TapCustomer)
    func didUpdateSwipeToDismiss(to enabled: Bool)
    func didUpdateAddShipping(to enabled:Bool)
    func didUpdateCredCardName(to enabled:Bool)
    func didUpdateCredCardSave(to type:SaveCardType)
    func didUpdateCloseButtonTitle(to enabled:Bool)
    func didUpdatePaymentTypes(to types:[TapPaymentType])
    func didUpdateTransactionMode(to mode:TransactionMode)
}
