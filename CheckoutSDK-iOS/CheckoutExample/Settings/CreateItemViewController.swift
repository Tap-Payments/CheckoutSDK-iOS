//
//  CreateItemViewController.swift
//  CheckoutExample
//
//  Created by Osama Rabie on 24/07/2022.
//  Copyright © 2022 Tap Payments. All rights reserved.
//

import UIKit
import CommonDataModelsKit_iOS


protocol CreateItemViewControllerDelegate
{
    func itemAdded(with item:ItemModel)
}


class CreateItemViewController: UIViewController {

    @IBOutlet weak var itemNameTextField: UITextField!
    @IBOutlet weak var itemDescTextField: UITextField!
    @IBOutlet weak var quantitySlider: UISlider!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var itemPriceSlider: UISlider!
    @IBOutlet weak var itemPriceLabel: UILabel!
    var tax:[Tax] = []
    @IBOutlet weak var discountSegment: UISegmentedControl!
    @IBOutlet weak var taxLabel: UILabel!
    @IBOutlet weak var discountSlider: UISlider!
    @IBOutlet weak var discountLabel: UILabel!
    var delegate:CreateItemViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        // Do any additional setup after loading the view.
        initUI()
    }
    
    
    func initUI() {
        itemNameTextField.delegate = self
        itemDescTextField.delegate = self
        adjustDiscountSlider()
    }
    
    
    private func adjustDiscountSlider() {
        discountSlider.value = 1
        discountSlider.isEnabled = true
        if discountSegment.selectedSegmentIndex == 0
        {
            discountLabel.text = "0"
            discountSlider.minimumValue = 1
            discountSlider.maximumValue = itemPriceSlider.value - 1
        }else if discountSegment.selectedSegmentIndex == 1 {
            discountLabel.text = "0%"
            discountSlider.minimumValue = 1
            discountSlider.maximumValue = 99
        }else{
            discountLabel.text = "0"
            discountSlider.isEnabled = false
        }
    }
    
    func updateTax() {
        taxLabel.text = "Tax (\(tax.count)) :"
    }
    
    @IBAction func priceSliderChanged(_ sender: Any) {
        let currentValue = round(itemPriceSlider.value)
        itemPriceLabel.text = "\(currentValue)"
        adjustDiscountSlider()
    }
    
    @IBAction func addTaxClicked(_ sender: Any) {
        let viewController:CreateTaxViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CreateTaxViewController") as! CreateTaxViewController
        viewController.delegate = self
        present(viewController, animated: true)

    }
    
    
    @IBAction func addItemClicked(_ sender: Any) {
        // Make sure all what we need is added
        guard let itemName:String = itemNameTextField.text,
              !itemName.isEmpty, itemName.count >= 3 else {
            showToast(message: "Item name should be 3+ charachters ", font: .systemFont(ofSize: 15))
            return
        }
        let priceValue = round(itemPriceSlider.value)
        let quntityValue = round(quantitySlider.value)
        let discValue = round(discountSlider.value)
        
        var discountModel:AmountModificatorModel? = nil
        if discountSegment.selectedSegmentIndex != 2 {
            discountModel = .init(type: (discountSegment.selectedSegmentIndex == 0) ? .Fixed : .Percentage, value: Double(discValue))
        }
        
        let item:ItemModel = .init(title: itemName, description: itemDescTextField.text, price: Double(priceValue), quantity: .init(value: Double(quntityValue), unitOfMeasurement: .units), discount: discountModel, taxes: tax, totalAmount: 0)
        
        saveItem(item: item)
        delegate?.itemAdded(with: item)
        
        dismiss(animated: true)
    }
    
    func saveItem(item: ItemModel) {
        var items:[ItemModel] = []
        
        if let data = UserDefaults.standard.value(forKey:TapSettings.itemsSaveKey) as? Data {
            do {
                items = try PropertyListDecoder().decode([ItemModel].self, from: data)
            } catch {
                print("error paymentTypes: \(error.localizedDescription)")
            }
        }
        
        items.append(item)
        UserDefaults.standard.set(try! PropertyListEncoder().encode(items), forKey: TapSettings.itemsSaveKey)
        UserDefaults.standard.synchronize()
        
    }
    
    @IBAction func quantitySliderChanged(_ sender: Any) {
        let currentValue = round(quantitySlider.value)
        quantityLabel.text = "\(currentValue)"
    }
    
    @IBAction func discountSegmentChanged(_ sender: Any) {
        adjustDiscountSlider()
    }
    @IBAction func discountSliderChanged(_ sender: Any) {
        let currentValue = round(discountSlider.value)
        discountLabel.text = "\(currentValue)"
        if discountSegment.selectedSegmentIndex == 1 {
            discountLabel.text = "\(discountLabel.text ?? "") %"
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

extension CreateItemViewController: UITextFieldDelegate, CreateTaxViewControllerDelegate {
    func taxAdded(with tax: Tax) {
        self.tax.append(tax)
        updateTax()
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
