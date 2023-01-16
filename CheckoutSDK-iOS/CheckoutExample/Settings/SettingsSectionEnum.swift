//
//  SettingsSectionEnum.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 9/6/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation

@objc public enum SettingsCellType: Int {
    case TitleSubtitle
    case SwitchButton
}

@objc public enum SettingsSectionEnum: Int {
    case Language
    case Localisation
    case TransactionMode
    case SDKMode
    case Theme
    case Currency
    case SwipeToDismiss
    case CloseButtonTitle
    case PyamentOptions
    case Customer
    case ApplePaySubscription
    
    var title: String {
        switch self {
        case .Language: return "Language"
        case .Localisation: return "Custom Localisation"
        case .SDKMode: return "SDK mode"
        case .Theme: return "Theme"
        case .Currency: return "Currency"
        case .SwipeToDismiss: return "Swipe to dismiss"
        case .CloseButtonTitle: return "Close sheet as a title"
        case .PyamentOptions: return "Pyament Options"
        case .Customer: return "Customer"
        case .TransactionMode: return "Transaction mode"
        case .ApplePaySubscription: return "Apple Pay Subscripton"
        }
    }
    
    var rowsTitles: [String] {
        switch self {
        case .Language: return ["Change Language"]
        case .SDKMode: return ["SDK mode"]
        case .Localisation: return ["Show Custom Localization"]
        case .Theme: return ["Change Theme"]
        case .Currency: return ["Change Currency"]
        case .SwipeToDismiss: return ["Enable swipe to dismiss the checkout screen"]
        case .CloseButtonTitle: return ["Enable to see it as title or disable it to be as an icon"]
        case .PyamentOptions: return ["Select payment options"]
        case .Customer: return["Your customer"]
        case .TransactionMode: return["Change the transaction mode"]
        case .ApplePaySubscription: return["Adjust the apple pay subscription transaction"]
        }
    }
    
    var cellType: SettingsCellType {
        switch self {
        case .Localisation, .SwipeToDismiss,.CloseButtonTitle:
            return .SwitchButton
        default:
            return .TitleSubtitle
        }
    }
}
