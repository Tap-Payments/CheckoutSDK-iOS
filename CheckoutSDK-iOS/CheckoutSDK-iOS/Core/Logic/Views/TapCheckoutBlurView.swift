//
//  TapCheckoutBlurView.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/3/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import UIKit
/// Represents a class that will handle showing a blurring background for the tap sheet based on the context
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
        if traitCollection.userInterfaceStyle == .dark {
            blurEffectView.effect = UIBlurEffect(style: .dark)
        }else {
            blurEffectView.effect = UIBlurEffect(style: .prominent)
            blurEffectView.alpha = 0.8
        }
    }
}

extension TapCheckoutBlurView {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // Change the blurring effect based on the current display status
        if traitCollection.userInterfaceStyle == .dark {
            blurEffectView.effect = UIBlurEffect(style: .dark)
        }else {
            blurEffectView.effect = UIBlurEffect(style: .prominent)
            blurEffectView.alpha = 0.8
        }
    }
}
