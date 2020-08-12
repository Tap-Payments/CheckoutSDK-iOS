//
//  LocalisationSettingsDelegate.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/12/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//
import Foundation

@objc public protocol LocalisationSettingsDelegate {
    @objc func didUpdateLanguage(with locale: String)
    @objc func didUpdateLocalisation(to enabled: Bool)
}
