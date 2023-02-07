//
//  TaxTableViewController.swift
//  CheckoutExample
//
//  Created by Osama Rabie on 11/09/2022.
//

import UIKit
import CommonDataModelsKit_iOS

class TaxTableViewController: UITableViewController {

    var taxes:[Tax] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        loadTaxes()
    }

    @IBAction func addTaxClicked(_ sender: Any) {
        let viewController:CreateTaxViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CreateTaxViewController") as! CreateTaxViewController
        viewController.delegate = self
        present(viewController, animated: true)
    }
    
    
    func loadTaxes() {
        
        if let data = UserDefaults.standard.value(forKey:TapSettings.taxesSaveKey) as? Data {
            do {
                taxes = try PropertyListDecoder().decode([Tax].self, from: data)
            } catch {
                print("error paymentTypes: \(error.localizedDescription)")
                taxes = []
            }
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taxes.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaxTableCell", for: indexPath)
        let tax:Tax = taxes[indexPath.row]
        
        cell.textLabel?.text = tax.title
        cell.detailTextLabel?.text = "Amount: \(tax.amount.value ?? 0.0) \( (tax.amount.type == .Percentage) ? "%" : "")"
        
        return cell
    }
    
    
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            taxes.remove(at: indexPath.row)
            UserDefaults.standard.set(try! PropertyListEncoder().encode(taxes), forKey: TapSettings.taxesSaveKey)
            UserDefaults.standard.synchronize()
            
            loadTaxes()
        }
    }
    
    
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension TaxTableViewController: CreateTaxViewControllerDelegate {
    
    func taxAdded(with tax: Tax) {
        taxes.append(tax)
        UserDefaults.standard.set(try! PropertyListEncoder().encode(taxes), forKey: TapSettings.taxesSaveKey)
        UserDefaults.standard.synchronize()
        
        loadTaxes()
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
