//
//  TapFormSettingsViewController.swift
//  CheckoutExample
//
//  Created by Osama Rabie on 20/01/2023.
//

import UIKit
import Eureka
import CommonDataModelsKit_iOS
import TapUIKit_iOS
import TapApplePayKit_iOS

class TapFormSettingsViewController: Eureka.FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TapFormSettingsViewController.funcPreFillData()
        
        form +++ Section("SDK Configuration")
        <<< SegmentedRow<String>(TapSettingsKeys.SDKLanguage.rawValue, { row in
            row.title = "SDK language"
            row.options = ["English","Arabic"]
            row.value = UserDefaults.standard.string(forKey: TapSettingsKeys.SDKLanguage.rawValue) ?? "English"
            row.onChange { segmentRow in
                UserDefaults.standard.set(segmentRow.value ?? "English", forKey: TapSettingsKeys.SDKLanguage.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        <<< SegmentedRow<String>(TapSettingsKeys.SDKMode.rawValue, { row in
            row.title = "SDK mode"
            row.options = [SDKMode.sandbox.description, SDKMode.production.description]
            row.value = TapFormSettingsViewController.sdkMode().description
            row.onChange { segmentRow in
                UserDefaults.standard.set(segmentRow.value ?? SDKMode.sandbox.description , forKey: TapSettingsKeys.SDKMode.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        <<< SegmentedRow<String>(TapSettingsKeys.SDKCloseButton.rawValue, { row in
            row.title = "Close button"
            row.options = ["Icon", "Title"]
            row.value = TapFormSettingsViewController.showCloseButtonTitle() ? "Title" : "Icon"
            row.onChange { segmentRow in
                UserDefaults.standard.set(row.options?.firstIndex(of: segmentRow.value ?? "Icon") == 1 , forKey: TapSettingsKeys.SDKCloseButton.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        
        form +++ Section("Logging Configuration")
        <<< SwitchRow(TapSettingsKeys.SDKULogUI.rawValue, { row in
            row.title = "Log UI events"
            row.value = TapFormSettingsViewController.loggingCapabilities().0
            row.onChange { switchRow in
                UserDefaults.standard.set(switchRow.value, forKey: TapSettingsKeys.SDKULogUI.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        <<< SwitchRow(TapSettingsKeys.SDKLogApi.rawValue, { row in
            row.title = "Log Api calls"
            row.value = TapFormSettingsViewController.loggingCapabilities().1
            row.onChange { switchRow in
                UserDefaults.standard.set(switchRow.value, forKey: TapSettingsKeys.SDKLogApi.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        <<< SwitchRow(TapSettingsKeys.SDKLogEvents.rawValue, { row in
            row.title = "Log user's events"
            row.value = TapFormSettingsViewController.loggingCapabilities().2
            row.onChange { switchRow in
                UserDefaults.standard.set(switchRow.value, forKey: TapSettingsKeys.SDKLogEvents.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        <<< SwitchRow(TapSettingsKeys.SDKLogConsole.rawValue, { row in
            row.title = "Log to Xcode console for development"
            row.value = TapFormSettingsViewController.loggingCapabilities().3
            row.onChange { switchRow in
                UserDefaults.standard.set(switchRow.value, forKey: TapSettingsKeys.SDKLogConsole.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        <<< ButtonRow(TapSettingsKeys.SDKLogPlatform.rawValue, { row in
            row.title = "See logs"
            row.onCellSelection({ cell, row in
                DispatchQueue.main.async {
                    UIApplication.shared.open(URL(string: "https://dashboard.bugfender.com/login?next=%2F")!)
                }
            })
        })
        
        
        form +++ Section("Transaction Configuration")
        <<< PickerInlineRow<String>(TapSettingsKeys.SDKTransactionMode.rawValue, { row in
            row.title = "Trx mode"
            row.options = TransactionMode.allCases.map{ $0.description }
            row.value = TapFormSettingsViewController.transactionSettings().0.description
            row.onChange { row in
                UserDefaults.standard.set(row.value, forKey: TapSettingsKeys.SDKTransactionMode.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        
        <<< PickerInlineRow<String>(TapSettingsKeys.SDKTransactionCurrency.rawValue, { row in
            row.title = "Currency"
            row.options = [TapCurrencyCode.KWD.appleRawValue, TapCurrencyCode.AED.appleRawValue, TapCurrencyCode.SAR.appleRawValue, TapCurrencyCode.BHD.appleRawValue, TapCurrencyCode.OMR.appleRawValue,
                           TapCurrencyCode.QAR.appleRawValue,
                           TapCurrencyCode.EGP.appleRawValue,
                           TapCurrencyCode.USD.appleRawValue,
                           TapCurrencyCode.EUR.appleRawValue]
            row.value = TapFormSettingsViewController.transactionSettings().1.appleRawValue
            row.onChange { row in
                UserDefaults.standard.set(row.value, forKey: TapSettingsKeys.SDKTransactionCurrency.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        <<< PickerInlineRow<String>(TapSettingsKeys.SDKTransactionPaymentTypes.rawValue, { row in
            row.title = "Payment types"
            row.options = TapPaymentType.allCases.map{ $0.stringValue }
            row.value = TapFormSettingsViewController.transactionSettings().2.stringValue
            row.onChange { row in
                UserDefaults.standard.set(row.value, forKey: TapSettingsKeys.SDKTransactionPaymentTypes.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        
        form +++ Section("Card Configuration")
        <<< SwitchRow(TapSettingsKeys.SDKCardName.rawValue, { row in
            row.title = "Collect card name"
            row.value = TapFormSettingsViewController.cardSettings().0
            row.onChange { switchRow in
                UserDefaults.standard.set(switchRow.value, forKey: TapSettingsKeys.SDKCardName.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        <<< PickerInlineRow<String>(TapSettingsKeys.SDKCardType.rawValue, { row in
            row.title = "Allowed card types"
            row.options = cardTypes.allCases.map{ $0.description }
            row.value = TapFormSettingsViewController.cardSettings().1.cardType.description
            row.onChange { row in
                UserDefaults.standard.set(row.value, forKey: TapSettingsKeys.SDKCardType.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        <<< PickerInlineRow<String>(TapSettingsKeys.SDKCardSave.rawValue, { row in
            row.title = "Allowed save card options"
            row.options = SaveCardType.allCases.map{ $0.toString() }
            row.value = TapFormSettingsViewController.cardSettings().2.toString()
            row.onChange { row in
                UserDefaults.standard.set(row.value, forKey: TapSettingsKeys.SDKCardSave.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        <<< SwitchRow(TapSettingsKeys.SDKCardNameEnabled.rawValue, { row in
            row.title = "Card name editable"
            row.value = TapFormSettingsViewController.cardSettings().3
            row.onChange { switchRow in
                UserDefaults.standard.set(switchRow.value, forKey: TapSettingsKeys.SDKCardNameEnabled.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        <<< TextRow(TapSettingsKeys.SDKCardNamePreload.rawValue, { row in
            row.title = "Preload card name"
            row.placeholder = "Card's holder name"
            row.value = TapFormSettingsViewController.cardSettings().4
            row.onChange { textRow in
                UserDefaults.standard.set(textRow.value ?? "", forKey: TapSettingsKeys.SDKCardNamePreload.rawValue)
            }
        })
        
        <<< SwitchRow(TapSettingsKeys.SDKCardRequire3DS.rawValue, { row in
            row.title = "Require 3DS"
            row.value = TapFormSettingsViewController.cardSettings().5
            row.onChange { switchRow in
                UserDefaults.standard.set(switchRow.value, forKey: TapSettingsKeys.SDKCardRequire3DS.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        <<< SwitchRow(TapSettingsKeys.SDKCardForceLTR.rawValue, { row in
            row.title = "Force LTR"
            row.value = TapFormSettingsViewController.cardSettings().6
            row.onChange { switchRow in
                UserDefaults.standard.set(switchRow.value, forKey: TapSettingsKeys.SDKCardForceLTR.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        
        form +++ Section("Customer Configuration", { section in
            section.tag = "CustomerConfiguration"
        })
        <<< SegmentedRow<String>(TapSettingsKeys.SDKCustomerType.rawValue, { row in
            row.title = "Customer type"
            row.options = SDKCustomerType.allCases.map{ $0.rawValue }
            row.value = TapFormSettingsViewController.customerSettings().0.rawValue
            row.onChange { row in
                UserDefaults.standard.set(row.value, forKey: TapSettingsKeys.SDKCustomerType.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        <<< TextRow(TapSettingsKeys.SDKCustomerID.rawValue, { row in
            row.title = "Customer ID"
            row.placeholder = "Fill in your customer id here please"
            row.value = TapFormSettingsViewController.customerSettings().1
            row.hidden = .function([TapSettingsKeys.SDKCustomerType.rawValue], { form in
                return !TapFormSettingsViewController.showCustomerID()
            })
            row.onChange { textRow in
                UserDefaults.standard.set(textRow.value ?? "cus_TS075220212320q2RD0707283", forKey: TapSettingsKeys.SDKCustomerID.rawValue)
            }
        })
        
        <<< TextRow(TapSettingsKeys.SDKCustomerName.rawValue, { row in
            row.title = "Customer name"
            row.placeholder = "Fill in customer's name"
            row.hidden = .function([TapSettingsKeys.SDKCustomerType.rawValue], { form in
                return TapFormSettingsViewController.showCustomerID()
            })
            row.value = TapFormSettingsViewController.customerSettings().2
            row.onChange { textRow in
                UserDefaults.standard.set(textRow.value ?? "", forKey: TapSettingsKeys.SDKCustomerName.rawValue)
            }
        })
        
        <<< EmailRow(TapSettingsKeys.SDKCustomerEmail.rawValue, { row in
            row.title = "Customer email"
            row.placeholder = "Fill in customer's email"
            row.hidden = .function([TapSettingsKeys.SDKCustomerType.rawValue], { form in
                return TapFormSettingsViewController.showCustomerID()
            })
            row.value = TapFormSettingsViewController.customerSettings().3
            row.onChange { textRow in
                UserDefaults.standard.set(textRow.value ?? "", forKey: TapSettingsKeys.SDKCustomerEmail.rawValue)
            }
        })
        
        <<< PickerInlineRow<String>(TapSettingsKeys.SDKCustomerISDN.rawValue, { row in
            row.title = "Customer's country code"
            row.options = ["965","966","20","973","974","40","971"].sorted()
            row.hidden = .function([TapSettingsKeys.SDKCustomerType.rawValue], { form in
                return TapFormSettingsViewController.showCustomerID()
            })
            row.value = TapFormSettingsViewController.customerSettings().4
            row.onChange { row in
                UserDefaults.standard.set(row.value, forKey: TapSettingsKeys.SDKCustomerISDN.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        
        <<< PhoneRow(TapSettingsKeys.SDKCustomerPhone.rawValue, { row in
            row.title = "Customer phone"
            row.placeholder = "Fill in customer's phone"
            row.hidden = .function([TapSettingsKeys.SDKCustomerType.rawValue], { form in
                return TapFormSettingsViewController.showCustomerID()
            })
            row.value = TapFormSettingsViewController.customerSettings().5
            row.onChange { textRow in
                UserDefaults.standard.set(textRow.value ?? "", forKey: TapSettingsKeys.SDKCustomerPhone.rawValue)
            }
        })
        
        <<< SwitchRow(TapSettingsKeys.SDKCustomerShippingAddress.rawValue, { row in
            row.title = "Add shipping address?"
            row.value = TapFormSettingsViewController.customerSettings().6
            row.hidden = .function([TapSettingsKeys.SDKCustomerType.rawValue], { form in
                return TapFormSettingsViewController.showCustomerID()
            })
            row.onChange { switchRow in
                UserDefaults.standard.set(switchRow.value, forKey: TapSettingsKeys.SDKCustomerShippingAddress.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        form +++ Section("Extra Fees")
        <<< SwitchRow(TapSettingsKeys.SDKFeesShipping.rawValue, { row in
            row.title = "Add dummy shipping of amount 10"
            row.value = TapFormSettingsViewController.extraFees().0
            row.onChange { switchRow in
                UserDefaults.standard.set(switchRow.value, forKey: TapSettingsKeys.SDKFeesShipping.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        <<< SwitchRow(TapSettingsKeys.SDKFeesTax.rawValue, { row in
            row.title = "Add dummy tax of amount 10%"
            row.value = TapFormSettingsViewController.extraFees().1
            row.onChange { switchRow in
                UserDefaults.standard.set(switchRow.value, forKey: TapSettingsKeys.SDKFeesTax.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        form +++ Section("Merchant Configuration")
        <<< TextRow(TapSettingsKeys.SDKSandBoxKey.rawValue, { row in
            row.title = "Sandbox key"
            row.placeholder = "Key"
            row.value = TapFormSettingsViewController.merchantSettings().0
            row.onChange { textRow in
                UserDefaults.standard.set(textRow.value ?? "sk_test_cvSHaplrPNkJO7dhoUxDYjqA", forKey: TapSettingsKeys.SDKSandBoxKey.rawValue)
            }
        })
        
        <<< TextRow(TapSettingsKeys.SDKProductionKey.rawValue, { row in
            row.title = "Production key"
            row.placeholder = "Key"
            row.value = TapFormSettingsViewController.merchantSettings().1
            row.onChange { textRow in
                UserDefaults.standard.set(textRow.value ?? "sk_live_V4UDhitI0r7sFwHCfNB6xMKp", forKey: TapSettingsKeys.SDKProductionKey.rawValue)
            }
        })
        
        <<< TextRow(TapSettingsKeys.SDKBundleID.rawValue, { row in
            row.title = "Bundle id"
            row.placeholder = "Bundle id"
            row.value = TapFormSettingsViewController.merchantSettings().2
            row.onChange { textRow in
                UserDefaults.standard.set(textRow.value ?? "company.tap.goSellSDKExamplee", forKey: TapSettingsKeys.SDKBundleID.rawValue)
            }
        })
        
        <<< TextRow(TapSettingsKeys.SDKBMerchantID.rawValue, { row in
            row.title = "Merchant id"
            row.placeholder = "Merchant id"
            row.value = TapFormSettingsViewController.merchantSettings().3
            row.onChange { textRow in
                UserDefaults.standard.set(textRow.value ?? "", forKey: TapSettingsKeys.SDKBMerchantID.rawValue)
            }
        })
        
        <<< TextRow(TapSettingsKeys.SDKApplePayMerchantID.rawValue, { row in
            row.title = "ApplePay merchant id"
            row.placeholder = "Apple pay merchant id"
            row.value = TapFormSettingsViewController.merchantSettings().4
            row.onChange { textRow in
                UserDefaults.standard.set(textRow.value ?? "merchant.tap.gosell", forKey: TapSettingsKeys.SDKApplePayMerchantID.rawValue)
            }
        })
        
        form +++ Section("Apple Pay")
        
        <<< PickerInlineRow<String>(TapSettingsKeys.SDKApplePayButtonType.rawValue, { row in
            row.title = "Apple pay button title"
            row.options = TapApplePayButtonType.allCases.map{ $0.rawValue }
            row.value = TapFormSettingsViewController.applePaySettings().0.rawValue
            row.onChange { row in
                UserDefaults.standard.set(row.value, forKey: TapSettingsKeys.SDKApplePayButtonType.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        <<< PickerInlineRow<String>(TapSettingsKeys.SDKApplePayButtonStyle.rawValue, { row in
            row.title = "Apple pay button color"
            row.options = TapApplePayButtonStyleOutline.allCases.filter{ $0 != .WhiteOutline }.map{ $0.rawValue }
            row.value = TapFormSettingsViewController.applePaySettings().1.rawValue
            row.onChange { row in
                UserDefaults.standard.set(row.value, forKey: TapSettingsKeys.SDKApplePayButtonStyle.rawValue)
                UserDefaults.standard.synchronize()
            }
        })
        
        <<< LabelRow(TapSettingsKeys.SDKApplePayRecurring.rawValue, { row in
            row.value = "Adjust apple pay recurring payments"
            row.onCellSelection { cell, row in
                let createApplePayRecurringController = self.storyboard?.instantiateViewController(withIdentifier: "ApplePaySubscriptionDetailsViewController") as! ApplePaySubscriptionDetailsViewController
                self.present(createApplePayRecurringController, animated: true, completion: nil)
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let vieww = view.viewWithTag(2233) {
            view.bringSubviewToFront(vieww)
        }
    }
    
    @IBAction func doneClicked(_ sender: Any) {
        dismiss(animated: true)
    }
    
}



fileprivate enum TapSettingsKeys:String {
    case SDKLanguage
    case SDKMode
    case SDKCloseButton
    
    case SDKSandBoxKey
    case SDKProductionKey
    case SDKBundleID
    case SDKBMerchantID
    case SDKApplePayMerchantID
    
    case SDKULogUI
    case SDKLogApi
    case SDKLogEvents
    case SDKLogConsole
    case SDKLogPlatform
    
    case SDKCardName
    case SDKCardType
    case SDKCardSave
    case SDKCardNameEnabled
    case SDKCardNamePreload
    case SDKCardRequire3DS
    case SDKCardForceLTR
    
    case SDKTransactionMode
    case SDKTransactionCurrency
    case SDKTransactionPaymentTypes
    
    case SDKCustomerType
    case SDKCustomerID
    case SDKCustomerName
    case SDKCustomerPhone
    case SDKCustomerISDN
    case SDKCustomerEmail
    case SDKCustomerShippingAddress
    
    case SDKFeesShipping
    case SDKFeesTax
    
    case SDKApplePayButtonType
    case SDKApplePayButtonStyle
    case SDKApplePayRecurring
}




extension TapFormSettingsViewController {
    
    static func selectedLocale() -> String {
        return (UserDefaults.standard.string(forKey: TapSettingsKeys.SDKLanguage.rawValue) ?? "English").prefix(2).lowercased()
    }
    
    static func sdkMode() -> SDKMode {
        let sdkMode:String = (UserDefaults.standard.object(forKey: TapSettingsKeys.SDKMode.rawValue) as? String) ?? "sandbox"
        
        
        return SDKMode.allCases.first{ $0.description.lowercased() == sdkMode.lowercased() } ?? .sandbox
        
        //return (UserDefaults.standard.object(forKey: TapSettingsKeys.SDKMode.rawValue) as? SDKMode) ?? SDKMode.sandbox
    }
    
    static func showCloseButtonTitle() -> Bool {
        return UserDefaults.standard.bool(forKey: TapSettingsKeys.SDKCloseButton.rawValue)
    }
    
    
    static func loggingCapabilities() -> (Bool,Bool,Bool,Bool,[TapLoggingType]) {
        let SDKULogUI       = UserDefaults.standard.bool(forKey: TapSettingsKeys.SDKULogUI.rawValue)
        let SDKLogApi       = UserDefaults.standard.bool(forKey: TapSettingsKeys.SDKLogApi.rawValue)
        let SDKLogEvents    = UserDefaults.standard.bool(forKey: TapSettingsKeys.SDKLogEvents.rawValue)
        let SDKLogConsole   = UserDefaults.standard.bool(forKey: TapSettingsKeys.SDKLogConsole.rawValue)
        var allowedLogging:[TapLoggingType] = []
        if SDKULogUI {
            allowedLogging.append(.UI)
        }
        if SDKLogApi {
            allowedLogging.append(.API)
        }
        if SDKLogEvents {
            allowedLogging.append(.EVENTS)
        }
        if SDKLogConsole {
            allowedLogging.append(.CONSOLE)
        }
        
        return (SDKULogUI, SDKLogApi, SDKLogEvents, SDKLogConsole, allowedLogging)
    }
    
    
    static func merchantSettings() -> (String, String, String, String, String) {
        let SDKSandBoxKey:String = UserDefaults.standard.string(forKey: TapSettingsKeys.SDKSandBoxKey.rawValue) ?? "sk_test_cvSHaplrPNkJO7dhoUxDYjqA"
        
        let SDKProductionKey:String = UserDefaults.standard.string(forKey: TapSettingsKeys.SDKProductionKey.rawValue) ?? "sk_live_V4UDhitI0r7sFwHCfNB6xMKp"
        
        let SDKBundleID:String = UserDefaults.standard.string(forKey: TapSettingsKeys.SDKBundleID.rawValue) ?? "company.tap.goSellSDKExamplee"
        
        let SDKBMerchantID:String = UserDefaults.standard.string(forKey: TapSettingsKeys.SDKBMerchantID.rawValue) ?? ""
        
        let SDKApplePayMerchantID:String = UserDefaults.standard.string(forKey: TapSettingsKeys.SDKApplePayMerchantID.rawValue) ?? "merchant.tap.gosell"
        
        return (SDKSandBoxKey, SDKProductionKey, SDKBundleID, SDKBMerchantID, SDKApplePayMerchantID)
    }
    
    static func cardSettings() -> (Bool, CardType, SaveCardType, Bool, String, Bool, Bool) {
        
        let SDKCardName:Bool = UserDefaults.standard.bool(forKey: TapSettingsKeys.SDKCardName.rawValue)
        
        let SDKCardType:CardType = CardType(cardTypeString: UserDefaults.standard.string(forKey: TapSettingsKeys.SDKCardType.rawValue) ?? "All")
        
        let SDKCardSave:SaveCardType = .init(stringValue: UserDefaults.standard.string(forKey: TapSettingsKeys.SDKCardSave.rawValue) ?? "All")
        
        let SDKCardNameEnabled:Bool = UserDefaults.standard.bool(forKey: TapSettingsKeys.SDKCardNameEnabled.rawValue)
        
        let SDKCardNamePreload:String = UserDefaults.standard.string(forKey: TapSettingsKeys.SDKCardNamePreload.rawValue) ?? ""
        
        let SDKCardRequire3DS:Bool = UserDefaults.standard.bool(forKey: TapSettingsKeys.SDKCardRequire3DS.rawValue)
        
        let SDKCardForceLTR:Bool = UserDefaults.standard.bool(forKey: TapSettingsKeys.SDKCardForceLTR.rawValue)
        
        return (SDKCardName, SDKCardType, SDKCardSave, SDKCardNameEnabled, SDKCardNamePreload, SDKCardRequire3DS, SDKCardForceLTR)
        
    }
    
    static func transactionSettings() -> (TransactionMode, TapCurrencyCode, TapPaymentType) {
        
        let SDKTransactionMode:TransactionMode = TransactionMode.allCases.first(where: {$0.description == UserDefaults.standard.string(forKey: TapSettingsKeys.SDKTransactionMode.rawValue) ?? "" }) ?? .purchase
        
        let SDKTransactionCurrency:TapCurrencyCode = TapCurrencyCode(appleRawValue: UserDefaults.standard.string(forKey: TapSettingsKeys.SDKTransactionCurrency.rawValue) ?? "KWD") ?? .KWD
        
        
        let SDKTransactionPaymentTypes:TapPaymentType = TapPaymentType(stringValue: UserDefaults.standard.string(forKey: TapSettingsKeys.SDKTransactionPaymentTypes.rawValue) ?? "all")
        
        return (SDKTransactionMode, SDKTransactionCurrency, SDKTransactionPaymentTypes)
        
    }
    
    
    static func customerSettings() -> (SDKCustomerType, String, String, String, String, String, Bool, TapCustomer) {
        
        let SDKCustomerType:SDKCustomerType = SDKCustomerType(rawValue: UserDefaults.standard.string(forKey: TapSettingsKeys.SDKCustomerType.rawValue) ?? "CustomerID") ?? .CustomerID
        
        let SDKCustomerID:String =  UserDefaults.standard.string(forKey: TapSettingsKeys.SDKCustomerID.rawValue) ?? "cus_TS075220212320q2RD0707283"
        
        let SDKCustomerName:String =  UserDefaults.standard.string(forKey: TapSettingsKeys.SDKCustomerName.rawValue) ?? "Tap customer"
        
        var SDKCustomerEmail:String = "tapcustomer@gmail.com"
        if let savedEmail:String = try? TapEmailAddress(emailAddressString: UserDefaults.standard.string(forKey: TapSettingsKeys.SDKCustomerEmail.rawValue) ?? "tapcustomer@gmail.com").value {
            SDKCustomerEmail = savedEmail
        }
        
        let SDKCustomerISDN:String = UserDefaults.standard.string(forKey: TapSettingsKeys.SDKCustomerISDN.rawValue) ?? "965"
        
        let SDKCustomerPhone:String = UserDefaults.standard.string(forKey: TapSettingsKeys.SDKCustomerPhone.rawValue) ?? "90064542"
        
        let SDKCustomerShippingAddress:Bool = UserDefaults.standard.bool(forKey: TapSettingsKeys.SDKCustomerShippingAddress.rawValue)
        
        var customer:TapCustomer = try! .init(identifier: "cus_TS075220212320q2RD0707283")
        
        if SDKCustomerType == .CustomerID {
            if let nonNullCustomer:TapCustomer = try? .init(identifier: SDKCustomerID) {
                customer = nonNullCustomer
            }
        }else{
            let email:TapEmailAddress? = try? .init(emailAddressString: SDKCustomerEmail)
            let phone:TapPhone? = try? .init(isdNumber: SDKCustomerISDN, phoneNumber: SDKCustomerPhone)
            var address:Address?
            if SDKCustomerShippingAddress {
                let tempCountry:CommonDataModelsKit_iOS.Country = try! .init(isoCode: "KW")
                address = .init(type:.residential,
                                country: tempCountry,
                                line1: "Street 13",
                                line2: "Building 4",
                                line3: "Flat 51",
                                city: "Hawally",
                                state: "Kuwait",
                                zipCode: "30003"
                )
            }
            
            if let nonNullCustomer:TapCustomer = try? .init(emailAddress: email, phoneNumber: phone, name: SDKCustomerName, address: address) {
                customer = nonNullCustomer
            }
        }
        return (SDKCustomerType, SDKCustomerID, SDKCustomerName, SDKCustomerEmail, SDKCustomerISDN, SDKCustomerPhone, SDKCustomerShippingAddress, customer)
    }
    
    static func showCustomerID() -> Bool {
        return customerSettings().0.rawValue == SDKCustomerType.CustomerID.rawValue
    }
    
    static func extraFees() -> (Bool, Bool, Shipping?, [Tax]) {
        let SDKFeesShipping:Bool = UserDefaults.standard.bool(forKey: TapSettingsKeys.SDKFeesShipping.rawValue)
        
        let SDKFeesTax:Bool = UserDefaults.standard.bool(forKey: TapSettingsKeys.SDKFeesTax.rawValue)
        
        let tempCountry:CommonDataModelsKit_iOS.Country = try! .init(isoCode: "KW")
        let shipping:Shipping? = SDKFeesShipping ? .init(name: "Shipping", descriptionText: "This is a custom shipping", amount: 10, currency: TapFormSettingsViewController.transactionSettings().1, recipientName: "Tap Payments", address: .init(type:.residential,
                                                                                                                                                                                                                                                    country: tempCountry,
                                                                                                                                                                                                                                                    line1: "Street 13",
                                                                                                                                                                                                                                                    line2: "Building 4",
                                                                                                                                                                                                                                                    line3: "Glat 51",
                                                                                                                                                                                                                                                    city: "Hawally",
                                                                                                                                                                                                                                                    state: "Kuwait",
                                                                                                                                                                                                                                                    zipCode: "30003"
                                                                                                                                                                                                                                                   ), provider: .init(id: "Prov", name: "Aramex")) : nil
        
        let tax:Tax = .init(title: "VAT", amount: .init(type: .Percentage,value: 10))
        
        return (SDKFeesShipping, SDKFeesTax, shipping, SDKFeesTax ? [tax] : [])
    }
    
    static func applePaySettings() -> (TapApplePayButtonType, TapApplePayButtonStyleOutline) {
        
        let SDKApplePayButtonType:TapApplePayButtonType = .init(rawValue: UserDefaults.standard.string(forKey: TapSettingsKeys.SDKApplePayButtonType.rawValue) ?? "plain") ?? .AppleLogoOnly
        
        let SDKApplePayButtonStyle:TapApplePayButtonStyleOutline = .init(rawValue: UserDefaults.standard.string(forKey: TapSettingsKeys.SDKApplePayButtonStyle.rawValue) ?? "auto") ?? .Auto
        
        return (SDKApplePayButtonType, SDKApplePayButtonStyle)
        
    }
    
    static func funcPreFillData () {
        if !UserDefaults.standard.bool(forKey: "SettingsBrefilled2") {
            
            UserDefaults.standard.set(true, forKey: TapSettingsKeys.SDKCardRequire3DS.rawValue)
            UserDefaults.standard.set(true, forKey: TapSettingsKeys.SDKCardNameEnabled.rawValue)
            UserDefaults.standard.set(true, forKey: TapSettingsKeys.SDKLogApi.rawValue)
            UserDefaults.standard.set(true, forKey: TapSettingsKeys.SDKULogUI.rawValue)
            UserDefaults.standard.set(true, forKey: TapSettingsKeys.SDKLogEvents.rawValue)
            UserDefaults.standard.set(true, forKey: TapSettingsKeys.SDKLogConsole.rawValue)
            UserDefaults.standard.set(true, forKey: "SettingsBrefilled2")
            UserDefaults.standard.synchronize()
        }
    }
}


enum SDKCustomerType:String,CaseIterable {
    case CustomerID
    case CustomerInfo
}
