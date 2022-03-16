//
//  TapCheckOutTheme.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/13/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation

/**
 Represents a model to pass custom dark and light theme files if required.
 If you want to add a custom theme modes please do the following:
 * Download the original [LightModeJsonFile](https://github.com/Tap-Payments/TapThemeManger-iOS/blob/master/TapThemeManager2020/TapThemeManager2020/Core/assets/DefaultLightTheme.json) and [DarkModeJsonFile](https://github.com/Tap-Payments/TapThemeManger-iOS/blob/master/TapThemeManager2020/TapThemeManager2020/Core/assets/DefaultDarkTheme.json)
 * Embedd them as assets inside your own project.
 * Adjust the needed values inside them
 * Pass their names in this Object
 */
@objc public class TapCheckOutTheme: NSObject {
    /// Represents the file name of the custom provided light theme file
    internal var lightModeThemeFileName:String?
    /// Represents the file name of the custom provided dark theme file
    internal var darkModeThemeFileName:String?
    /// Represents the type of the provided custom theme, whether it is local embedded or a remote JSON file
    internal var themeType:TapThemeType?
    
    /**
     Represents a model to pass custom dark and light theme files if required.
     - Parameter lightModeThemeFileName: The name of the light mode theme you file in your project you want to use. It is required
     - Parameter darkModeThemeFileName:  The name of the dark mode theme you file in your project you want to use. If not passed, the light mode one will be used for both displays
     - Parameter themeType:  Represents the type of the provided custom theme, whether it is local embedded or a remote JSON file
     */
    @objc public init(with lightModeThemeFileName:String,and darkModeThemeFileName:String?, from themeType:TapThemeType = .LocalJsonFile) {
        super.init()
        // Check he didn't pass empty light theme file
        guard lightModeThemeFileName != "" else {
            fatalError("Light mode file name cann't be empty")
        }
        self.lightModeThemeFileName = lightModeThemeFileName
        
        // Check if he didn't pass a dark theme file, we assign the light to it
        guard let nonNullDarkThemeFile = darkModeThemeFileName else {
            self.darkModeThemeFileName = lightModeThemeFileName
            return
        }
        self.darkModeThemeFileName = nonNullDarkThemeFile
        self.themeType = themeType
    }    
}


/// An enum that defines the type of the provided custom theme, whether it is local embedded or a remote JSON file
@objc public enum TapThemeType : Int {
    /// The custom theme file is an embedded json file
    case LocalJsonFile
    /// The custom theme file is a remote  json file
    case RemoteJsonFile
}
