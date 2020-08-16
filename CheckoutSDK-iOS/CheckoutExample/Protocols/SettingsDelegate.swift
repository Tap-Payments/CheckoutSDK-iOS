//
//  LocalisationSettingsDelegate.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/12/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//
import Foundation
import CheckoutSDK_iOS

@objc public protocol SettingsDelegate {
    @objc func didUpdateLanguage(with locale: String)
    @objc func didUpdateLocalisation(to enabled: Bool)
    @objc func didChangeTheme(with themeName: String?)
    @objc func didChangeCurrency(with currency: TapCurrencyCode)
}
