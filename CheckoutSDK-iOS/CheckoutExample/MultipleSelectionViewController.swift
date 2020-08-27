//
//  MultipleSelectionViewController.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/26/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import UIKit
import CheckoutSDK_iOS

protocol MultipleSelectionViewDelegate {
    func didSelectRow(with paymentType: TapPaymentType)
}
 
class MultipleSelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var listTableView: UITableView!
    
    var options: [TapPaymentType]?
    var delegate: MultipleSelectionViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options?.count ?? 0
    }
       
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = options![indexPath.row].stringValue
        return cell
    }
   
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let options = options else { return }
        self.delegate?.didSelectRow(with: options[indexPath.row])
        self.dismiss(animated: true, completion: nil)
    }
}
