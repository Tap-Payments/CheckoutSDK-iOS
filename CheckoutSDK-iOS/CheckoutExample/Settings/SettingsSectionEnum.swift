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
    case Theme
    case Currency
    case SwipeToDismiss
    case PyamentOptions
    
    var title: String {
        switch self {
        case .Language: return "Language"
        case .Localisation: return "Custom Localisation"
        case .Theme: return "Theme"
        case .Currency: return "Currency"
        case .SwipeToDismiss: return "Swipe to dismiss"
        case .PyamentOptions: return "Pyament Options"
        }
    }
    
    var rowsTitles: [String] {
        switch self {
        case .Language: return ["Change Language"]
        case .Localisation: return ["Show Custom Localization"]
        case .Theme: return ["Change Theme"]
        case .Currency: return ["Change Currency"]
        case .SwipeToDismiss: return ["Enable swipe to dismiss the checkout screen"]
        case .PyamentOptions: return ["Select payment options"]
        }
    }
    
    var cellType: SettingsCellType {
        switch self {
        case .Localisation, .SwipeToDismiss:
            return .SwitchButton
        default:
            return .TitleSubtitle
        }
    }
}
