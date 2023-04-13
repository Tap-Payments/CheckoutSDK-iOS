//
//  TapBottomCheckoutControllerViewController.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/3/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import UIKit
import SnapKit
import CommonDataModelsKit_iOS
import TapUIKit_iOS
import WebKit
import TapApplePayKit_iOS
import TapCardVlidatorKit_iOS
import TapCardInputKit_iOS
import LocalisationManagerKit_iOS
import AVFoundation
import TapCardScanner_iOS

internal class TapBottomCheckoutControllerViewController: UIViewController {
    
    let sharedCheckoutDataManager:TapCheckout = TapCheckout.sharedCheckoutManager()
    
    var delegate:ToPresentAsPopupViewControllerDelegate?
    var tapVerticalView: TapVerticalView = .init()
    
    
    var tapActionButtonViewModel: TapActionButtonViewModel {
        return sharedCheckoutDataManager.dataHolder.viewModels.tapActionButtonViewModel
    }
    
    
    var dragView:TapDragHandlerView = .init()
    
    var webViewModel:TapWebViewModel = .init()
    
    var asyncViewModel:TapAsyncViewModel?
    
    var rates:[String:Double] = [:]
    var loadedWebPages:Int = 0
    var fadeOutAnimationDuration:Double = 0.3
    var fadeInAnimationDuration:Double = 0.7
    var fadeInAnimationDelay:Double  {
        return fadeOutAnimationDuration - 0.1
    }
    let poweredByTapView:PoweredByTapView = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TapKeyboardAvoiding.avoidingView = self.view
        TapKeyboardAvoiding.paddingForCurrentAvoidingView = -130
        //self.view.addKeyboardListener(30)
        //TapKeyboardAvoiding.keyboardAvoidingMode = .minimumDelayed
        //KeyboardAvoiding.setAvoidingView(self.view, withTriggerView:sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView)
        addDefaultViews()
        sharedCheckoutDataManager.UIDelegate = self
        tapVerticalView.delegate = self
        // Do any additional setup after  the view.
        tapVerticalView.updateKeyBoardHandling(with: false)
        createDefaultViewModels()
        // Setting up the number of lines and doing a word wrapping
        UILabel.appearance(whenContainedInInstancesOf:[UIAlertController.self]).numberOfLines = 2
        UILabel.appearance(whenContainedInInstancesOf:[UIAlertController.self]).lineBreakMode = .byWordWrapping
        addGloryViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(0)) {
            self.poweredByTapView.slideIn(from:.bottom, duration: 0.5)
            self.poweredByTapView.fadeIn(duration: 0.5)
            self.poweredByTapView.poweredByTapLogo.fadeIn(duration: 1)
            print("HERE")
        }
    }
    
    func addDefaultViews() {
        
        let tapBlurView:TapCheckoutBlurView = .init(frame: tapVerticalView.bounds)
        self.poweredByTapView.alpha = 0
        // Add the views
        view.addSubview(tapBlurView)
        view.addSubview(poweredByTapView)
        view.addSubview(tapVerticalView)
        
        view.backgroundColor = .clear
        tapVerticalView.backgroundColor = .clear
        
        tapVerticalView.layer.cornerRadius = CGFloat(12)
        tapVerticalView.clipsToBounds = true
        tapVerticalView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        tapBlurView.layer.cornerRadius = CGFloat(12)
        tapBlurView.clipsToBounds = true
        tapBlurView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        // Add the constraints
        poweredByTapView.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(58)
        }
        
        tapVerticalView.snp.remakeConstraints { (make) in
            make.top.equalTo(poweredByTapView.snp.bottom).offset(-10)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        tapBlurView.snp.remakeConstraints { (make) in
            make.edges.equalTo(tapVerticalView.snp.edges)
        }
        
        view.layoutIfNeeded()
    }
    
    func createDefaultViewModels() {
        
        sharedCheckoutDataManager.dataHolder.viewModels.tapMerchantViewModel.delegate = self
        
        sharedCheckoutDataManager.dataHolder.viewModels.tapAmountSectionViewModel.delegate = self
        
        tapActionButtonViewModel.buttonStatus = .InvalidPayment
        webViewModel.delegate = self
        changeBlur(to: false)
        
        createTabBarViewModel()
        dragView.updateHandler(visiblity: sharedCheckoutDataManager.dataHolder.viewModels.showDragHandler)
    }
    
    func createTabBarViewModel() {
        
        sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.delegate = self
    }
    
    func addGloryViews() {
        
        // The button
        self.tapVerticalView.setupActionButton(with: tapActionButtonViewModel)
        // Update the visibility of the views based on the transaction mode
        sharedCheckoutDataManager.updateViewsVisibility()
        // The initial views..
        self.tapVerticalView.add(views: [dragView,sharedCheckoutDataManager.dataHolder.viewModels.tapMerchantViewModel.attachedView,sharedCheckoutDataManager.dataHolder.viewModels.tapAmountSectionViewModel.attachedView,sharedCheckoutDataManager.dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.attachedView,sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.attachedView,sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView], with: [.init(for: .fadeIn)])
    }
    
    
    
    func showAlert(title:String,message:String) {
        let alertController:UIAlertController = .init(title: title, message: message, preferredStyle: .alert)
        let okAction:UIAlertAction = .init(title: "OK", style: .destructive, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    func showGoPay() {
        tapVerticalView.showGoPaySignInForm(with: self, and: sharedCheckoutDataManager.dataHolder.viewModels.goPayBarViewModel!)
    }
    
    /**
     Update the items list UI wise when a new currency is selected
     - Parameter currency: The new selected currency
     */
    func updateItemsList(with currency:TapCurrencyCode) {
        /*dataHolder.viewModels.tapItemsTableViewModel.dataSource.forEach { (genericCellModel) in
         if let itemViewModel:ItemCellViewModel = genericCellModel as? ItemCellViewModel {
         itemViewModel.convertCurrency = currency
         }
         }*/
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


extension TapBottomCheckoutControllerViewController: TapVerticalViewDelegate {
    
    func innerSizeChanged(to newSize: CGSize, with frame: CGRect) {
        //print("DELEGATE CALL BACK WITH SIZE \(newSize) and Frame of :\(frame)")
        guard let delegate = delegate else { return }
        
        delegate.changeHeight(to: newSize.height + frame.origin.y + view.safeAreaBottom)
    }
    
}


extension TapBottomCheckoutControllerViewController:TapMerchantHeaderViewDelegate {
    func iconClicked() {
        //showAlert(title: "Merchant Header", message: "You can make any action needed based on clicking the Profile Logo ;)")
    }
    func merchantHeaderClicked() {
        //showAlert(title: "Merchant Header", message: "The user clicked on the header section, do you want me to do anything?")
    }
    func closeButtonClicked() {
        delegate?.dismissMySelfClicked()
    }
}


extension TapBottomCheckoutControllerViewController:TapAmountSectionViewModelDelegate {
    func showItemsClicked() {
        self.view.endEditing(true)
        self.removeView(viewType: TapAmountSectionView.self, with: .init(for: .none, with: 0), and: true, skipSelf: true)
        tapVerticalView.hideActionButton(fadeInDuation: 0, fadeInDelay: 0)
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: { [weak self] in
            self!.sharedCheckoutDataManager.chanegActionButton(status: .InvalidPayment, actionBlock: nil)
            self!.sharedCheckoutDataManager.dataHolder.viewModels.tapCurrienciesChipHorizontalListViewModel.attachedView.alpha = 0
            self!.sharedCheckoutDataManager.dataHolder.viewModels.tapItemsTableViewModel.attachedView.alpha = 0
            self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.deselectAll()
            self!.sharedCheckoutDataManager.resetCardData(shouldFireCardDataChanged: false)
            CardValidator.favoriteCardBrand = nil
            self?.tapVerticalView.add(views: [self!.sharedCheckoutDataManager.dataHolder.viewModels.tapCurrienciesChipHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapItemsTableViewModel.attachedView], with: [.init(for: .slideIn, with:self!.fadeInAnimationDuration, wait: 0)])
            if let locale = TapLocalisationManager.shared.localisationLocale, locale == "ar" {
                //self?.sharedCheckoutDataManager.dataHolder.viewModels.tapCurrienciesChipHorizontalListViewModel.refreshLayout()
            }
            
            
            
            // We need to highlight the default currency of the user didn't select a new currency other than the default currency
            self!.sharedCheckoutDataManager.highlightDefaultCurrency()
        })
    }
    
    
    func closeItemsClicked() {
        // First we need to close any keyboard if any
        self.view.endEditing(true)
        // We will remove all the shown views below the amount section first
        self.removeView(viewType: TapChipHorizontalList.self, with: .init(for: .none, with: 0), and: true)
        // Now let us add back the default views
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: { [weak self] in
            self?.tapVerticalView.showActionButton(fadeInDuation:self!.fadeInAnimationDuration,fadeInDelay:0)
            self?.tapVerticalView.add(views: [self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView], with: [.init(for: .slideIn, with:self!.fadeInAnimationDuration, wait: 0)])
        })
    }
    
    func amountSectionClicked() {
        //showAlert(title: "Amount Section", message: "The user clicked on the amount section, do you want me to do anything?")
    }
    
    func closeScannerClicked() {
        tapVerticalView.closeScanner()
        sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.scanerClosed()
        DispatchQueue.main.async{ [weak self] in
            self?.tapVerticalView.add(views: [self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView], with: [.init(for: .slideIn, with:self!.fadeInAnimationDuration, wait: 0)])
        }
    }
    
    
    func localCurrencyPromptClicked(currencyCode: String) {
        // Make sure we have a valid currency view model (Just defensive code)
        guard let nonNullCurrencyCode:TapCurrencyCode = .init(appleRawValue: currencyCode),
              let nonNullCurrencyViewModel:CurrencyChipViewModel = self.sharedCheckoutDataManager.dataHolder.viewModels.currenciesChipsViewModel.first(where: { $0.currency.currency == nonNullCurrencyCode }) else { return }
        
        self.sharedCheckoutDataManager.currencyChip(for: nonNullCurrencyViewModel)
    }
    
    func closeGoPayClicked() {
        // Deselect all the selected chips
        sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.deselectAll()
        sharedCheckoutDataManager.chanegActionButton(status: .InvalidPayment,actionBlock: nil)
        view.endEditing(true)
        // inform the Tap vertical view to start the process of removing all the views related to the gopay sign in views
        tapVerticalView.closeGoPaySignInForm()
        // Add the default views back
        DispatchQueue.main.async { [weak self] in
            self?.tapVerticalView.add(views: [self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView], with: [.init(for: .fadeIn, with:self!.fadeInAnimationDuration, wait: self!.fadeInAnimationDelay)])
        }
        //showWebView(with: URL(string:"https://www.google.com")!)
    }
    
    func showScanner() {
        tapVerticalView.showScanner(with: sharedCheckoutDataManager, for: self)
    }
    
    func showAsyncView(merchantModel: TapMerchantHeaderViewModel, chargeModel: Charge, paymentOption:PaymentOption) {
        // Create the view model
        asyncViewModel = nil
        asyncViewModel = .init(merchantModel: merchantModel, chargeModel: chargeModel, paymentOption: paymentOption)
        guard let asyncView = asyncViewModel?.attachedView else {
            return
        }
        // Add the async view to the screen
        self.removeView(viewType: TapMerchantHeaderView.self, with: .init(for: .none, with: 0), and: true, skipSelf: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) { [weak self] in
            self?.tapActionButtonViewModel.expandButton()
            self?.tapActionButtonViewModel.buttonStatus = .AsyncClosePayment
            self?.tapActionButtonViewModel.buttonActionBlock = {
                DispatchQueue.main.async {
                    self?.delegate?.dismissMySelfClicked()
                }
            }
            self?.tapVerticalView.add(view: asyncView, with: [.init(for: .slideIn, with:self!.fadeInAnimationDuration, wait: 0)],shouldFillHeight: true)
            
        }
    }
    
    func showWebView(with url:URL, and navigationDelegate:TapWebViewModelDelegate? = nil, for webViewType:WebViewTypeEnum) {
        if webViewType == .InScreen {
            showWebViewInScreen(with: url, and: navigationDelegate)
        }else if webViewType == .InCard {
            showWebViewInCard(with: url, and: navigationDelegate)
        }else{
            showWebViewFullScreen(with: url, and: navigationDelegate)
        }
    }
    
    func showWebViewInScreen(with url:URL, and navigationDelegate:TapWebViewModelDelegate? = nil) {
        // Stop the dismiss on swipe feature, because when we remove all views, the height will be minium than the threshold, ending up the whole sheet being dimissed
        let originalDismissOnSwipeValue = disableAutoDismiss()
        
        // Stop OTP timers if any
        tapVerticalView.stopOTPTimers()
        
        self.removeView(viewType: TapAmountSectionView.self, with: .init(for: .fadeOut, with: fadeOutAnimationDuration), and: true, skipSelf: false)
        
        webViewModel = .init()
        webViewModel.delegate = navigationDelegate
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
            //self?.tapVerticalView.hideActionButton()
            self?.changeBlur(to: false)
            self?.sharedCheckoutDataManager.dataHolder.viewModels.tapAmountSectionViewModel.screenChanged(to: .SavedCardView)
            self?.tapActionButtonViewModel.expandButton()
            self?.tapActionButtonViewModel.buttonStatus = .CancelPayment
            self?.tapActionButtonViewModel.buttonActionBlock = {
                DispatchQueue.main.async {
                    self?.cancelWebView()
                    //TapCheckout.sharedCheckoutManager().dismissMySelfClicked()
                }
            }
            self?.tapVerticalView.add(view: self!.webViewModel.attachedView, with: [.init(for: .fadeIn, with:self!.fadeInAnimationDuration, wait: self!.fadeInAnimationDelay)],shouldFillHeight: true)
            self?.webViewModel.load(with: url)
            // Set it back to swipe on dismiss
            TapCheckout.sharedCheckoutManager().dataHolder.viewModels.swipeDownToDismiss = originalDismissOnSwipeValue
        }
    }
    
    func showWebViewInCard(with url:URL, and navigationDelegate:TapWebViewModelDelegate? = nil) {
        // Stop the dismiss on swipe feature, because when we remove all views, the height will be minium than the threshold, ending up the whole sheet being dimissed
        let originalDismissOnSwipeValue = disableAutoDismiss()
        
        // Stop OTP timers if any
        tapVerticalView.stopOTPTimers()
        
        webViewModel = .init()
        webViewModel.delegate = navigationDelegate
        webViewModel.load(with: url)
        
        webViewModel.idleForWhile = {
            self.webViewModel.idleForWhile = {}
            self.tapVerticalView.hideActionButton(fadeInDuation: 0.25,keepPowredByTapView: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) { [weak self] in
                // make sure all is set
                guard let paymentViewModel = self?.sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel else {return}
                let cardView = paymentViewModel.attachedView
                cardView.cardInputView.alpha = 0
                // let us add the web view inside the card and fade it in
                paymentViewModel.addFullScreen(view: self?.webViewModel.attachedView)
                // adjust the button and the cancel button to get back from the web view when needed
                self?.sharedCheckoutDataManager.dataHolder.viewModels.tapAmountSectionViewModel.screenChanged(to: .SavedCardView)
                
                
                // Time to scale the size to show the web view after the fade in animation
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(0)) {
                    let newMaxSize = cardView.frame.height + (self?.tapVerticalView.getMaxAvailableHeight(showingCardWebView: true) ?? 0) - 150
                    cardView.snp.updateConstraints { make in
                        make.height.equalTo(newMaxSize)
                    }
                    cardView.layoutIfNeeded()
                    self?.enableInteraction(with: true)
                }
                TapCheckout.sharedCheckoutManager().dataHolder.viewModels.swipeDownToDismiss = originalDismissOnSwipeValue
            }
        }
        
        // add a blur view to spice up the 3ds bg
        
        /*let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.layer.cornerRadius = 8
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        webViewModel.attachedView.insertSubview(blurView, at: 0)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: webViewModel.attachedView.webViewHolder.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: webViewModel.attachedView.webViewHolder.leadingAnchor),
            blurView.heightAnchor.constraint(equalTo: webViewModel.attachedView.webViewHolder.heightAnchor),
            blurView.widthAnchor.constraint(equalTo: webViewModel.attachedView.webViewHolder.widthAnchor)
        ])*/
    }
    
    func showWebViewFullScreen(with url:URL, and navigationDelegate:TapWebViewModelDelegate? = nil) {
        // Stop the dismiss on swipe feature, because when we remove all views, the height will be minium than the threshold, ending up the whole sheet being dimissed
        let originalDismissOnSwipeValue = disableAutoDismiss()
        
        self.removeView(viewType: TapMerchantHeaderView.self, with: .init(for: .fadeOut), and: true, skipSelf: false)
        
        webViewModel = .init()
        webViewModel.shouldShowHeaderView = false
        webViewModel.shouldBeFullScreen = true
        
        webViewModel.delegate = navigationDelegate
        webViewModel.load(with: url)
        
        webViewModel.idleForWhile = {
            self.webViewModel.idleForWhile = {}
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [weak self] in
                self?.tapVerticalView.hideActionButton()
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                    self?.tapVerticalView.add(view: self!.webViewModel.attachedView, with: [.init(for: .slideIn, with:self!.fadeInAnimationDuration, wait: 0.1)],shouldFillHeight: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
                        self?.webViewModel.webView.webView.scrollView.tap_scrollToBottom(animated: false)
                        self?.webViewModel.webView.webView.scrollView.tap_scrollToTop(animated: false)
                        print("SCROLLED")
                    }
                }
                self?.webViewModel.attachedView.layoutIfNeeded()
                // remove any loading view if needed
                self?.enableInteraction(with: true)
                // Set it back to swipe on dismiss
                TapCheckout.sharedCheckoutManager().dataHolder.viewModels.swipeDownToDismiss = originalDismissOnSwipeValue
            }
        }
    }
    
    /// Handles closing the web view and getting back normal views
    func cancelWebView(showingFullScreen:Bool = false) {
        // First thing, animate closing the web view
        /*// We will remove all the shown views below the amount section first
         self.removeView(viewType: TapWebView.self, with: .init(for: .fadeOut, with: fadeOutAnimationDuration), and: true)
         // Now let us add back the default views
         DispatchQueue.main.asyncAfter(deadline: .now(), execute: { [weak self] in
         self?.tapVerticalView.showActionButton(fadeInDuation:self!.fadeInAnimationDuration,fadeInDelay:self!.fadeInAnimationDelay)
         self?.tapVerticalView.add(views: [ self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView], with: [.init(for: .fadeIn, with:self!.fadeInAnimationDuration, wait: self!.fadeInAnimationDelay)])
         })*/
        let isAsyncPayment = sharedCheckoutDataManager.dataHolder.transactionData.selectedPaymentOption?.isAsync ?? false
        let isAsyncPaymentFinished = sharedCheckoutDataManager.dataHolder.transactionData.currentCharge?.status
        
        if isAsyncPayment, isAsyncPaymentFinished == .inProgress {
            delegate?.dismissMySelfClicked()
        }else{
            closeWebView()
            // Reset data
            sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.deselectAll()
            sharedCheckoutDataManager.resetCardData(shouldFireCardDataChanged: false)
            CardValidator.favoriteCardBrand = nil
            // Adjust the button back
            sharedCheckoutDataManager.chanegActionButton(status: .InvalidPayment, actionBlock: nil)
            
            if showingFullScreen {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    self.sharedCheckoutDataManager.dataHolder.viewModels.tapActionButtonViewModel.expandButton()
                }
                
                // Add back the default views & reset the
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) { [weak self] in
                    // Once we finished the password/OTP views of goPay we have to make sure that the blur view is now invisible
                    self?.tapVerticalView.add(views: [self!.sharedCheckoutDataManager.dataHolder.viewModels.tapMerchantViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapAmountSectionViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView], with: [.init(for: .fadeIn, with:self!.fadeInAnimationDuration - 0.4, wait: self!.fadeInAnimationDelay)])
                }
            }else{
                // Add back the default views & reset the
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(650)) { [weak self] in
                    self?.tapVerticalView.showBlur = false
                    self?.sharedCheckoutDataManager.dataHolder.viewModels.tapAmountSectionViewModel.screenChanged(to: .DefaultView)
                    self?.tapVerticalView.add(views: [self!.sharedCheckoutDataManager.dataHolder.viewModels.tapAmountSectionViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView], with: [.init(for: .fadeIn, with:self!.fadeInAnimationDuration, wait: self!.fadeInAnimationDelay)])
                }
            }
        }
    }
    
    func closeWebView() {
        
        // Stop the dismiss on swipe feature, because when we remove all views, the height will be minium than the threshold, ending up the whole sheet being dimissed
        let originalDismissOnSwipeValue = disableAutoDismiss()
        
        self.view.endEditing(true)
        self.tapVerticalView.remove(view: sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView, with: .init(for: .fadeOut, with: fadeOutAnimationDuration))
        self.tapVerticalView.remove(view: webViewModel.attachedView, with: .init(for: .fadeOut, with: fadeOutAnimationDuration))
        self.tapVerticalView.showActionButton()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            // Set it back to swipe on dismiss
            TapCheckout.sharedCheckoutManager().dataHolder.viewModels.swipeDownToDismiss = originalDismissOnSwipeValue
        }
    }
    
    func disableAutoDismiss() -> Bool {
        // Stop the dismiss on swipe feature, because when we remove all views, the height will be minium than the threshold, ending up the whole sheet being dimissed
        let sharedManager = TapCheckout.sharedCheckoutManager()
        let originalDismissOnSwipeValue = sharedManager.dataHolder.viewModels.swipeDownToDismiss
        sharedManager.dataHolder.viewModels.swipeDownToDismiss = false
        return originalDismissOnSwipeValue
    }
    
    func hideGoPay() {
        self.view.endEditing(true)
        self.tapVerticalView.remove(view: sharedCheckoutDataManager.dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.attachedView, with: .init(for: .fadeOut, with: fadeOutAnimationDuration))
        self.sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.editMode(changed: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.headerType = .GatewayListHeader
            UserDefaults.standard.set(false, forKey: TapCheckoutConstants.GoPayLoginUserDefaultsKey)
            self.sharedCheckoutDataManager.dataHolder.transactionData.loggedInToGoPay = false
        }
    }
    
    
    func hideLoyalty() {
        tapVerticalView.remove(viewType: TapLoyaltyView.self, with: .init(for: .fadeOut), and: false)
    }
    
    
    func showLoyalty(with loyaltyViewModel: TapLoyaltyViewModel, animate:Bool) {
        tapVerticalView.add(views: [loyaltyViewModel.attachedView], with: [.init(for:.fadeIn,with: animate ? 0.25 : 0.1)])
    }
}






extension TapBottomCheckoutControllerViewController {
    
    
    func handleTelecomPayment(for cardBrand: CardBrand, with validation: CrardInputTextFieldStatusEnum) {
        if validation == .Valid {
            tapActionButtonViewModel.buttonStatus = .ValidPayment
            let payAction:()->() = { self.startPayment(then:true) }
            tapActionButtonViewModel.buttonActionBlock = payAction
        }else {
            tapActionButtonViewModel.buttonStatus = .InvalidPayment
            tapActionButtonViewModel.buttonActionBlock = {}
        }
    }
    
    func startPayment(then success:Bool) {
        view.endEditing(true)
        self.removeView(viewType: TapAmountSectionView.self, with: .init(for: .fadeOut, with: fadeOutAnimationDuration), and: true, skipSelf: true)
        self.tapActionButtonViewModel.startLoading()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(3500)) {
            self.tapActionButtonViewModel.endLoading(with: success, completion: {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) {
                    self.dismiss(animated: true, completion: nil)
                }
            })
        }
        
        
    }
    
    /**
     Removes an arranged subview from the vertical hierarchy
     - Parameter view: The view to be deleted
     - Parameter animation: The animation to be applied while doing the view removal. Default is nil
     - Parameter deleteAfterViews: If true, all views below the mentioned view will be deleted
     - Parameter skipSelf: If true, then the mentioned view WILL not be deleted and all views below the mentioned view will be deleted
     */
    internal func removeView(viewType:AnyClass, with animation:TapSheetAnimation? = nil, and deleteAfterViews:Bool = false,skipSelf:Bool = false) {
        let sharedManager = TapCheckout.sharedCheckoutManager()
        let originalDismissOnSwipeValue = sharedManager.dataHolder.viewModels.swipeDownToDismiss
        sharedManager.dataHolder.viewModels.swipeDownToDismiss = false
        
        self.tapVerticalView.remove(viewType: viewType, with: animation ?? .init(for: .fadeOut, with: fadeOutAnimationDuration), and: deleteAfterViews, skipSelf: skipSelf)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            sharedManager.dataHolder.viewModels.swipeDownToDismiss = originalDismissOnSwipeValue
        }
    }
}

extension TapBottomCheckoutControllerViewController: TapAuthenticateDelegate {
    func authenticationSuccess() {
        print("authenticationSuccess")
        startPayment(then: true)
    }
    
    func authenticationFailed(with error: Error?) {
        print("authenticationFailed")
        tapActionButtonViewModel.buttonStatus = .ValidPayment
        tapActionButtonViewModel.expandButton()
    }
}


extension TapBottomCheckoutControllerViewController:TapCardTelecomPaymentProtocol {
    func cardFieldsAreFocused() {
        sharedCheckoutDataManager.handleCardFormIsFocused()
    }
    
    func saveCardChanged(for saveCardType: SaveCardType, to enabled: Bool) {
        // update the saving card status for the checkout manager
        // If activated for TAP we need to check if we have to collect user's data
        if saveCardType == .Tap {
            sharedCheckoutDataManager.handleCustomerContact(with: .Valid)
        }
    }
    
    func closeSavedCardClicked() {
        // Deselect the already selected saved card
        sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.deselectAll()
        sharedCheckoutDataManager.dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.deselectAll()
        // Invalidate the payment button
        // The status is invalid hence we need to clear the action button
        sharedCheckoutDataManager.dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .InvalidPayment
        sharedCheckoutDataManager.dataHolder.viewModels.tapActionButtonViewModel.buttonActionBlock = {}
    }
    
    
    func showHint(with status: TapHintViewStatusEnum) {
        let hintViewModel:TapHintViewModel = .init(with: status)
        let hintView:TapHintView = hintViewModel.createHintView()
        tapVerticalView.attach(hintView: hintView, to: TapCardTelecomPaymentView.self,with: false)
    }
    
    func hideHints() {
        tapVerticalView.removeAllHintViews()
    }
    
    func cardDataChanged(tapCard: TapCard,cardStatusUI:CardInputUIStatus) {
        // Based on the card input status we decide what to do with the new card
        if cardStatusUI == .SavedCard {
            // We don't deselct the selected card, we reset the current card data
            sharedCheckoutDataManager.dataHolder.transactionData.currentCard = .init(tapCardCVV:tapCard.tapCardCVV)
        }else{
            // When a new card data is entered, then we need to deselct any selected gatways like SAVED CARDS or Redirections chips
            sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.deselectAll()
            sharedCheckoutDataManager.dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.deselectAll()
            // Let us inform the checkout shared manager about the new card please
            sharedCheckoutDataManager.dataHolder.transactionData.currentCard = (tapCard.tapCardNumber?.tap_length ?? 0 > 0) ? tapCard : nil
        }
    }
    
    func brandDetected(for cardBrand: CardBrand, with validation: CrardInputTextFieldStatusEnum,cardStatusUI: CardInputUIStatus, isCVVFocused:Bool) {
        //tapActionButtonViewModel.buttonStatus = (validation == .Valid) ? .ValidPayment : .InvalidPayment
        // Based on the detected brand type we decide the action button status
        if cardBrand.brandSegmentIdentifier == "telecom" {
            handleTelecomPayment(for: cardBrand, with: validation)
        }else if cardBrand.brandSegmentIdentifier == "cards" {
            sharedCheckoutDataManager.handleCardValidationStatus(for:cardBrand, with: validation, cardStatusUI: cardStatusUI, isCVVFocused: isCVVFocused)
        }
    }
    
    func scanCardClicked() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [weak self] response in
            if response {
                //access granted
                DispatchQueue.main.asyncAfter(deadline: .now()) {[weak self] in
                    self?.showScanner()
                }
            }
        }
    }
    
    
    func shouldAllowChange(with cardNumber: String) -> Bool {
        return sharedCheckoutDataManager.shouldAllowCard(with: cardNumber)
    }
}


extension TapBottomCheckoutControllerViewController:TapGenericTableViewModelDelegate {
    func didSelectTable(item viewModel: TapGenericTableCellViewModel) {
        return
    }
    
    func itemClicked(for viewModel: ItemCellViewModel) {
        showAlert(title: viewModel.itemTitle(), message: "You clicked on the item.. Look until now, clicking an item is worthless we are just showcasing 🙂")
    }
}


extension TapBottomCheckoutControllerViewController: TapGoPaySignInViewProtocol {
    func countryCodeClicked() {
        
    }
    
    func changeBlur(to:Bool) {
        self.tapVerticalView.showBlur = to
    }
    
    func signIn(with email: String, and password: String) {
        sharedCheckoutDataManager.signIn(email: email, password: password)
    }
    
    func signIn(phone: String, and otp: String) {
        sharedCheckoutDataManager.signIn(phone: phone, otp: otp)
    }
    
    func verifyAuthentication(for otpAuthenticationID:String, with otp:String) {
        // Get the authenticable model based on the current transaction mode
        switch sharedCheckoutDataManager.dataHolder.transactionData.transactionMode
        {
        case .purchase:
            // Then we are dealing with a charge mode
            sharedCheckoutDataManager.verifyAuthenticationOTP(for: otpAuthenticationID, with: otp, chargeOrAuthorize:sharedCheckoutDataManager.dataHolder.transactionData.currentCharge!)
            break
        case .authorizeCapture:
            // Then we are dealing with authorize model
            sharedCheckoutDataManager.verifyAuthenticationOTP(for: otpAuthenticationID, with: otp, chargeOrAuthorize:sharedCheckoutDataManager.dataHolder.transactionData.currentAuthorize!)
            break
        default:
            break
        }
    }
    
    func closeGoPaySignView() {
        // We need to close the goPaySign in view and show back the default views in the checkout screen
        closeGoPayClicked()
    }
}


extension UIView {
    
    var safeAreaBottom: CGFloat {
        if #available(iOS 11, *) {
            if let window = UIApplication.shared.keyWindowInConnectedScenes {
                return window.safeAreaInsets.bottom
            }
        }
        return 0
    }
    
    var safeAreaTop: CGFloat {
        if #available(iOS 11, *) {
            if let window = UIApplication.shared.keyWindowInConnectedScenes {
                return window.safeAreaInsets.top
            }
        }
        return 0
    }
}

extension UIApplication {
    var keyWindowInConnectedScenes: UIWindow? {
        return windows.first(where: { $0.isKeyWindow })
    }
}


extension TapBottomCheckoutControllerViewController: TapSwitchViewModelDelegate {
    func didChangeCardState(cardState: TapSwitchCardStateEnum) {
        print("current card State: \(cardState.rawValue)")
    }
    
    func didChangeState(state: TapSwitchEnum, enabledSwitches:TapSwitchEnum) {
        
        changeBlur(to: state != .none && enabledSwitches == .all)
        
        if state != .none {
            self.tapActionButtonViewModel.buttonStatus = .SaveValidPayment
        }
        
        //self.tapActionButtonViewModel.buttonStatus = (state == .none) ? .ValidPayment : .SaveValidPayment
        
    }
}

extension TapBottomCheckoutControllerViewController:TapWebViewModelDelegate {
    func webViewCanceled(showingFullScreen:Bool) {
        cancelWebView(showingFullScreen: showingFullScreen)
    }
    
    func willLoad(request: URLRequest) -> WKNavigationActionPolicy {
        return .allow
    }
    
    func didLoad(url: URL?) {
        loadedWebPages += 1
        if loadedWebPages > 2 {
            closeWebView()
        }
    }
    
    func didFail(with error: Error, for url: URL?) {
        
    }
}


extension TapBottomCheckoutControllerViewController:TapCheckoutSharedManagerUIDelegate {
    
    func changeHeightt(to: CGFloat) {
        //print("DELEGATE CALL BACK WITH SIZE \(newSize) and Frame of :\(frame)")
        guard let delegate = delegate else { return }
        
        delegate.reduceHeight(by: to)
    }
    
    func prepareFor3DSInCardAnimation() {
        // First let us remove the gateways view if any
        //tapVerticalView.remove(viewType: TapChipHorizontalList .self, with: .init(for: .fadeOut, with: 0.35), and: false, skipSelf: false)
        //tapVerticalView.remove(viewType: CustomerContactDataCollectionView.self, with: .init(for: .fadeOut, with: 0.35), and: false, skipSelf: false)
        //tapVerticalView.remove(viewType: CustomerShippingDataCollectionView.self, with: .init(for: .fadeOut, with: 0.35), and: false, skipSelf: false)
        
        
        // Second let us shrink the card view and make it in the ideal height,
        // Which is mainly hiding the save card view
        let cardViewModel = sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(550)) {
            cardViewModel.change3dsLoadingStatus(to: true)
        }
    }
    
    func hideCustomerContactDataCollection() {
        tapVerticalView.remove(viewType: CustomerContactDataCollectionView .self, with: .init(for: .fadeOut, with: fadeOutAnimationDuration), and: false)
        tapVerticalView.remove(viewType: CustomerShippingDataCollectionView .self, with: .init(for: .fadeOut, with: fadeOutAnimationDuration), and: false)
    }
    
    
    func showCustomerContactDataCollection(with customerDataViewModel: CustomerContactDataCollectionViewModel, and customerShippingViewModel:CustomerShippingDataCollectionViewModel, animate: Bool) {
        tapVerticalView.add(views: [customerDataViewModel.attachedView, customerShippingViewModel.attachedView], with: [.init(for:.fadeIn,with: animate ? 0.25 : 0.1)], shouldScrollToBottom: true)
    }
    
    
    func attach(hintView: TapHintView, to: AnyClass, with animations: Bool) {
        tapVerticalView.attach(hintView: hintView, to: to, with: animations)
    }
    
    
    func showSavedCardOTPView(with authenticationID:String = "") {
        tapVerticalView.showGoPaySignInForm(with: self, and: sharedCheckoutDataManager.dataHolder.viewModels.goPayBarViewModel!,hintViewStatus: .SavedCardOTP, for: authenticationID)
        //KeyboardAvoiding.setAvoidingView(self.view, withTriggerView:self.tapVerticalView.powereByTapView.poweredbyLabel)
    }
    
    func hideSavedCardOTP() {
        //KeyboardAvoiding.setAvoidingView(self.view, withTriggerView:sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView)
        hideGoPay()
    }
    
    func dismissCheckout(with error: Error) {
        delegate?.dismissMySelfClicked()
    }
    
    func actionButton(shouldLoad: Bool, success: Bool, onComplete: @escaping () -> ()) {
        if shouldLoad {
            tapActionButtonViewModel.startLoading(completion: onComplete)
        }else{
            tapActionButtonViewModel.endLoading(with: success, completion: onComplete)
        }
    }
    
    
    func goPaySignIn(status: Bool) {
        
        tapActionButtonViewModel.endLoading(with: true, completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) { [weak self] in
                self?.closeGoPayClicked()
                self?.tapActionButtonViewModel.buttonStatus = .InvalidPayment
                self?.tapActionButtonViewModel.expandButton()
            }
        })
    }
    
    func removeView(view: UIView,with animation:TapSheetAnimation? = nil) {
        tapVerticalView.remove(view: view, with: animation)
    }
    
    /**
     Will call the root controller to display a needed alert controller
     - Parameter alert: The UIAlertController to be displayed
     */
    func show(alert:UIAlertController) {
        present(alert, animated: true, completion: nil)
    }
    
    func enableInteraction(with status: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let nonNullSelf = self else {return}
            if let addedBeforeView:UIView = nonNullSelf.view.viewWithTag(12341234) {
                addedBeforeView.removeFromSuperview()
            }
            
            // Add an idle view if the caller wants to disable
            if !status {
                nonNullSelf.view.endEditing(false)
                let idleView:UIView = .init(frame: nonNullSelf.view.frame)
                idleView.backgroundColor = .clear
                idleView.tag = 12341234
                nonNullSelf.view.addSubview(idleView)
                nonNullSelf.view.bringSubviewToFront(idleView)
            }
        }
    }
}


// MARK: - The scanner data source
extension TapBottomCheckoutControllerViewController: TapScannerDataSource {
    func allowedCardBrands() -> [CardBrand] {
        if let loadedDataCardBrands = sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.tapCardPhoneListViewModel?.dataSource.map({ $0.associatedCardBrand }) {
            return loadedDataCardBrands
        }
        return CardBrand.allCases
    }
}





/**
 Edge of the view's parent that the animation should involve
 - none: involves no edge
 - top: involves the top edge of the parent
 - bottom: involves the bottom edge of the parent
 - left: involves the left edge of the parent
 - right: involves the right edge of the parent
 */
fileprivate enum SimpleAnimationEdge {
    case none
    case top
    case bottom
    case left
    case right
}

/**
 A UIView extension that makes adding basic animations, like fades and bounces, simple.
 */
fileprivate extension UIView {
    /**
     Fades this view in. This method can be chained with other animations to combine a fade with
     the other animation, for instance:
     ```
     view.fadeIn().slideIn(from: .left)
     ```
     - Parameters:
     - duration: duration of the animation, in seconds
     - delay: delay before the animation starts, in seconds
     - completion: block executed when the animation ends
     */
    @discardableResult func fadeIn(duration: TimeInterval = 0.25,
                                   delay: TimeInterval = 0,
                                   completion: ((Bool) -> Void)? = nil) -> UIView {
        isHidden = false
        alpha = 0
        UIView.animate(
            withDuration: duration, delay: delay, options: .curveEaseInOut, animations: {
                self.alpha = 1
            }, completion: completion)
        return self
    }
    
    /**
     Fades this view out. This method can be chained with other animations to combine a fade with
     the other animation, for instance:
     ```
     view.fadeOut().slideOut(to: .right)
     ```
     - Parameters:
     - duration: duration of the animation, in seconds
     - delay: delay before the animation starts, in seconds
     - completion: block executed when the animation ends
     */
    @discardableResult func fadeOut(duration: TimeInterval = 0.25,
                                    delay: TimeInterval = 0,
                                    completion: ((Bool) -> Void)? = nil) -> UIView {
        UIView.animate(
            withDuration: duration, delay: delay, options: .curveEaseOut, animations: {
                self.alpha = 0
            }, completion: completion)
        return self
    }
    
    /**
     Fades the background color of a view from existing bg color to a specified color without using alpha values.
     
     - Parameters:
     - toColor: the final color you want to fade to
     - duration: duration of the animation, in seconds
     - delay: delay before the animation starts, in seconds
     - completion: block executed when the animation ends
     */
    @discardableResult func fadeColor(toColor: UIColor = UIColor.red,
                                      duration: TimeInterval = 0.25,
                                      delay: TimeInterval = 0,
                                      completion: ((Bool) -> Void)? = nil) -> UIView {
        UIView.animate(
            withDuration: duration, delay: delay, options: .curveEaseIn, animations: {
                self.backgroundColor = toColor
            }, completion: completion)
        return self
    }
    
    /**
     Slides this view into position, from an edge of the parent (if "from" is set) or a fixed offset
     away from its position (if "x" and "y" are set).
     - Parameters:
     - from: edge of the parent view that should be used as the starting point of the animation
     - x: horizontal offset that should be used for the starting point of the animation
     - y: vertical offset that should be used for the starting point of the animation
     - duration: duration of the animation, in seconds
     - delay: delay before the animation starts, in seconds
     - completion: block executed when the animation ends
     */
    @discardableResult func slideIn(from edge: SimpleAnimationEdge = .none,
                                    x: CGFloat = 0,
                                    y: CGFloat = 0,
                                    duration: TimeInterval = 0.4,
                                    delay: TimeInterval = 0,
                                    completion: ((Bool) -> Void)? = nil) -> UIView {
        let offset = offsetFor(edge: edge)
        transform = CGAffineTransform(translationX: offset.x + x, y: offset.y + y)
        isHidden = false
        UIView.animate(
            withDuration: duration, delay: delay, usingSpringWithDamping: 1, initialSpringVelocity: 2,
            options: .curveEaseOut, animations: {
                self.transform = .identity
                self.alpha = 1
            }, completion: completion)
        return self
    }
    
    /**
     Slides this view out of its position, toward an edge of the parent (if "to" is set) or a fixed
     offset away from its position (if "x" and "y" are set).
     - Parameters:
     - to: edge of the parent view that should be used as the ending point of the animation
     - x: horizontal offset that should be used for the ending point of the animation
     - y: vertical offset that should be used for the ending point of the animation
     - duration: duration of the animation, in seconds
     - delay: delay before the animation starts, in seconds
     - completion: block executed when the animation ends
     */
    @discardableResult func slideOut(to edge: SimpleAnimationEdge = .none,
                                     x: CGFloat = 0,
                                     y: CGFloat = 0,
                                     duration: TimeInterval = 0.25,
                                     delay: TimeInterval = 0,
                                     completion: ((Bool) -> Void)? = nil) -> UIView {
        let offset = offsetFor(edge: edge)
        let endTransform = CGAffineTransform(translationX: offset.x + x, y: offset.y + y)
        UIView.animate(
            withDuration: duration, delay: delay, options: .curveEaseOut, animations: {
                self.transform = endTransform
            }, completion: completion)
        return self
    }
    
    /**
     Moves this view into position, with a bounce at the end, either from an edge of the parent (if
     "from" is set) or a fixed offset away from its position (if "x" and "y" are set).
     - Parameters:
     - from: edge of the parent view that should be used as the starting point of the animation
     - x: horizontal offset that should be used for the starting point of the animation
     - y: vertical offset that should be used for the starting point of the animation
     - duration: duration of the animation, in seconds
     - delay: delay before the animation starts, in seconds
     - completion: block executed when the animation ends
     */
    @discardableResult func bounceIn(from edge: SimpleAnimationEdge = .none,
                                     x: CGFloat = 0,
                                     y: CGFloat = 0,
                                     duration: TimeInterval = 0.5,
                                     delay: TimeInterval = 0,
                                     completion: ((Bool) -> Void)? = nil) -> UIView {
        let offset = offsetFor(edge: edge)
        transform = CGAffineTransform(translationX: offset.x + x, y: offset.y + y)
        isHidden = false
        UIView.animate(
            withDuration: duration, delay: delay, usingSpringWithDamping: 0.58, initialSpringVelocity: 3,
            options: .curveEaseOut, animations: {
                self.transform = .identity
                self.alpha = 1
            }, completion: completion)
        return self
    }
    
    /**
     Moves this view out of its position, starting with a bounce. The view moves toward an edge of
     the parent (if "to" is set) or a fixed offset away from its position (if "x" and "y" are set).
     - Parameters:
     - to: edge of the parent view that should be used as the ending point of the animation
     - x: horizontal offset that should be used for the ending point of the animation
     - y: vertical offset that should be used for the ending point of the animation
     - duration: duration of the animation, in seconds
     - delay: delay before the animation starts, in seconds
     - completion: block executed when the animation ends
     */
    @discardableResult func bounceOut(to edge: SimpleAnimationEdge = .none,
                                      x: CGFloat = 0,
                                      y: CGFloat = 0,
                                      duration: TimeInterval = 0.35,
                                      delay: TimeInterval = 0,
                                      completion: ((Bool) -> Void)? = nil) -> UIView {
        let offset = offsetFor(edge: edge)
        let delta = CGPoint(x: offset.x + x, y: offset.y + y)
        let endTransform = CGAffineTransform(translationX: delta.x, y: delta.y)
        let prepareTransform = CGAffineTransform(translationX: -delta.x * 0.2, y: -delta.y * 0.2)
        UIView.animateKeyframes(
            withDuration: duration, delay: delay, options: .calculationModeCubic, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.2) {
                    self.transform = prepareTransform
                }
                UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.2) {
                    self.transform = prepareTransform
                }
                UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.6) {
                    self.transform = endTransform
                }
            }, completion: completion)
        return self
    }
    
    /**
     Moves this view into position, as though it were popping out of the screen.
     - Parameters:
     - fromScale: starting scale for the view, should be between 0 and 1
     - duration: duration of the animation, in seconds
     - delay: delay before the animation starts, in seconds
     - completion: block executed when the animation ends
     */
    @discardableResult func popIn(fromScale: CGFloat = 0.5,
                                  duration: TimeInterval = 0.5,
                                  delay: TimeInterval = 0,
                                  completion: ((Bool) -> Void)? = nil) -> UIView {
        isHidden = false
        alpha = 0
        transform = CGAffineTransform(scaleX: fromScale, y: fromScale)
        UIView.animate(
            withDuration: duration, delay: delay, usingSpringWithDamping: 0.55, initialSpringVelocity: 3,
            options: .curveEaseOut, animations: {
                self.transform = .identity
                self.alpha = 1
            }, completion: completion)
        return self
    }
    
    /**
     Moves this view out of position, as though it were withdrawing into the screen.
     - Parameters:
     - toScale: ending scale for the view, should be between 0 and 1
     - duration: duration of the animation, in seconds
     - delay: delay before the animation starts, in seconds
     - completion: block executed when the animation ends
     */
    @discardableResult func popOut(toScale: CGFloat = 0.5,
                                   duration: TimeInterval = 0.3,
                                   delay: TimeInterval = 0,
                                   completion: ((Bool) -> Void)? = nil) -> UIView {
        let endTransform = CGAffineTransform(scaleX: toScale, y: toScale)
        let prepareTransform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        UIView.animateKeyframes(
            withDuration: duration, delay: delay, options: .calculationModeCubic, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.2) {
                    self.transform = prepareTransform
                }
                UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.3) {
                    self.transform = prepareTransform
                }
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.transform = endTransform
                    self.alpha = 0
                }
            }, completion: completion)
        return self
    }
    
    /**
     Causes the view to hop, either toward a particular edge or out of the screen (if "toward" is
     .None).
     - Parameters:
     - toward: the edge to hop toward, or .None to hop out
     - amount: distance to hop, expressed as a fraction of the view's size
     - duration: duration of the animation, in seconds
     - delay: delay before the animation starts, in seconds
     - completion: block executed when the animation ends
     */
    @discardableResult func hop(toward edge: SimpleAnimationEdge = .none,
                                amount: CGFloat = 0.4,
                                duration: TimeInterval = 0.6,
                                delay: TimeInterval = 0,
                                completion: ((Bool) -> Void)? = nil) -> UIView {
        var dx: CGFloat = 0, dy: CGFloat = 0, ds: CGFloat = 0
        if edge == .none {
            ds = amount / 2
        } else if edge == .left || edge == .right {
            dx = (edge == .left ? -1 : 1) * self.bounds.size.width * amount;
            dy = 0
        } else {
            dx = 0
            dy = (edge == .top ? -1 : 1) * self.bounds.size.height * amount;
        }
        UIView.animateKeyframes(
            withDuration: duration, delay: delay, options: .calculationModeLinear, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.28) {
                    let t = CGAffineTransform(translationX: dx, y: dy)
                    self.transform = t.scaledBy(x: 1 + ds, y: 1 + ds)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.28, relativeDuration: 0.28) {
                    self.transform = .identity
                }
                UIView.addKeyframe(withRelativeStartTime: 0.56, relativeDuration: 0.28) {
                    let t = CGAffineTransform(translationX: dx * 0.5, y: dy * 0.5)
                    self.transform = t.scaledBy(x: 1 + ds * 0.5, y: 1 + ds * 0.5)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.84, relativeDuration: 0.16) {
                    self.transform = .identity
                }
            }, completion: completion)
        return self
    }
    
    /**
     Causes the view to shake, either toward a particular edge or in all directions (if "toward" is
     .None).
     - Parameters:
     - toward: the edge to shake toward, or .None to shake in all directions
     - amount: distance to shake, expressed as a fraction of the view's size
     - duration: duration of the animation, in seconds
     - delay: delay before the animation starts, in seconds
     - completion: block executed when the animation ends
     */
    @discardableResult func shake(toward edge: SimpleAnimationEdge = .none,
                                  amount: CGFloat = 0.15,
                                  duration: TimeInterval = 0.6,
                                  delay: TimeInterval = 0,
                                  completion: ((Bool) -> Void)? = nil) -> UIView {
        let steps = 8
        let timeStep = 1.0 / Double(steps)
        var dx: CGFloat, dy: CGFloat
        if edge == .left || edge == .right {
            dx = (edge == .left ? -1 : 1) * self.bounds.size.width * amount;
            dy = 0
        } else {
            dx = 0
            dy = (edge == .top ? -1 : 1) * self.bounds.size.height * amount;
        }
        UIView.animateKeyframes(
            withDuration: duration, delay: delay, options: .calculationModeCubic, animations: {
                var start = 0.0
                for i in 0..<(steps - 1) {
                    UIView.addKeyframe(withRelativeStartTime: start, relativeDuration: timeStep) {
                        self.transform = CGAffineTransform(translationX: dx, y: dy)
                    }
                    if (edge == .none && i % 2 == 0) {
                        swap(&dx, &dy)  // Change direction
                        dy *= -1
                    }
                    dx *= -0.85
                    dy *= -0.85
                    start += timeStep
                }
                UIView.addKeyframe(withRelativeStartTime: start, relativeDuration: timeStep) {
                    self.transform = .identity
                }
            }, completion: completion)
        return self
    }
    
    private func offsetFor(edge: SimpleAnimationEdge) -> CGPoint {
        if let parentSize = self.superview?.frame.size {
            switch edge {
            case .none: return CGPoint.zero
            case .top: return CGPoint(x: 0, y: -frame.maxY)
            case .bottom: return CGPoint(x: 0, y: parentSize.height - frame.minY)
            case .left: return CGPoint(x: -frame.maxX, y: 0)
            case .right: return CGPoint(x: parentSize.width - frame.minX, y: 0)
            }
        }
        return .zero
    }
}
