//
//  PaymentOptionButtonStyle.swift
//  CommonDataModelsKit-iOS
//
//  Created by Osama Rabie on 19/04/2023.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let paymentOptionButtonStyle = try PaymentOptionButtonStyle(json)

import Foundation
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let paymentOptionButtonStyle = try PaymentOptionButtonStyle(json)


// MARK: - PaymentOptionButtonStyle
public struct PaymentOptionButtonStyle: Codable {
    public var background: Background?
    public var titlesAssets: TitlesAssets?
    public var paymenOptionName: String?
    
    enum CodingKeys: String, CodingKey {
        case background
        case titlesAssets = "titles_assets"
    }
}

// MARK: PaymentOptionButtonStyle convenience initializers and mutators

extension PaymentOptionButtonStyle {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PaymentOptionButtonStyle.self, from: data)
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    /// Returns and computes the list of colors for the ingredients passed to this style.
    /// Also, it auto computes whether we need to display the dark or light colors based on the device interface
    public func backgroundColors() -> [UIColor] {
        guard let lightBackgroundColors:[String] = background?.light?.backgroundColors,
              let darkBackgroundColors:[String] = background?.dark?.backgroundColors else { return [.black] }
        
        // We decide which theme object to user based on the current userInterfaceStyle
        if #available(iOS 12.0, *) {
            return (UIView().traitCollection.userInterfaceStyle == .dark) ? darkBackgroundColors.compactMap{ UIColor(tap_hex: $0) } : lightBackgroundColors.compactMap{ UIColor(tap_hex: $0) }
        } else {
            // Fallback on earlier versions
            return lightBackgroundColors.compactMap{ UIColor(tap_hex: $0) }
        }
    }
    
    /// Returns the solid color the button should show after shrinking while loading
    /// Also, it auto computes whether we need to display the dark or light colors based on the device interface
    func baseColor() -> UIColor {
        guard let lightBackgroundColor:String = background?.light?.baseColor,
              let darkBackgroundColor:String = background?.dark?.baseColor else { return .black }
        
        // We decide which theme object to user based on the current userInterfaceStyle
        if #available(iOS 12.0, *) {
            return (UIView().traitCollection.userInterfaceStyle == .dark) ? UIColor(tap_hex: lightBackgroundColor)! : UIColor(tap_hex: darkBackgroundColor)!
        } else {
            // Fallback on earlier versions
            return UIColor(tap_hex: lightBackgroundColor)!
        }
    }
    
    func with(
        background: Background?? = nil,
        titlesAssets: TitlesAssets?? = nil,
        paymentOptionName: String?? = nil
    ) -> PaymentOptionButtonStyle {
        return PaymentOptionButtonStyle(
            background: background ?? self.background,
            titlesAssets: titlesAssets ?? self.titlesAssets,
            paymenOptionName: self.paymenOptionName
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Background
public struct Background: Codable {
    var light, dark: BackgroundDark?
}

// MARK: Background convenience initializers and mutators

extension Background {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Background.self, from: data)
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        light: BackgroundDark?? = nil,
        dark: BackgroundDark?? = nil
    ) -> Background {
        return Background(
            light: light ?? self.light,
            dark: dark ?? self.dark
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - BackgroundDark
struct BackgroundDark: Codable {
    var baseColor: String?
    var backgroundColors: [String]?
    
    enum CodingKeys: String, CodingKey {
        case baseColor = "base_color"
        case backgroundColors = "background_colors"
    }
}

// MARK: BackgroundDark convenience initializers and mutators

extension BackgroundDark {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(BackgroundDark.self, from: data)
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        baseColor: String?? = nil,
        backgroundColors: [String]?? = nil
    ) -> BackgroundDark {
        return BackgroundDark(
            baseColor: baseColor ?? self.baseColor,
            backgroundColors: backgroundColors ?? self.backgroundColors
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - TitlesAssets
public struct TitlesAssets: Codable {
    public  var baseURL:String
}

// MARK: TitlesAssets convenience initializers and mutators

extension TitlesAssets {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(TitlesAssets.self, from: data)
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        baseURL:String
    ) -> TitlesAssets {
        return TitlesAssets(
            baseURL: baseURL
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - Helper functions for creating encoders and decoders


@propertyWrapper public struct NilOnFail<T: Codable>: Codable {
    
    public let wrappedValue: T?
    public init(from decoder: Decoder) throws {
        wrappedValue = try? T(from: decoder)
    }
    public init(_ wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }
}
