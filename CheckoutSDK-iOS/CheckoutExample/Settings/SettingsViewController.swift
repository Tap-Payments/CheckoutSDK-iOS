//
//  SettingsViewController.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/12/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import UIKit
import CheckoutSDK_iOS

class SettingsViewController: UIViewController {

    @IBOutlet weak var settingsTableView: UITableView!
    
    /// The delegate used to fire events to the caller view
    public var delegate: SettingsDelegate?
    
    private var settingsList: [SettingsSectionEnum] = []
    private var tapSettings = TapSettings(language: "English", localisation: false, theme: "Default", currency: .USD, swipeToDismissFeature: true, paymentTypes: [.All],closeButtonTitleFeature: true, customer: try! .init(identifier: "cus_TS075220212320q2RD0707283"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tapSettings.load()
        tapSettings.onChangeBlock = {
            self.refillTableView()
        }
        settingsTableView.register(UINib.init(nibName: "LocalisationSwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "LocalisationSwitchTableViewCell")
        self.refillTableView()
    }
    
    private func refillTableView() {
        self.fillDataSource()
        self.settingsTableView.reloadData()
    }
    
    func fillDataSource() {
        settingsList.removeAll()
        settingsList.append(.Language)
        settingsList.append(.Localisation)
        settingsList.append(.Theme)
        settingsList.append(.Currency)
        settingsList.append(.SwipeToDismiss)
        settingsList.append(.CloseButtonTitle)
        settingsList.append(.PyamentOptions)
        settingsList.append(.Customer)
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: TableView DataSource / Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return settingsList.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return settingsList[section].title
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsList[section].rowsTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let currentsection = settingsList[indexPath.section]
        if currentsection.cellType == .SwitchButton {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LocalisationSwitchTableViewCell") as! SwitchTableViewCell
            cell.titleLabel.text = currentsection.rowsTitles[indexPath.row]
            switch currentsection {
            case .Localisation: cell.switchButton.isOn = tapSettings.localisation
            case .SwipeToDismiss: cell.switchButton.isOn = tapSettings.swipeToDismissFeature
            case .CloseButtonTitle: cell.switchButton.isOn = tapSettings.closeButtonTitleFeature
            default: break
            }
            cell.indexPath = indexPath
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            cell.textLabel?.text = currentsection.rowsTitles[indexPath.row]
            switch currentsection {
            case .Language: cell.detailTextLabel?.text = tapSettings.language
            case .Theme: cell.detailTextLabel?.text = tapSettings.theme
            case .Currency: cell.detailTextLabel?.text = tapSettings.currency.appleRawValue
            case .PyamentOptions:
                var strings: [String] = []
                tapSettings.paymentTypes.forEach{strings.append($0.stringValue)}
                cell.detailTextLabel?.text = strings.joined(separator: ",")
            case .Customer:
                cell.detailTextLabel?.text = getCustomerName()
            default: break
            }
            return cell
        }
    }
    
    func getCustomerName() -> String {
        if let name = tapSettings.customer.firstName {
            return name
        }
        
        if let id = tapSettings.customer.identifier {
            return "ID : \(id)"
        }
        
        return "Using default customer."
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let settingSection = SettingsSectionEnum(rawValue: indexPath.section)! as SettingsSectionEnum
        switch settingSection {
        case .Language: showLanguageActionSheet()
        case .Theme: showThemeActionSheet()
        case .Currency: showCurrencyActionSheet()
        case .PyamentOptions: showPaypentTypesList()
        case .Customer: showCustomerDetails()
        default: break
        }
    }
    
}

extension SettingsViewController: SwitchTableViewCellDelegate, MultipleSelectionViewDelegate {
    func switchDidChange(enabled: Bool, at indexPath: IndexPath?) {
        let text = enabled ? "enabled" : "disabled"
        print("indexPath?.section: \(String(describing: indexPath?.section)) -- enabled \(text)")
        let settingSection = SettingsSectionEnum(rawValue: indexPath?.section ?? 0)! as SettingsSectionEnum

        switch settingSection {
        case .Localisation:
            tapSettings.localisation = enabled
            self.delegate?.didUpdateLocalisation(to: enabled)
        case .SwipeToDismiss:
            self.delegate?.didUpdateSwipeToDismiss(to: enabled)
        case .CloseButtonTitle:
            self.delegate?.didUpdateCloseButtonTitle(to: enabled)
        default: break
        }
    }
    func didUpdatePaymentTypes(paymentTypes: [TapPaymentType]) {
        tapSettings.paymentTypes = paymentTypes
        delegate?.didUpdatePaymentTypes(to: paymentTypes)
    }
    
}

extension SettingsViewController  {
    // MARK: Multiple Selection List
    func showPaypentTypesList() {
        let multipleOptionsVC = self.storyboard?.instantiateViewController(withIdentifier: "MultipleSelectionViewController") as! MultipleSelectionViewController
        multipleOptionsVC.options = [.All,.Web,.Card,.Telecom,.ApplePay]
        multipleOptionsVC.selectedOptions = tapSettings.paymentTypes
        multipleOptionsVC.delegate = self
        self.present(multipleOptionsVC, animated: true, completion: nil)
    }
    
    func showCustomerDetails() {
        let createCustomerViewController = self.storyboard?.instantiateViewController(withIdentifier: "CreateCustomerViewController") as! CreateCustomerViewController
        createCustomerViewController.customerDelegate = self
        self.present(createCustomerViewController, animated: true, completion: nil)
    }
    
    // MARK: Language Selection
    func showLanguageActionSheet() {
         //Create the AlertController and add Its action like button in Actionsheet
        let languageActionSheet = UIAlertController(title: nil, message: "Select language", preferredStyle: .actionSheet)
       
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel)
        languageActionSheet.addAction(cancelActionButton)
        
        ["Arabic","English","French","Hindi"].forEach { language in
            languageActionSheet.addAction(UIAlertAction(title: language, style: .default, handler: { [weak self] _ in
                self?.tapSettings.language = language!
                self?.delegate?.didUpdateLanguage(with: String(language!.lowercased().prefix(2)))
            }))
        }
        self.present(languageActionSheet, animated: true, completion: nil)
    }
    
    func showThemeActionSheet() {
         //Create the AlertController and add Its action like button in Actionsheet
        let themeActionSheet = UIAlertController(title: nil, message: "Select Theme", preferredStyle: .actionSheet)
       
        let defaultActionButton = UIAlertAction(title: "Default", style: .default) { _ in
            self.tapSettings.theme = "Default"
            self.delegate?.didChangeTheme(with: .none)
        }
        themeActionSheet.addAction(defaultActionButton)
        
        let redActionButton = UIAlertAction(title: "Custom Red", style: .default) { _ in
            self.tapSettings.theme = "Custom Red"
            self.delegate?.didChangeTheme(with: "Red")
        }
        themeActionSheet.addAction(redActionButton)

        let greenActionButton = UIAlertAction(title: "Custom Green", style: .default) { _ in
            self.tapSettings.theme = "Custom Green"
            self.delegate?.didChangeTheme(with: "Green")
        }
        themeActionSheet.addAction(greenActionButton)

        /*let blueActionButton = UIAlertAction(title: "Custom Blue", style: .default) { _ in
            self.delegate?.didChangeTheme(with: "Blue")
        }
        themeActionSheet.addAction(blueActionButton)*/
        self.present(themeActionSheet, animated: true, completion: nil)
    }
    
    func showCurrencyActionSheet() {
         //Create the AlertController and add Its action like button in Actionsheet
        let currencyActionSheet = UIAlertController(title: nil, message: "Select Currency", preferredStyle: .actionSheet)
        let supportedCurrencies:[TapCurrencyCode] = [.USD,.AED,.KWD,.BHD,.QAR,.SAR,.OMR,.EGP,.JOD]
        supportedCurrencies.forEach { (currency) in
            currencyActionSheet.addAction(UIAlertAction(title: "\(currency.appleRawValue)", style: .default) { [weak self] _ in
                self?.tapSettings.currency = currency
                self?.delegate?.didChangeCurrency(with: currency)
            })
        }
        
        self.present(currencyActionSheet, animated: true, completion: nil)
    }
}


extension SettingsViewController: CreateCustomerDelegate {
    func customerCreated(customer: TapCustomer) {
        tapSettings.customer = customer
        self.delegate?.didChangeCustomer(with: customer)
    }
    
    
}
