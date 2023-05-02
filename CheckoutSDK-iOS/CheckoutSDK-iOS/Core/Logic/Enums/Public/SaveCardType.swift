//
//  SaveCardType.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 02/05/2023.
//  Copyright © 2023 Tap Payments. All rights reserved.
//

import Foundation
/// Defines which save card should be displayed
@objc public enum SaveCardType:Int,Codable,CaseIterable {
    /// Don't show the save card option at all
    case None
    /// Only display save card for merchant
    case Merchant
    /// Only display save card for TAP
    case Tap
    /// Display save card for merchant & TAP
    case All
    
    /// Retrusn string representation for the enum
    public func toString() -> String {
        switch self {
        case .None:
            return "None"
        case .Merchant:
            return "Merchant"
        case .Tap:
            return "Tap"
        case .All:
            return "All"
        }
    }
    
    public init(stringValue:String) {
        if stringValue.lowercased() == "none" {
            self = .None
        }else if stringValue.lowercased() == "merchant" {
            self = .Merchant
        }else if stringValue.lowercased() == "tap" {
            self = .Tap
        }else if stringValue.lowercased() == "all" {
            self = .All
        }else{
            self = .None
        }
    }
}
