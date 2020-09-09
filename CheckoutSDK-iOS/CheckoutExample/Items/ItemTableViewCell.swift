//
//  ItemTableViewCell.swift
//  CheckoutExample
//
//  Created by Kareem Ahmed on 8/18/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import UIKit
import CheckoutSDK_iOS

class ItemTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var discountLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(with item: ItemModel) {
        self.titleLabel.text = "Title: \(item.title ?? "")"
        self.descriptionLabel.text = "Description: \(item.itemDescription ?? "")"
        self.priceLabel.text = "Price: \(item.price ?? 0.0)"
        self.discountLabel.text = "Discount: \(item.discount?.valuee ?? 0.0)"
        self.quantityLabel.text = "Quantity: \(item.quantity ?? 0)"
    }
}
