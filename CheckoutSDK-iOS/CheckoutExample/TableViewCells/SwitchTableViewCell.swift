//
//  LocalisationSwitchTableViewCell.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/12/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import UIKit

protocol SwitchTableViewCellDelegate {
    func switchDidChange(enabled: Bool, at indexPath: IndexPath?)
}

class SwitchTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var switchButton: UISwitch!
    var delegate: SwitchTableViewCellDelegate?
    var indexPath: IndexPath?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.switchButton.addTarget(self, action: #selector(switchToggled(sender:)), for: .valueChanged)
    }


    
    /// Called when the switch button state change.
    /// - Parameter sender: the sender switch view which has been toggled
    @objc func switchToggled(sender: UISwitch) {
        let value = sender.isOn
        print("switch value changed \(value)")
        self.delegate?.switchDidChange(enabled: sender.isOn, at: indexPath)
    }
}
