//
//  SettingsViewController.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/12/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var settingsTableView: UITableView!
    
    /// The delegate used to fire events to the caller view
    @objc public var delegate: LocalisationSettingsDelegate?
    
    private var settingsList: [[String: Any]] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        settingsTableView.register(UINib.init(nibName: "LocalisationSwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "LocalisationSwitchTableViewCell")
        settingsList.append(["title": "Language", "rows":["Change Language"], "cellType":""])
        settingsList.append(["title": "Custom Localisation", "rows": ["Show Custom Localization"], "cellType":"switch"])
        settingsList.append(["title": "Theme", "rows": ["Change Theme"], "cellType":""])
        settingsList.append(["title": "Currency", "rows": ["Change Currency"], "cellType":""])
        settingsTableView.reloadData()
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
        guard let rows = settingsList[section]["rows"] as? [String] else { return 0 }
        return rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let rows = settingsList[indexPath.section]["rows"] as? [String] else { return UITableViewCell() }
        if settingsList[indexPath.section]["cellType"] as! String == "switch" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LocalisationSwitchTableViewCell") as! LocalisationSwitchTableViewCell
            cell.titleLabel.text = rows[indexPath.row]
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            cell.textLabel?.text = rows[indexPath.row]
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0: showLanguageActionSheet()
        case 2: showThemeActionSheet()
        case 3: showCurrencyActionSheet()
        default: break
        }
    }
    
}

extension SettingsViewController: LocalisationSwitchTableViewCellDelegate {
    func switchDidChange(enabled: Bool) {
        let text = enabled ? "enabled" : "disabled"
        print("localisation \(text)")
    }
}

extension SettingsViewController  {
    
    // MARK: Language Selection
    func showLanguageActionSheet() {
         //Create the AlertController and add Its action like button in Actionsheet
        let languageActionSheet = UIAlertController(title: nil, message: "Select language", preferredStyle: .actionSheet)
       
        let cancelActionButton = UIAlertAction(title: "Cancel", style: .cancel)
        languageActionSheet.addAction(cancelActionButton)
        
        let arabicActionButton = UIAlertAction(title: "Arabic", style: .default) { _ in
            self.delegate?.didUpdateLanguage(with: "ar")
        }
        
        languageActionSheet.addAction(arabicActionButton)

        let englishActionButton = UIAlertAction(title: "English", style: .default) { _ in
            self.delegate?.didUpdateLanguage(with: "en")
        }
        languageActionSheet.addAction(englishActionButton)

        let frenchActionButton = UIAlertAction(title: "French", style: .default) { _ in
            self.delegate?.didUpdateLanguage(with: "fr")
        }
        languageActionSheet.addAction(frenchActionButton)
        let hindiActionButton = UIAlertAction(title: "Hindi", style: .default) { _ in
            self.delegate?.didUpdateLanguage(with: "hi")
        }
        languageActionSheet.addAction(hindiActionButton)
        self.present(languageActionSheet, animated: true, completion: nil)
    }
    
    func showThemeActionSheet() {
         //Create the AlertController and add Its action like button in Actionsheet
        let themeActionSheet = UIAlertController(title: nil, message: "Select Theme", preferredStyle: .actionSheet)
       
        let defaultActionButton = UIAlertAction(title: "Default", style: .default) { _ in
            self.delegate?.didChangeTheme(with: .none)
        }
        themeActionSheet.addAction(defaultActionButton)
        
        let redActionButton = UIAlertAction(title: "Custom Red", style: .default) { _ in
            self.delegate?.didChangeTheme(with: "Red")
        }
        themeActionSheet.addAction(redActionButton)

        let greenActionButton = UIAlertAction(title: "Custom Green", style: .default) { _ in
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
       
        let usdActionButton = UIAlertAction(title: "USD", style: .default) { _ in
            self.delegate?.didChangeCurrency(with: "USD")
        }
        currencyActionSheet.addAction(usdActionButton)
        
        let aedActionButton = UIAlertAction(title: "AED", style: .default) { _ in
            self.delegate?.didChangeCurrency(with: "AED")
        }
        currencyActionSheet.addAction(aedActionButton)
        
        let sarActionButton = UIAlertAction(title: "SAR", style: .default) { _ in
            self.delegate?.didChangeCurrency(with: "SAR")
        }
        currencyActionSheet.addAction(sarActionButton)
        
        let kwdActionButton = UIAlertAction(title: "KWD", style: .default) { _ in
            self.delegate?.didChangeCurrency(with: "KWD")
        }
        currencyActionSheet.addAction(kwdActionButton)
        
        let bhdActionButton = UIAlertAction(title: "BHD", style: .default) { _ in
            self.delegate?.didChangeCurrency(with: "BHD")
        }
        currencyActionSheet.addAction(bhdActionButton)
        
        let qarActionButton = UIAlertAction(title: "QAR", style: .default) { _ in
            self.delegate?.didChangeCurrency(with: "QAR")
        }
        currencyActionSheet.addAction(qarActionButton)
        
        let omrActionButton = UIAlertAction(title: "OMR", style: .default) { _ in
            self.delegate?.didChangeCurrency(with: "OMR")
        }
        currencyActionSheet.addAction(omrActionButton)
        
        let egpActionButton = UIAlertAction(title: "EGP", style: .default) { _ in
            self.delegate?.didChangeCurrency(with: "EGP")
        }
        currencyActionSheet.addAction(egpActionButton)
        
        let jodActionButton = UIAlertAction(title: "JOD", style: .default) { _ in
            self.delegate?.didChangeCurrency(with: "JOD")
        }
        currencyActionSheet.addAction(jodActionButton)
        
        
        self.present(currencyActionSheet, animated: true, completion: nil)
    }
}
