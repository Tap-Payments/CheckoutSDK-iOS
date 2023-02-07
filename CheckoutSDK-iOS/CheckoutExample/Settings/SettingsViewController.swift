//
//  SettingsViewController.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/12/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import UIKit
import CheckoutSDK_iOS
import CommonDataModelsKit_iOS
import TapUIKit_iOS

class SettingsViewController: UIViewController {

    @IBOutlet weak var settingsTableView: UITableView!
    
    /// The delegate used to fire events to the caller view
    public var delegate: SettingsDelegate?
    
    private var settingsList: [SettingsSectionEnum] = []
    private var tapSettings = TapSettings(localisation: false, theme: "Default", currency: .KWD, swipeToDismissFeature: true, paymentTypes: [.All],closeButtonTitleFeature: true, customer: try! .init(identifier: "cus_TS075220212320q2RD0707283"), transactionMode: .purchase, addShippingFeature: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tapSettings.load()
        tapSettings.onChangeBlock = {
            self.refillTableView()
        }
        settingsTableView.register(UINib.init(nibName: "LocalisationSwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "LocalisationSwitchTableViewCell")
        self.refillTableView()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //tapSettings.updateSavedData()
    }
    
    private func refillTableView() {
        self.fillDataSource()
        self.settingsTableView.reloadData()
    }
    
    func fillDataSource() {
        settingsList.removeAll()
        settingsList.append(.Language)
        settingsList.append(.SDKMode)
        settingsList.append(.Localisation)
        settingsList.append(.TransactionMode)
        settingsList.append(.Theme)
        settingsList.append(.Currency)
        settingsList.append(.SwipeToDismiss)
        settingsList.append(.AddShipping)
        settingsList.append(.CloseButtonTitle)
        settingsList.append(.PyamentOptions)
        settingsList.append(.CreditCardName)
        settingsList.append(.CreditSaveCardName)
        settingsList.append(.Customer)
        settingsList.append(.Bundle)
        settingsList.append(.Loyalty)
        settingsList.append(.ApplePayRecurring)
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
            case .AddShipping: cell.switchButton.isOn = tapSettings.addShipingFeature
            case .CreditCardName: cell.switchButton.isOn = tapSettings.creditNameFeature
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
            case .Language: cell.detailTextLabel?.text = TapSettings.language
            case .SDKMode: cell.detailTextLabel?.text = TapSettings.sdkMode.description
            case .Theme: cell.detailTextLabel?.text = tapSettings.theme
            case .Currency: cell.detailTextLabel?.text = tapSettings.currency.appleRawValue
            case .PyamentOptions:
                var strings: [String] = []
                tapSettings.paymentTypes.forEach{strings.append($0.stringValue)}
                cell.detailTextLabel?.text = strings.joined(separator: ",")
            case .Customer:
                cell.detailTextLabel?.text = getCustomerName()
            case .Bundle:
                cell.detailTextLabel?.text = "Set your bundle id + tap keys"
            case .ApplePayRecurring:
                cell.detailTextLabel?.text = "Set apple pay recurring details if needed"
            case .Loyalty:
                cell.detailTextLabel?.text = "Set a loyalty point redemption program"
            case .TransactionMode:
                cell.detailTextLabel?.text = tapSettings.transactionMode.description
            case .CreditSaveCardName:
                cell.detailTextLabel?.text = TapSettings.saveCardFeature.toString()
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
        case .SDKMode: showSDKModeActionSheet()
        case .Theme: showThemeActionSheet()
        case .Currency: showCurrencyActionSheet()
        case .PyamentOptions: showPaypentTypesList()
        case .CreditSaveCardName: showSaveCardType()
        case .Customer: showCustomerDetails()
        case .Bundle: showBundleDetails()
        case .Loyalty: showLoyaltyDetails()
        case .TransactionMode: showTransactionTypesList()
        case .ApplePayRecurring: showApplePayRecurring()
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
        case .AddShipping:
            self.delegate?.didUpdateAddShipping(to: enabled)
        case .CreditCardName:
            UserDefaults.standard.set(enabled, forKey: TapSettings.creditNameFeatureSevedKey)
            self.delegate?.didUpdateCredCardName(to: enabled)
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
    
    func showTransactionTypesList() {
        //Create the AlertController and add Its action like button in Actionsheet
        let transactionModeActionSheet = UIAlertController(title: nil, message: "Select a mode", preferredStyle: .actionSheet)
        
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel)
        transactionModeActionSheet.addAction(cancelActionButton)
        
        TransactionMode.allCases.forEach { trxMode in
            transactionModeActionSheet.addAction(UIAlertAction(title: trxMode.description, style: .default, handler: { [weak self] _ in
                self?.tapSettings.transactionMode = trxMode
                self?.delegate?.didUpdateTransactionMode(to: trxMode)
            }))
        }
        self.present(transactionModeActionSheet, animated: true, completion: nil)
    }
    
    
    func showBundleDetails() {
        let createBundleViewController = self.storyboard?.instantiateViewController(withIdentifier: "CreateBundleViewController") as! CreateBundleViewController
        self.present(createBundleViewController, animated: true, completion: nil)
    }
    
    
    func showApplePayRecurring() {
        let createApplePayRecurringController = self.storyboard?.instantiateViewController(withIdentifier: "ApplePaySubscriptionDetailsViewController") as! ApplePaySubscriptionDetailsViewController
        self.present(createApplePayRecurringController, animated: true, completion: nil)
    }
    
    func showLoyaltyDetails() {
        let createLoyaltyViewController = self.storyboard?.instantiateViewController(withIdentifier: "CreateLoyaltyViewController") as! CreateLoyaltyViewController
        self.present(createLoyaltyViewController, animated: true, completion: nil)
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
        
        ["Arabic","English"].forEach { language in
            languageActionSheet.addAction(UIAlertAction(title: language, style: .default, handler: { _ in
                UserDefaults.standard.set(String(language!.lowercased().prefix(2)).lowercased(), forKey: TapSettings.localIDSevedKey)
                UserDefaults.standard.synchronize()
                self.delegate?.didUpdateLanguage(with: TapSettings.language)
                self.settingsTableView.reloadData()
            }))
        }
        self.present(languageActionSheet, animated: true, completion: nil)
    }
    
    
    func showSDKModeActionSheet() {
        //Create the AlertController and add Its action like button in Actionsheet
        let languageActionSheet = UIAlertController(title: nil, message: "Select SDK mode", preferredStyle: .actionSheet)
        
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel)
        languageActionSheet.addAction(cancelActionButton)
        
        languageActionSheet.addAction(.init(title: "sandbox", style: .default, handler: { _ in
            UserDefaults.standard.set(SDKMode.sandbox.rawValue,forKey: TapSettings.sdkModeSevedKey)
            self.settingsTableView.reloadData()
        }))
        
        languageActionSheet.addAction(.init(title: "production", style: .default, handler: { _ in
            UserDefaults.standard.set(SDKMode.production.rawValue,forKey: TapSettings.sdkModeSevedKey)
            self.settingsTableView.reloadData()
        }))
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
    func showSaveCardType() {
        //Create the AlertController and add Its action like button in Actionsheet
        let saveCardActionSheet = UIAlertController(title: nil, message: "Select Save cards options", preferredStyle: .actionSheet)
        SaveCardType.allCases.forEach { (saveCardType) in
            saveCardActionSheet.addAction(UIAlertAction(title: "\(saveCardType.toString())", style: .default) { [weak self] _ in
                UserDefaults.standard.set(saveCardType.toString(), forKey: TapSettings.saveCardFeatureSevedKey)
                self?.delegate?.didUpdateCredCardSave(to: saveCardType)
                self?.settingsTableView.reloadData()
            })
        }
        
        self.present(saveCardActionSheet, animated: true, completion: nil)
    }
    
    
}


extension SettingsViewController: CreateCustomerDelegate {
    func customerCreated(customer: TapCustomer) {
        tapSettings.customer = customer
        self.delegate?.didChangeCustomer(with: customer)
    }
    
    
}
