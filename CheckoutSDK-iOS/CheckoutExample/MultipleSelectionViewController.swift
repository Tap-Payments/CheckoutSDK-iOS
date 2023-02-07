//
//  MultipleSelectionViewController.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/26/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import UIKit
import CheckoutSDK_iOS
import CommonDataModelsKit_iOS

protocol MultipleSelectionViewDelegate {
    func didUpdatePaymentTypes(paymentTypes: [TapPaymentType])
}
 
class MultipleSelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var listTableView: UITableView!
    
    var options: [TapPaymentType]?
    var selectedOptions: [TapPaymentType]? {
        didSet {
            delegate?.didUpdatePaymentTypes(paymentTypes: selectedOptions ?? [])
        }
    }
    var delegate: MultipleSelectionViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        if selectedOptions == nil {
            selectedOptions = []
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options?.count ?? 0
    }
       
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = options![indexPath.row].stringValue
        cell.accessoryType = selectedOptions!.contains(options![indexPath.row]) ? .checkmark : .none
        return cell
    }
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectType(at: indexPath)
        tableView.reloadData()
    }
    
    func selectType(at indexPath: IndexPath) {
        guard let options = options else { return }
        if indexPath.row == 0 {
            selectedOptions?.removeAll()
            selectedOptions?.append(options[indexPath.row])
            return
        }
        
        if indexPath.row != 0 && selectedOptions!.contains(options[0]) {
            selectedOptions?.removeAll{ $0 == options[0] }
        }
        if selectedOptions!.contains(options[indexPath.row]) {
            selectedOptions?.removeAll{ $0 == options[indexPath.row] }
        } else {
            selectedOptions?.append(options[indexPath.row])
        }
    }
}
