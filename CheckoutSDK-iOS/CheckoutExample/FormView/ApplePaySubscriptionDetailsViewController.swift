//
//  ApplePaySubscriptionDetailsViewController.swift
//  CheckoutExample
//
//  Created by Osama Rabie on 27/12/2022.
//

import UIKit
import Eureka
import PassKit

class ApplePaySubscriptionDetailsViewController: Eureka.FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form +++ Section("Enablement")
        <<< SwitchRow(SettingsKeys.ApplePaySubscriptionEnabled.rawValue, { row in
            row.title = "Enable subscription transaction?"
            row.value = TapSettings.isSubsciption
            row.onChange { switchRow in
                UserDefaults.standard.set(switchRow.value, forKey: TapSettings.isSubsciptionSevedKey)
                UserDefaults.standard.synchronize()
            }
        })
        
        +++ Section("Billing Cycle")
        <<< DateRow(SettingsKeys.ApplePaySubscriptionBillingStartDate.rawValue,{ row in
            row.title = "Start Date"
            row.value = Date(timeIntervalSince1970: TapSettings.applePayBillingStartDate)
            row.minimumDate = Date()
            row.onChange { dateRow in
                UserDefaults.standard.set(dateRow.value?.timeIntervalSince1970 ?? Date().timeIntervalSince1970, forKey: TapSettings.applePayBillingStartDateSevedKey)
                UserDefaults.standard.synchronize()
                
            }
        })
        <<< DateRow(SettingsKeys.ApplePaySubscriptionBillingEndDate.rawValue,{ row in
            row.title = "End Date"
            row.value = Date(timeIntervalSince1970: TapSettings.applePayBillingEndDate)
            row.minimumDate = Date()
            row.onChange { dateRow in
                UserDefaults.standard.set(dateRow.value?.timeIntervalSince1970 ?? Date().timeIntervalSince1970, forKey: TapSettings.applePayBillingEndDateSevedKey)
                UserDefaults.standard.synchronize()
                
            }
        })
        <<< SegmentedRow<String>(SettingsKeys.ApplePaySubscriptionBillingCycle.rawValue, { row in
            row.title = "Billing Cycle"
            row.options = NSCalendar.Unit.getSelectableStrings()
            row.value = TapSettings.applePayBillingCycle.toString()
            row.onChange { segmentRow in
                UserDefaults.standard.set(segmentRow.value ?? "day", forKey: TapSettings.applePayBillingCycleSevedKey)
                
                let startDate:Date = (self.form.rowBy(tag: SettingsKeys.ApplePaySubscriptionBillingStartDate.rawValue) as! DateRow).value ?? Date()
                
                var endDate:Date = startDate.adding(.day, value: 1)
                if segmentRow.value?.lowercased() == "day" {
                    endDate = startDate.adding(.day, value: 1)
                }else if segmentRow.value?.lowercased() == "month" {
                    endDate = startDate.adding(.month, value: 1)
                }else if segmentRow.value?.lowercased() == "year" {
                    endDate = startDate.adding(.year, value: 1)
                }
                
                UserDefaults.standard.set(endDate.timeIntervalSince1970, forKey: TapSettings.applePayBillingEndDateSevedKey)
                UserDefaults.standard.synchronize()
                //self.tableView.reloadData()
                (self.form.rowBy(tag: SettingsKeys.ApplePaySubscriptionBillingEndDate.rawValue) as! DateRow).value = endDate
                (self.form.rowBy(tag: SettingsKeys.ApplePaySubscriptionBillingEndDate.rawValue) as! DateRow).reload()
            }
        })
        
        +++ Section("User information")
        <<< TextRow(SettingsKeys.ApplePaySubscriptionSubscriptionName.rawValue, { row in
            row.title = "Subscription name"
            row.placeholder = "My Subscription"
            row.value = TapSettings.applePaySubscriptionName
            row.onChange { textRow in
                UserDefaults.standard.set(textRow.value ?? "My Subscription", forKey: TapSettings.applePayNameSevedKey)
            }
        })
        
        
        <<< TextRow(SettingsKeys.ApplePaySubscriptionSubscriptionDesc.rawValue, { row in
            row.title = "Subscription description"
            row.placeholder = "My description"
            row.value = TapSettings.applePaySubscriptionDesc
            row.onChange { textRow in
                UserDefaults.standard.set(textRow.value ?? "", forKey: TapSettings.applePayBillingStartDescSevedKey)
            }
        })
        
        <<< TextRow(SettingsKeys.ApplePaySubscriptionSubscriptionBillingAgree.rawValue, { row in
            row.title = "Billing Agreement"
            row.placeholder = "My agreement"
            row.value = TapSettings.applePaySubscriptionBillingAgree
            row.onChange { textRow in
                UserDefaults.standard.set(textRow.value ?? "", forKey: TapSettings.applePaySubscriptionBillingAgreeSevedKey)
            }
        })
    }
}





enum SettingsKeys:String {
    case ApplePaySubscriptionEnabled
    case ApplePaySubscriptionBillingStartDate
    case ApplePaySubscriptionBillingEndDate
    case ApplePaySubscriptionBillingCycle
    case ApplePaySubscriptionSubscriptionName
    case ApplePaySubscriptionSubscriptionBillingAgree
    case ApplePaySubscriptionSubscriptionDesc
    case ApplePaySubscriptionDescription
    case ApplePaySubscriptionAgreement
    case ApplePaySubscriptionManagementURL
}


internal extension NSCalendar.Unit {
    
    func toString() -> String {
        switch self {
        case .day: return "Day"
        case .month: return "Month"
        case .year: return "Year"
        default: return "none"
        }
    }
    
    static func getSelectableStrings() -> [String] {
        let selectedValues:[NSCalendar.Unit] = [.day,.month,.year]
        return selectedValues.map{ $0.toString() }
        
    }
    
    static func from(string:String) -> NSCalendar.Unit {
        if string.lowercased() == "day" {
            return .day
        }
        
        if string.lowercased() == "month" {
            return .month
        }
        
        if string.lowercased() == "year" {
            return .year
        }
        
        return .day
    }
}


public extension Date {
    func noon(using calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    func day(using calendar: Calendar = .current) -> Int {
        calendar.component(.day, from: self)
    }
    func adding(_ component: Calendar.Component, value: Int, using calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: component, value: value, to: self)!
    }
    func monthSymbol(using calendar: Calendar = .current) -> String {
        calendar.monthSymbols[calendar.component(.month, from: self)-1]
    }
}
