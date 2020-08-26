//
//  TapSettings.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/17/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//
import class Foundation.NSObject
import CheckoutSDK_iOS

@objc public class TapSettings: NSObject {
    var language: String {
        didSet {
            self.onChangeBlock?()
        }
    }
    var localisation: Bool {
        didSet {
            self.onChangeBlock?()
        }
    }
    var theme: String {
        didSet {
            self.onChangeBlock?()
        }
    }
    var currency: TapCurrencyCode {
        didSet {
            self.onChangeBlock?()
        }
    }
    var swipeToDismissFeature: Bool {
        didSet {
            self.onChangeBlock?()
        }
    }
    var onChangeBlock: (() -> ())?
    
    init(language: String, localisation: Bool, theme: String, currency: TapCurrencyCode, swipeToDismissFeature: Bool) {
        self.language = language
        self.localisation = localisation
        self.theme = theme
        self.currency = currency
        self.swipeToDismissFeature = swipeToDismissFeature
    }
}
