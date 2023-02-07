//
//  CreateLoyaltyViewController.swift
//  CheckoutExample
//
//  Created by Osama Rabie on 18/09/2022.
//

import UIKit
import TapUIKit_iOS
import CommonDataModelsKit_iOS
import CheckoutSDK_iOS

class CreateLoyaltyViewController: UIViewController {

    @IBOutlet weak var programNameTextField: UITextField!
    @IBOutlet weak var pointsNameTextField: UITextField!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var bankBinTextField: UITextField!
    @IBOutlet weak var logoTextField: UITextField!
    @IBOutlet weak var mainCurrencyButton: UIButton!
    @IBOutlet weak var balanceTextField: UITextField!
    @IBOutlet weak var minTextField: UITextField!
    @IBOutlet weak var supportedCurrenciesTableView: UITableView!
    
    var supportedCurrencies:[TapCurrencyCode] = [.AED,.KWD,.EGP]
    
    var loyaltyViewModel:TapLoyaltyViewModel = TapLoyaltyViewModel.init(loyaltyModel: .init(id: "", bankName: "ADCB", bankLogo: "https://is1-ssl.mzstatic.com/image/thumb/Purple126/v4/78/00/ed/7800edd0-5854-b6ce-458f-dfcf75caa495/AppIcon-0-0-1x_U007emarketing-0-0-0-5-0-0-sRGB-0-0-0-GLES2_U002c0-512MB-85-220-0-0.png/1024x1024.jpg", loyaltyProgramName: "ADCB TouchPoints", loyaltyPointsName: "TouchPoints", termsConditionsLink: "https://www.adcb.com/en/personal/adcb-for-you/touchpoints/touchpoints-rewards.aspx", supportedCurrencies: [.init(currency: AmountedCurrency.init(.AED, 200, "", 2, 50), balanceAmount: 1000, minimumAmount: 100),.init(currency: AmountedCurrency.init(.EGP, 1000, "", 2, 10), balanceAmount: 5000, minimumAmount: 500)], transactionsCount: "25.000"), transactionTotalAmount:200, currency: .AED)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logoTextField.text = "https://is1-ssl.mzstatic.com/image/thumb/Purple126/v4/78/00/ed/7800edd0-5854-b6ce-458f-dfcf75caa495/AppIcon-0-0-1x_U007emarketing-0-0-0-5-0-0-sRGB-0-0-0-GLES2_U002c0-512MB-85-220-0-0.png/1024x1024.jpg"
        programNameTextField.text = "ADCB TouchPoints"
        bankBinTextField.text = "ADCB"
        programNameTextField.text = "ADCB TouchPoints"
        pointsNameTextField.text = "TouchPoints"
        mainCurrencyButton.setTitle("AED", for: .normal)
        balanceTextField.text = "1000"
        minTextField.text = "100"
        
        supportedCurrenciesTableView.dataSource = self
        supportedCurrenciesTableView.delegate = self
        supportedCurrenciesTableView.reloadData()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func saveClicked(_ sender: Any) {
    }
    @IBAction func resetClicked(_ sender: Any) {
    }
    
    /*
     @IBAction func mainCurrencyClicked(_ sender: Any) {
     }
     // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
     
     */
    @IBAction func enableLoyaltySwitchChanged(_ sender: Any) {
        TapCheckout.loyaltyEnabled = (sender as! UISwitch ).isOn
    }
}


extension CreateLoyaltyViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Supported Currencies"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        supportedCurrencies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "CreateLoyaltyViewControllerCurrencyCell", for: indexPath)
        
        cell.textLabel?.text = supportedCurrencies[indexPath.row].appleRawValue
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
}
