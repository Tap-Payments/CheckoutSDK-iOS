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
    
    var rates:[String:Double] = [:]
    var loadedWebPages:Int = 0
    var fadeOutAnimationDuration:Double = 0.3
    var fadeInAnimationDuration:Double = 0.7
    var fadeInAnimationDelay:Double  {
        return fadeOutAnimationDuration - 0.1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addDefaultViews()
        sharedCheckoutDataManager.UIDelegate = self
        tapVerticalView.delegate = self
        // Do any additional setup after  the view.
        tapVerticalView.updateKeyBoardHandling(with: true)
        createDefaultViewModels()
        // Setting up the number of lines and doing a word wrapping
        UILabel.appearance(whenContainedInInstancesOf:[UIAlertController.self]).numberOfLines = 2
        UILabel.appearance(whenContainedInInstancesOf:[UIAlertController.self]).lineBreakMode = .byWordWrapping
        addGloryViews()
    }
    
    func addDefaultViews() {
        
        let tapBlurView:TapCheckoutBlurView = .init(frame: view.bounds)
        
        // Add the views
        view.addSubview(tapBlurView)
        view.addSubview(tapVerticalView)
        
        view.backgroundColor = .clear
        tapVerticalView.backgroundColor = .clear
        
        // Add the constraints
        tapBlurView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        tapVerticalView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        view.layoutIfNeeded()
    }
    
    func createDefaultViewModels() {
        
        sharedCheckoutDataManager.dataHolder.viewModels.tapMerchantViewModel.delegate = self
        
        sharedCheckoutDataManager.dataHolder.viewModels.tapAmountSectionViewModel.delegate = self
        
        tapActionButtonViewModel.buttonStatus = .InvalidPayment
        webViewModel.delegate = self
        
        sharedCheckoutDataManager.dataHolder.viewModels.tapSaveCardSwitchViewModel.delegate = self
        
        createTabBarViewModel()
        dragView.delegate = self
        
        dragView.changeCloseButton(to: sharedCheckoutDataManager.dataHolder.viewModels.closeButtonStyle)
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
        self.tapVerticalView.add(views: [dragView,sharedCheckoutDataManager.dataHolder.viewModels.tapMerchantViewModel.attachedView,sharedCheckoutDataManager.dataHolder.viewModels.tapAmountSectionViewModel.attachedView,sharedCheckoutDataManager.dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.attachedView,sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.attachedView,sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView,sharedCheckoutDataManager.dataHolder.viewModels.tapSaveCardSwitchViewModel.attachedView], with: [.init(for: .fadeIn)])
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
}


extension TapBottomCheckoutControllerViewController:TapAmountSectionViewModelDelegate {
    func showItemsClicked() {
        self.view.endEditing(true)
        self.removeView(viewType: TapAmountSectionView.self, with: .init(for: .fadeOut, with: fadeOutAnimationDuration), and: true, skipSelf: true)
        tapVerticalView.hideActionButton()
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: { [weak self] in
            self!.sharedCheckoutDataManager.dataHolder.viewModels.tapCurrienciesChipHorizontalListViewModel.attachedView.alpha = 0
            self!.sharedCheckoutDataManager.dataHolder.viewModels.tapItemsTableViewModel.attachedView.alpha = 0
            self?.tapVerticalView.add(views: [self!.sharedCheckoutDataManager.dataHolder.viewModels.tapCurrienciesChipHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapItemsTableViewModel.attachedView], with: [.init(for: .fadeIn, with:self!.fadeInAnimationDuration, wait: self!.fadeInAnimationDelay)])
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
        self.removeView(viewType: TapChipHorizontalList.self, with: .init(for: .fadeOut, with: fadeOutAnimationDuration), and: true)
        // Now let us add back the default views
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: { [weak self] in
            self?.tapVerticalView.showActionButton(fadeInDuation:self!.fadeInAnimationDuration,fadeInDelay:self!.fadeInAnimationDelay)
            self?.tapVerticalView.add(views: [self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapSaveCardSwitchViewModel.attachedView], with: [.init(for: .fadeIn, with:self!.fadeInAnimationDuration, wait: self!.fadeInAnimationDelay)])
        })
    }
    
    func amountSectionClicked() {
        //showAlert(title: "Amount Section", message: "The user clicked on the amount section, do you want me to do anything?")
    }
    
    func closeScannerClicked() {
        tapVerticalView.closeScanner()
        sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.scanerClosed()
        DispatchQueue.main.async{ [weak self] in
            self?.tapVerticalView.add(views: [self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapSaveCardSwitchViewModel.attachedView], with: [.init(for: .fadeIn, with:self!.fadeInAnimationDuration, wait: self!.fadeInAnimationDelay)])
        }
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
            self?.tapVerticalView.add(views: [self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView,self!.sharedCheckoutDataManager.dataHolder.viewModels.tapSaveCardSwitchViewModel.attachedView], with: [.init(for: .fadeIn, with:self!.fadeInAnimationDuration, wait: self!.fadeInAnimationDelay)])
        }
        //showWebView(with: URL(string:"https://www.google.com")!)
    }
    
    func showScanner() {
        tapVerticalView.showScanner(with: sharedCheckoutDataManager)
    }
    
    func showWebView(with url:URL, and navigationDelegate:TapWebViewModelDelegate? = nil) {
        // Stop the dismiss on swipe feature, because when we remove all views, the height will be minium than the threshold, ending up the whole sheet being dimissed
        let originalDismissOnSwipeValue = disableAutoDismiss()
        
        self.removeView(viewType: TapDragHandlerView.self, with: .init(for: .fadeOut, with: fadeOutAnimationDuration), and: true, skipSelf: true)
        
        webViewModel = .init()
        webViewModel.delegate = navigationDelegate
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
            self?.tapVerticalView.hideActionButton()
            self?.tapVerticalView.add(view: self!.webViewModel.attachedView, with: [.init(for: .fadeIn, with:self!.fadeInAnimationDuration, wait: self!.fadeInAnimationDelay)],shouldFillHeight: true)
            self?.webViewModel.load(with: url)
            // Set it back to swipe on dismiss
            TapCheckout.sharedCheckoutManager().dataHolder.viewModels.swipeDownToDismiss = originalDismissOnSwipeValue
        }
    }
    
    
    func closeWebView() {
        
        // Stop the dismiss on swipe feature, because when we remove all views, the height will be minium than the threshold, ending up the whole sheet being dimissed
        let originalDismissOnSwipeValue = disableAutoDismiss()
        
        self.view.endEditing(true)
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
}






extension TapBottomCheckoutControllerViewController {

    
    func handleTelecomPayment(for cardBrand: CardBrand, with validation: CrardInputTextFieldStatusEnum) {
        if validation == .Valid {
            tapActionButtonViewModel.buttonStatus = .ValidPayment
            let payAction:()->() = { self.startPayment(then:true) }
            tapActionButtonViewModel.buttonActionBlock = payAction
            sharedCheckoutDataManager.dataHolder.viewModels.tapSaveCardSwitchViewModel.cardState = .validTelecom
        }else {
            tapActionButtonViewModel.buttonStatus = .InvalidPayment
            tapActionButtonViewModel.buttonActionBlock = {}
            sharedCheckoutDataManager.dataHolder.viewModels.tapSaveCardSwitchViewModel.cardState = .invalidTelecom
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
    
    func showHint(with status: TapHintViewStatusEnum) {
        let hintViewModel:TapHintViewModel = .init(with: status)
        let hintView:TapHintView = hintViewModel.createHintView()
        tapVerticalView.attach(hintView: hintView, to: TapCardTelecomPaymentView.self,with: false)
    }
    
    func hideHints() {
        tapVerticalView.removeAllHintViews()
    }
    
    func cardDataChanged(tapCard: TapCard) {
        // When a new card data is entered, then we need to deselct any selected gatways like SAVED CARDS or Redirections chips
        sharedCheckoutDataManager.dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.deselectAll()
        sharedCheckoutDataManager.dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.deselectAll()
        // Let us inform the checkout shared manager about the new card please
        sharedCheckoutDataManager.dataHolder.transactionData.currentCard = (tapCard.tapCardNumber?.tap_length ?? 0 > 0) ? tapCard : nil
    }
    
    func brandDetected(for cardBrand: CardBrand, with validation: CrardInputTextFieldStatusEnum) {
        //tapActionButtonViewModel.buttonStatus = (validation == .Valid) ? .ValidPayment : .InvalidPayment
        // Based on the detected brand type we decide the action button status
        if cardBrand.brandSegmentIdentifier == "telecom" {
            handleTelecomPayment(for: cardBrand, with: validation)
        }else if cardBrand.brandSegmentIdentifier == "cards" {
            sharedCheckoutDataManager.handleCardValidationStatus(for:cardBrand, with: validation)
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
    
    
    func didChangeState(state: TapSwitchEnum) {
        
        
        changeBlur(to: state != .none)
        
        if state != .none {
            self.tapActionButtonViewModel.buttonStatus = .SaveValidPayment
        }
        
        //self.tapActionButtonViewModel.buttonStatus = (state == .none) ? .ValidPayment : .SaveValidPayment
        
    }
}

extension TapBottomCheckoutControllerViewController:TapWebViewModelDelegate {
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

extension TapBottomCheckoutControllerViewController:TapDragHandlerViewDelegate {
    
    func closeButtonClicked() {
        delegate?.dismissMySelfClicked()
    }
}



extension TapBottomCheckoutControllerViewController:TapCheckoutSharedManagerUIDelegate {
    
    func attach(hintView: TapHintView, to: AnyClass, with animations: Bool) {
        tapVerticalView.attach(hintView: hintView, to: to, with: animations)
    }
    
    
    func showSavedCardOTPView(with authenticationID:String = "") {
        tapVerticalView.showGoPaySignInForm(with: self, and: sharedCheckoutDataManager.dataHolder.viewModels.goPayBarViewModel!,hintViewStatus: .SavedCardOTP, for: authenticationID)
    }
    
    func hideSavedCardOTP() {
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
    
    func removeView(view: UIView) {
        tapVerticalView.remove(view: view)
    }
    
    /**
     Will call the root controller to display a needed alert controller
     - Parameter alert: The UIAlertController to be displayed
     */
    func show(alert:UIAlertController) {
        present(alert, animated: true, completion: nil)
    }
    
    func enableInteraction(with status: Bool) {
        //view.isUserInteractionEnabled = status
    }
}
