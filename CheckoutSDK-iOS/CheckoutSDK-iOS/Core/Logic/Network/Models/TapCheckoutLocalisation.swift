//
//  TapCheckoutLocalisation.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 17/03/2022.
//  Copyright © 2022 Tap Payments. All rights reserved.
//

import Foundation
import LocalisationManagerKit_iOS

/**
 Represents a model to pass custom localisation  files if required.
 If you want to add a custom localisation please do the following:
 * Download the original [Default localisation](https://github.com/Tap-Payments/CommonDataModelsKit-iOS/blob/master/CommonDataModelsKit-iOS/CommonDataModelsKit-iOS/Core/assets/DefaultTapLocalisation.json) and
 * Embedd them as assets inside your own project.
 * Adjust the needed values inside them
 * Pass their names in this Object
 */
@objc public class TapCheckoutLocalisation: NSObject {
    /// Represents the file name of the custom provided localisation file
    internal var filePath:URL?
    /// Represents the type of the provided custom localisation, whether it is local embedded or a remote JSON file
    internal var localisationType:TapLocalisationType?
    
    /**
     Represents a model to pass custom localisation  files if required.
     - Parameter filePath: The name of the light mode theme you file in your project you want to use. It is required
     - Parameter localisationType:  Represents the type of the provided custom localisation, whether it is local embedded or a remote JSON file
     */
    @objc public init(with filePath:URL,from localisationType:TapLocalisationType = .LocalJsonFile) {
        super.init()
        // Check he didn't pass empty localisation file
        guard filePath.absoluteString != "" else {
            fatalError("Localisation file name cann't be empty")
        }
        self.localisationType = localisationType
        self.filePath = filePath
    }
}
