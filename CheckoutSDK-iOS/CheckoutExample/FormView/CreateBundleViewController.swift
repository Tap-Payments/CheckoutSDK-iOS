//
//  CreateBundleViewController.swift
//  CheckoutExample
//
//  Created by Osama Rabie on 07/08/2022.
//

import UIKit
import CheckoutSDK_iOS

class CreateBundleViewController: UIViewController {

    @IBOutlet weak var bundlDTextField: UITextField!
    @IBOutlet weak var liveKeyTextField: UITextField!
    @IBOutlet weak var sandBoxKeyTextField: UITextField!
    @IBOutlet weak var merchantIDTextField: UITextField!
    @IBOutlet weak var loadingActivity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingActivity.stopAnimating()
        reloadData()
        // Do any additional setup after loading the view.
    }
    
    
    func reloadData() {
        
        bundlDTextField.text = UserDefaults.standard.value(forKey: TapSettings.bundleSevedKey) as? String ?? "company.tap.goSellSDKExamplee"
        liveKeyTextField.text = UserDefaults.standard.value(forKey: TapSettings.liveSevedKey) as? String ?? "sk_live_V4UDhitI0r7sFwHCfNB6xMKp"
        sandBoxKeyTextField.text = UserDefaults.standard.value(forKey: TapSettings.sandboxSevedKey) as? String ?? "sk_test_cvSHaplrPNkJO7dhoUxDYjqA"
        merchantIDTextField.text = UserDefaults.standard.value(forKey: TapSettings.merchantIDSevedKey) as? String ?? "599424"
        
        TapCheckout.bundleID = bundlDTextField.text ?? ""
        
        TapCheckout.secretKey = .init(sandbox: sandBoxKeyTextField.text ?? "", production: liveKeyTextField.text ?? "")
    }
    
    @IBAction func resetClicked(_ sender: Any) {
        
        UserDefaults.standard.set("company.tap.goSellSDKExamplee", forKey: TapSettings.bundleSevedKey)
        UserDefaults.standard.set("sk_live_V4UDhitI0r7sFwHCfNB6xMKp", forKey: TapSettings.liveSevedKey)
        UserDefaults.standard.set("sk_test_cvSHaplrPNkJO7dhoUxDYjqA", forKey: TapSettings.sandboxSevedKey)
        UserDefaults.standard.set("599424", forKey: TapSettings.merchantIDSevedKey)
        reloadData()
        
    }
    
    @IBAction func saveClicked(_ sender: Any) {
        
        UserDefaults.standard.set(bundlDTextField.text ?? "company.tap.goSellSDKExamplee", forKey: TapSettings.bundleSevedKey)
        UserDefaults.standard.set(liveKeyTextField.text ?? "sk_live_V4UDhitI0r7sFwHCfNB6xMKp", forKey: TapSettings.liveSevedKey)
        UserDefaults.standard.set(sandBoxKeyTextField.text ?? "sk_test_cvSHaplrPNkJO7dhoUxDYjqA", forKey: TapSettings.sandboxSevedKey)
        UserDefaults.standard.set(merchantIDTextField.text ?? "599424", forKey: TapSettings.merchantIDSevedKey)
        
        reloadData()
        
        dismiss(animated: true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
