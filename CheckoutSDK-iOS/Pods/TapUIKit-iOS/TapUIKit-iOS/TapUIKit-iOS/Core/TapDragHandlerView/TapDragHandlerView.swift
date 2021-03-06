//
//  TapDragHandlerView.swift
//  TapUIKit-iOS
//
//  Created by Osama Rabie on 6/9/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import TapThemeManager2020
import LocalisationManagerKit_iOS
import CommonDataModelsKit_iOS

/// Represents the public protocol to listen to the notifications fired from the TapDragHandler
@objc public protocol TapDragHandlerViewDelegate {
    /// Will be fired once the close button is clicked
    @objc func closeButtonClicked()
}

/// Represents a standalone configurable view to show a drag handler at the top of the bottom sheet
@objc public class TapDragHandlerView: UIView {
    
    /// The container view that holds everything from the XIB
    @IBOutlet var containerView: UIView!
    /// The image view to show the drag handler
    @IBOutlet var handlerImageView: UIImageView!
    /// The width constraint of the separation line, to be used in animating the width of the handler
    @IBOutlet weak var handlerImageViewWidthConstraint: NSLayoutConstraint!
    /// The height constraint of the separation line, to be used in animating the height of the handler
    @IBOutlet weak var handlerImageViewHeightConstraint: NSLayoutConstraint!
    /// The path to look for theme entry in
    private let themePath = "tapDragHandler"
    /// Represents the public protocol to listen to the notifications fired from the TapDragHandler
    public var delegate:TapDragHandlerViewDelegate?
    /// The button that will dismiss the whole TAP sheet
    @IBOutlet weak var cancelButton: UIButton!
    
    private var closeButtonState:CheckoutCloseButtonEnum = .icon
    
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
        self.containerView = setupXIB()
        self.translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(equalToConstant: 30).isActive = true
        self.layoutIfNeeded()
        handlerImageView.translatesAutoresizingMaskIntoConstraints = false
        applyTheme()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.containerView.frame = bounds
    }
    
    /**
     Will animate the handler image view to the provided width and height
     - Parameter width: The new width to be applied
     - Parameter height: The new height to be applied
     - Parameter animated : Indicates whether the width change should be animated or not, default is true
     */
    @objc public func changeHandlerSize(with width:CGFloat, and height:CGFloat, animated:Bool = true) {
        handlerImageViewWidthConstraint.constant = width
        handlerImageViewHeightConstraint.constant = height
        
        if animated {
            UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveEaseInOut], animations: { [weak self] in
                self?.layoutIfNeeded()
            }, completion: nil)
        }else{
            layoutIfNeeded()
        }
    }
    
    @objc public func changeCloseButton(to closeButtonState:CheckoutCloseButtonEnum) {
        if closeButtonState == .title {
            cancelButton.setTitle(TapLocalisationManager.shared.localisedValue(for: "Common.close", with: TapCommonConstants.pathForDefaultLocalisation()).uppercased(), for: .normal)
            cancelButton.setImage(nil, for: .normal)
        }else{
            cancelButton.setTitle("", for: .normal)
            cancelButton.setImage(TapThemeManager.imageValue(for: "merchantHeaderView.closeCheckoutIcon"), for: .normal)
        }
        self.closeButtonState = closeButtonState
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        delegate?.closeButtonClicked()
    }
}

// Mark:- Theme methods
extension TapDragHandlerView {
    /// Consolidated one point to apply all needed theme methods
    public func applyTheme() {
        matchThemeAttributes()
    }
    
    /**
     Update the visibility of the tap handler dragger with the given status
     - Parameter visiblity: If set, the handler will be shown. Will be hidden otherwise.
     */
    @objc public func updateHandler(visiblity to:Bool) {
        handlerImageView.isHidden = !to
    }
    
    /// Match the UI attributes with the correct theming entries
    private func matchThemeAttributes() {
        
        //cancelButton.setTitle(TapLocalisationManager.shared.localisedValue(for: "Common.close", with: TapCommonConstants.pathForDefaultLocalisation()), for: .normal)
        
        changeCloseButton(to: closeButtonState)
        
        handlerImageView.tap_theme_image = .init(keyPath: "\(themePath).image")
        handlerImageView.layer.tap_theme_cornerRadious = .init(keyPath: "\(themePath).corner")
        changeHandlerSize(with: CGFloat(TapThemeManager.numberValue(for: "\(themePath).width")?.floatValue ?? 75),
                          and: CGFloat(TapThemeManager.numberValue(for: "\(themePath).height")?.floatValue ?? 2))
        tap_theme_backgroundColor = .init(keyPath: "\(themePath).backgroundColor")
        cancelButton.tap_theme_setTitleColor(selector: .init(keyPath: "\(themePath).cancelButton.titleLabelColor"), forState: .normal)
        cancelButton.tap_theme_tintColor = .init(keyPath: "\(themePath).cancelButton.titleLabelColor")
        cancelButton.titleLabel?.tap_theme_font = .init(stringLiteral: "\(themePath).cancelButton.titleLabelFont")
    }
    
    /// Listen to light/dark mde changes and apply the correct theme based on the new style
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        TapThemeManager.changeThemeDisplay(for: self.traitCollection.userInterfaceStyle)
        applyTheme()
    }
}


/// Defines the style of the checkout close button
@objc public enum CheckoutCloseButtonEnum:Int {
    /// Will show a close button icon only
    case icon = 1
    /// Will show the word "CLOSE" as a title only
    case title = 2
}
