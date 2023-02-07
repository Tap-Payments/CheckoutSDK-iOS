//
//  LogsViewController.swift
//  CheckoutExample
//
//  Created by Osama Rabie on 27/12/2022.
//

import UIKit

class LogsViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        textView.text = TapSettings.logs.joined(separator: "\n")
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func shareClicked(_ sender: Any) {
        let items = [textView.text ?? ""]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
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
