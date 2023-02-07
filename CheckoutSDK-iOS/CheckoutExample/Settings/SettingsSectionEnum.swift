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
    case SDKMode
    case Localisation
    case TransactionMode
    case Theme
    case Currency
    case SwipeToDismiss
    case AddShipping
    case CloseButtonTitle
    case PyamentOptions
    case CreditCardName
    case CreditSaveCardName
    case Customer
    case Bundle
    case Loyalty
    case ApplePayRecurring
    
    var title: String {
        switch self {
        case .Language: return "Language"
        case .SDKMode: return "SDK mode"
        case .Localisation: return "Custom Localisation"
        case .Theme: return "Theme"
        case .Currency: return "Currency"
        case .SwipeToDismiss: return "Swipe to dismiss"
        case .AddShipping: return "Shipping"
        case .CloseButtonTitle: return "Close sheet as a title"
        case .PyamentOptions: return "Pyament Options"
        case .CreditCardName: return "Collect card holder name"
        case .CreditSaveCardName: return "Save card"
        case .Customer: return "Customer"
        case .TransactionMode: return "Transaction mode"
        case .Bundle: return "Bundle data"
        case .Loyalty: return "Loyalty data"
        case .ApplePayRecurring: return "Apple pay recurring"
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
        case .AddShipping: return ["Add dummy shipping of value 10 to the trx"]
        case .CloseButtonTitle: return ["Enable to see it as title or disable it to be as an icon"]
        case .PyamentOptions: return ["Select payment options"]
        case .CreditCardName: return ["Will display the card name field"]
        case .CreditSaveCardName: return ["Will save card to merchant"]
        case .Customer: return["Your customer"]
        case .Bundle: return["Bundle and keys"]
        case .Loyalty: return["Loyalty redemption progam"]
        case .TransactionMode: return["Change the transaction mode"]
        case .ApplePayRecurring: return["Adjust subscription transaction"]
        }
    }
    
    var cellType: SettingsCellType {
        switch self {
        case .Localisation, .SwipeToDismiss,.CloseButtonTitle, .AddShipping, .CreditCardName:
            return .SwitchButton
        default:
            return .TitleSubtitle
        }
    }
}
