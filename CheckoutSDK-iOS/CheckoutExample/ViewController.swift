//
//  ViewController.swift
//  CheckoutExample
//
//  Created by Osama Rabie on 7/31/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import UIKit
import CheckoutSDK_iOS

class ViewController: UIViewController {
   
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func startSDKClicked(_ sender: Any) {
        let checkout:TapCheckout = .init()
        present(checkout.startCheckoutSDK(), animated: true, completion: nil)
    }
}
