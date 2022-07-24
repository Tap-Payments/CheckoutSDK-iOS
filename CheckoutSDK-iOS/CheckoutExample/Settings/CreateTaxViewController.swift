//
//  CreateTaxViewController.swift
//  CheckoutExample
//
//  Created by Osama Rabie on 24/07/2022.
//  Copyright © 2022 Tap Payments. All rights reserved.
//

import UIKit
import CommonDataModelsKit_iOS

protocol CreateTaxViewControllerDelegate {
    func taxAdded(with tax:Tax)
}

class CreateTaxViewController: UIViewController {

    @IBOutlet weak var taxNameTextField: UITextField!
    @IBOutlet weak var textDescTextField: UITextField!
    @IBOutlet weak var taxTypeSegment: UISegmentedControl!
    @IBOutlet weak var taxValueSlider: UISlider!
    @IBOutlet weak var taxValueLabel: UILabel!
    @IBOutlet weak var addTaxButton: UIButton!
    var delegate:CreateTaxViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initUI()
    }
    
    private func initUI() {
        taxNameTextField.becomeFirstResponder()
        adjustTaxSlider()
        taxNameTextField.delegate = self
        textDescTextField.delegate = self
    }
    
    
    private func adjustTaxSlider() {
        taxValueSlider.value = 0
        if taxTypeSegment.selectedSegmentIndex == 0
        {
            taxValueLabel.text = "0"
            taxValueSlider.minimumValue = 0
            taxValueSlider.maximumValue = 50
        }else{
            taxValueLabel.text = "0%"
            taxValueSlider.minimumValue = 0
            taxValueSlider.maximumValue = 100
        }
    }

    @IBAction func addTaxButtonClicked(_ sender: Any) {
        // Make sure we have the needed values for a tax :)
        guard let taxName:String = taxNameTextField.text,
              !taxName.isEmpty,
              taxValueSlider.value >= 1 else {
            self.showToast(message: "To add a tax you need to add a name and a value >= 1", font: .systemFont(ofSize: 12.0))
            return
        }
        
        // let us create the tax object
        let tax:Tax = .init(title: taxName, descriptionText: textDescTextField.text, amount: .init(type: (taxTypeSegment.selectedSegmentIndex == 0) ? .Fixed : .Percentage, value: round(Double(taxValueSlider.value))))
        
        // Pass back the tax
        dismiss(animated: true) { [weak self] in
            self?.delegate?.taxAdded(with: tax)
        }
    }
    @IBAction func taxTypeSwitchChanged(_ sender: Any) {
        adjustTaxSlider()
    }
    @IBAction func taxValueSliderChanged(_ sender: Any) {
        //let step: Float = (taxTypeSegment.selectedSegmentIndex == 0) ? 1 : 0.5
        let currentValue = round(taxValueSlider.value)
        taxValueLabel.text = "\(currentValue)"
        if taxTypeSegment.selectedSegmentIndex == 1 {
            taxValueLabel.text = "\(taxValueLabel.text ?? "") %"
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

extension CreateTaxViewController:UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}


extension UIViewController {
    
    func showToast(message : String, font: UIFont) {
        
        let toastLabel = UILabel(frame: CGRect(x: 20, y: self.view.frame.size.height-100, width: self.view.frame.size.width - 20, height: 50))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.numberOfLines = 0
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    } }
