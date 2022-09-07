//
//  CreateCustomerViewController.swift
//  CheckoutExample
//
//  Created by Osama Rabie on 20/07/2022.
//  Copyright © 2022 Tap Payments. All rights reserved.
//

import UIKit
import CheckoutSDK_iOS
import CommonDataModelsKit_iOS

protocol CreateCustomerDelegate {
    func customerCreated(customer:TapCustomer)
}

class CreateCustomerViewController: UIViewController {

    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var customerIDTextField: UITextField!
    @IBOutlet weak var countryCodeTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var loadingLoader: UIActivityIndicatorView!
    var customerDelegate: CreateCustomerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func createCustomerClicked(_ sender: Any) {
        // to add a customer whether he adds name + (email or phone) or the customer id
        if let customerID = customerIDTextField.text,
           !customerID.isEmpty {
            customerDelegate?.customerCreated(customer: try! .init(identifier: customerID))
            dismiss(animated: true)
        }else if let firstName = firstNameTextField.text {
            do {
                var email:TapEmailAddress? = nil
                var phone:TapPhone? = nil
                if let emailText = emailTextField.text {
                    email = try .init(emailAddressString: emailText)
                }
                if let phoneText = phoneNumberTextField.text, let code = countryCodeTextField.text {
                    phone = try .init(isdNumber: code, phoneNumber: phoneText)
                }
                let tempCountry:Country = try! .init(isoCode: "KW")
                let tempAdddress:Address = .init(type:.residential,
                                                 country: tempCountry,
                                                 line1: "asdasd",
                                                 line2: "sadsadas",
                                                 line3: "2312323",
                                                 city: "Hawally",
                                                 state: "Kuwait",
                                                 zipCode: "30003"
                                                 )
                
                customerDelegate?.customerCreated(customer: try .init(emailAddress: email, phoneNumber: phone, name: firstName, address: tempAdddress))
                dismiss(animated: true)
            }catch {
                if let nonNullerror:TapSDKKnownError = error as? TapSDKKnownError {
                    let uialert:UIAlertController = .init(title: "Error", message: nonNullerror.localizedDescription, preferredStyle: .alert)
                    let okAction:UIAlertAction = .init(title: "OK", style: .cancel)
                    uialert.addAction(okAction)
                    DispatchQueue.main.async { [weak self] in
                        self?.present(uialert, animated: true)
                    }
                }
                
            }
        }
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
