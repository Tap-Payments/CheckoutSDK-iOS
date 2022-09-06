//
//  AddItemViewController.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/18/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import UIKit
import CheckoutSDK_iOS

protocol AddItemViewControllerDelegate {
    func addNewItem(with itemModel: ItemModel)
}

class AddItemViewController: FormViewController {
    var delegate: AddItemViewControllerDelegate?
    
    var gender:String? {
        didSet {
            if let cell = self.sections?[2][0], let gender = self.gender {
                (cell as! LinkCell).valueLabel.text = gender
            }
        }
    }

    func createFieldsAndSections()->[[Field]]{
        let titleField = Field(name:"title", title:"Title:", cellType: NameCell.self)
        let descriptionField = Field(name:"description", title:"Description:", cellType: NameCell.self)
        let price = Field(name:"price", title:"Price:", cellType: NumberCell.self)
        let quantity = Field(name:"quantity", title:"Quantity:", cellType: IntCell.self)
        let discount = Field(name:"discount", title:"Discount:", cellType: NumberCell.self)

        let sectionPersonal = [titleField, descriptionField, price, quantity, discount]
        return [sectionPersonal]
    }
    
    lazy var saveButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
    }()
    
    override init(){
        super.init()
        let its = createFieldsAndSections()
        self.fields = its
        self.sections = buildCells(items: its)
        self.selectedRow = { (form:FormViewController,indexPath:IndexPath) in
            let cell = form.tableView.cellForRow(at: indexPath)
            cell?.isSelected = false
        }
    }
    
    override init(config:ConfigureForm){
        super.init(config:config)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Item"
        navigationItem.rightBarButtonItem = saveButton
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @objc func saveTapped(){
        let dic = self.getFormData()
        let titleVal = dic["title"] as? String ?? ""
        let descriptionVal = dic["description"] as? String ?? ""
        let priceVal = Double((dic["price"] as? String ?? "").replacingOccurrences(of: ",", with: "")) ?? 0.0
        let quantityVal = Int((dic["quantity"] as? String ?? "").replacingOccurrences(of: ",", with: "")) ?? 1
        let discountVal = Double((dic["discount"] as? String ?? "").replacingOccurrences(of: ",", with: "")) ?? 0.0
        
        let item = ItemModel(title: titleVal, description: descriptionVal, price: priceVal, quantity: Double(quantityVal), discount: AmountModificatorModel(type: .Fixed, value: discountVal),totalAmount: 0)
        self.delegate?.addNewItem(with: item)
           
        
        dismiss(animated: true, completion: nil)

//        let item = ItemModel(title: titleVal, description: descriptionVal, price: priceVal, quantity: quantityVal, discount: discountVal)
//        let alertController = UIAlertController(title: "Form Data", message: dic.description, preferredStyle: .alert)
//        //We add buttons to the alert controller by creating UIAlertActions:
//        let actionOk = UIAlertAction(title: "OK",
//                                     style: .default,
//                                     handler: nil) //You can use a block here to handle a press on this button
//
//        alertController.addAction(actionOk)
//        self.present(alertController, animated: true, completion: nil)
    }
}
