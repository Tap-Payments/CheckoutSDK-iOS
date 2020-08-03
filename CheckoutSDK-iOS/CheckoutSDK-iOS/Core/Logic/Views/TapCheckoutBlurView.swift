//
//  TapCheckoutBlurView.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/3/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import UIKit

class TapCheckoutBlurView: UIView {

    /// Represents the main holding view
    @IBOutlet var contentView: UIView!
    /// Represents the actual backbone web view
    @IBOutlet weak var blurEffectView: UIVisualEffectView!
    
    // Mark:- Init methods
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    /// Used as a consolidated method to do all the needed steps upon creating the view
    private func commonInit() {
        self.contentView = setupXIB()
    }
}

extension TapCheckoutBlurView {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        if traitCollection.userInterfaceStyle == .dark {
            blurEffectView.effect = UIBlurEffect(style: .dark)
        }else {
            blurEffectView.effect = UIBlurEffect(style: .regular)
        }
    }
}
