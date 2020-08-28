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
    
    private var settingsList: [[String: Any]] = []
    private var tapSettings = TapSettings(language: "English", localisation: false, theme: "Default", currency: .USD, swipeToDismissFeature: false, paymentTypes: [.All])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tapSettings.onChangeBlock = {
            self.fillDataSource()
            self.settingsTableView.reloadData()
        }
        settingsTableView.register(UINib.init(nibName: "LocalisationSwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "LocalisationSwitchTableViewCell")
        self.fillDataSource()
        settingsTableView.reloadData()
    }
    
    func fillDataSource() {
        settingsList.removeAll()
        settingsList.append(["title": "Language",
                             "rows":[["title": "Change Language", "selected":tapSettings.language]], "cellType":""])
        settingsList.append(["title": "Custom Localisation",
                             "rows": [["title": "Show Custom Localization", "selected": tapSettings.localisation]], "cellType":"switch"])
        settingsList.append(["title": "Theme",
                             "rows": [["title": "Change Theme", "selected": tapSettings.theme]], "cellType":""])
        settingsList.append(["title": "Currency",
                             "rows": [["title": "Change Currency", "selected": tapSettings.currency]], "cellType":""])
        settingsList.append(["title": "Swipe to dismiss",
        "rows": [["title": "Enable swipe to dismiss the checkout screen", "selected": tapSettings.swipeToDismissFeature]], "cellType":"switch"])
        settingsList.append(["title": "Pyament Options",
        "rows": [["title": "Select payment options", "selected": tapSettings.paymentTypes]], "cellType":""])
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return settingsList.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return settingsList[section]["title"] as? String
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let rows = settingsList[section]["rows"] as? [[String: Any]] else { return 0 }
        return rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let rows = settingsList[indexPath.section]["rows"] as? [[String: Any]] else { return UITableViewCell() }
        let currentRow = rows[indexPath.row]
        
        if settingsList[indexPath.section]["cellType"] as! String == "switch" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LocalisationSwitchTableViewCell") as! SwitchTableViewCell
            cell.titleLabel.text = currentRow["title"] as? String
            cell.switchButton.isOn = currentRow["selected"] as? Bool ?? false
            cell.indexPath = indexPath
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            cell.textLabel?.text = currentRow["title"] as? String
            let selectedValue = currentRow["selected"]
           switch indexPath.section {
            case 0: // Language
            cell.detailTextLabel?.text = selectedValue as? String
           case 2: // Theme
            cell.detailTextLabel?.text = selectedValue as? String
           case 3: // currency
            cell.detailTextLabel?.text = (selectedValue as? TapCurrencyCode)?.appleRawValue
           case 5:
            var strings: [String] = []
            (selectedValue as? [TapPaymentType])?.forEach{strings.append($0.stringValue)}
            cell.detailTextLabel?.text = strings.joined(separator: ",")
            default: break
            }
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0: showLanguageActionSheet()
        case 2: showThemeActionSheet()
        case 3: showCurrencyActionSheet()
        case 5: showPaypentTypesList()
        default: break
        }
    }
    
}

extension SettingsViewController: SwitchTableViewCellDelegate, MultipleSelectionViewDelegate {
    func switchDidChange(enabled: Bool, at indexPath: IndexPath?) {
        let text = enabled ? "enabled" : "disabled"
        print("indexPath?.section: \(String(describing: indexPath?.section)) -- enabled \(text)")
        switch indexPath?.section {
        case 1:
            self.delegate?.didUpdateLocalisation(to: enabled)
        case 4:
            self.delegate?.didUpdateSwipeToDismiss(to: enabled)
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
        [.USD,.AED,.KWD,.BHD,.QAR,.SAR,.OMR,.EGP,.JOD].forEach { (currency) in
            currencyActionSheet.addAction(UIAlertAction(title: "\(currency.appleRawValue)", style: .default) { [weak self] _ in
//                self?.tapSettings.currency = currency
                self?.delegate?.didChangeCurrency(with: currency)
            })
        }
        
        self.present(currencyActionSheet, animated: true, completion: nil)
    }
}
