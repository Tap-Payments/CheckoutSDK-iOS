//
//  UtilitiesProtocols.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/15/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import CommonDataModelsKit_iOS

/// A protocol used to imply that the sub class has an array of supported currencies and can be filtered regarding it
internal protocol FilterableByCurrency {
    
    var supportedCurrencies: [TapCurrencyCode] { get }
}

/// A protocol used to imply that the sub class has an array can be sorted by a given KEY
internal protocol SortableByOrder {
    
    var orderBy: Int { get }
}


/// All models that have identifier are conforming to this protocol.
internal protocol IdentifiableWithString {
    
    // MARK: Properties
    
    /// Unique identifier of an object.
    var identifier: String { get }
}


/// All models that have identifier are conforming to this protocol.
internal protocol OptionallyIdentifiableWithString {
    
    // MARK: Properties
    
    /// Unique identifier of an object.
    var identifier: String? { get }
}



extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()
        
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
    
    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}

