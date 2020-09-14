//
//  TapBottomCheckoutControllerViewController.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/3/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import UIKit
import SnapKit

internal class TapBottomCheckoutControllerViewController: UIViewController {
    
    let sharedCheckoutDataManager:TapCheckoutSharedManager = .sharedCheckoutManager()
    
    var delegate:ToPresentAsPopupViewControllerDelegate?
    var tapVerticalView: TapVerticalView = .init()
    
    
    var tapActionButtonViewModel: TapActionButtonViewModel {
        return sharedCheckoutDataManager.tapActionButtonViewModel
    }
    
    
    var dragView:TapDragHandlerView = .init()
    
    var webViewModel:TapWebViewModel = .init()
    
    var rates:[String:Double] = [:]
    var loadedWebPages:Int = 0
    
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
        
        sharedCheckoutDataManager.tapMerchantViewModel.delegate = self
        
        sharedCheckoutDataManager.tapAmountSectionViewModel.delegate = self
        
        tapActionButtonViewModel.buttonStatus = .InvalidPayment
        webViewModel.delegate = self
        
        sharedCheckoutDataManager.tapSaveCardSwitchViewModel.delegate = self
        
        createTabBarViewModel()
        createGatewaysViews()
        dragView.delegate = self
    }
    
    func createTabBarViewModel() {
        
        sharedCheckoutDataManager.tapCardTelecomPaymentViewModel.delegate = self
    }
    
    func addGloryViews() {
        
        // The button
        self.tapVerticalView.setupActionButton(with: tapActionButtonViewModel)
        // The initial views
        self.tapVerticalView.add(views: [dragView,sharedCheckoutDataManager.tapMerchantViewModel.attachedView,sharedCheckoutDataManager.tapAmountSectionViewModel.attachedView,sharedCheckoutDataManager.tapGoPayChipsHorizontalListViewModel.attachedView,sharedCheckoutDataManager.tapGatewayChipHorizontalListViewModel.attachedView,sharedCheckoutDataManager.tapCardTelecomPaymentViewModel.attachedView,sharedCheckoutDataManager.tapSaveCardSwitchViewModel.attachedView], with: [.init(for: .fadeIn)])
    }
    
    
    func showAlert(title:String,message:String) {
        let alertController:UIAlertController = .init(title: title, message: message, preferredStyle: .alert)
        let okAction:UIAlertAction = .init(title: "OK", style: .destructive, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    func createGatewaysViews() {
        
        
        sharedCheckoutDataManager.tapCurrienciesChipHorizontalListViewModel.delegate = self
        
        sharedCheckoutDataManager.tapGatewayChipHorizontalListViewModel.delegate = self

        sharedCheckoutDataManager.tapGoPayChipsHorizontalListViewModel.delegate = self
    }
    
    
    func showGoPay() {
        tapVerticalView.showGoPaySignInForm(with: self, and: sharedCheckoutDataManager.goPayBarViewModel!)
    }
    
    /**
     Update the items list UI wise when a new currency is selected
     - Parameter currency: The new selected currency
     */
    func updateItemsList(with currency:TapCurrencyCode) {
        /*tapItemsTableViewModel.dataSource.forEach { (genericCellModel) in
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
        print("DELEGATE CALL BACK WITH SIZE \(newSize) and Frame of :\(frame)")
        guard let delegate = delegate else { return }
        
        delegate.changeHeight(to: newSize.height + frame.origin.y + view.safeAreaBottom)
    }
    
}


extension TapBottomCheckoutControllerViewController:TapMerchantHeaderViewDelegate {
    func iconClicked() {
        showAlert(title: "Merchant Header", message: "You can make any action needed based on clicking the Profile Logo ;)")
    }
    func merchantHeaderClicked() {
        showAlert(title: "Merchant Header", message: "The user clicked on the header section, do you want me to do anything?")
    }
}


extension TapBottomCheckoutControllerViewController:TapAmountSectionViewModelDelegate {
    func showItemsClicked() {
        self.view.endEditing(true)
        self.tapVerticalView.remove(viewType: TapAmountSectionView.self, with: .init(), and: true, skipSelf: true)
        tapVerticalView.hideActionButton()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(80), execute: { [weak self] in
            self!.sharedCheckoutDataManager.tapCurrienciesChipHorizontalListViewModel.attachedView.alpha = 0
            self!.sharedCheckoutDataManager.tapItemsTableViewModel.attachedView.alpha = 0
            self?.tapVerticalView.add(views: [self!.sharedCheckoutDataManager.tapCurrienciesChipHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.tapItemsTableViewModel.attachedView], with: [.init(for: .fadeIn)])
            if let locale = TapLocalisationManager.shared.localisationLocale, locale == "ar" {
                self?.sharedCheckoutDataManager.tapCurrienciesChipHorizontalListViewModel.refreshLayout()
            }
        })
    }
    
    
    func closeItemsClicked() {
        self.view.endEditing(true)
        self.tapVerticalView.remove(viewType: TapChipHorizontalList.self, with: .init(), and: true)
        
        DispatchQueue.main.async{ [weak self] in
            self?.tapVerticalView.showActionButton()
            self?.tapVerticalView.add(views: [self!.sharedCheckoutDataManager.tapGoPayChipsHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.tapGatewayChipHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.tapCardTelecomPaymentViewModel.attachedView,self!.sharedCheckoutDataManager.tapSaveCardSwitchViewModel.attachedView], with: [.init(for: .fadeIn)])
        }
    }
    
    func amountSectionClicked() {
        showAlert(title: "Amount Section", message: "The user clicked on the amount section, do you want me to do anything?")
    }
    
    func closeScannerClicked() {
        tapVerticalView.closeScanner()
        sharedCheckoutDataManager.tapCardTelecomPaymentViewModel.scanerClosed()
        DispatchQueue.main.async{ [weak self] in
            self?.tapVerticalView.add(views: [self!.sharedCheckoutDataManager.tapGoPayChipsHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.tapGatewayChipHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.tapCardTelecomPaymentViewModel.attachedView,self!.sharedCheckoutDataManager.tapSaveCardSwitchViewModel.attachedView], with: [.init(for: .fadeIn)])
        }
    }
    
    
    func closeGoPayClicked() {
        sharedCheckoutDataManager.tapGatewayChipHorizontalListViewModel.deselectAll()
        tapVerticalView.closeGoPaySignInForm()
        
        DispatchQueue.main.async { [weak self] in
            self?.tapVerticalView.add(views: [self!.sharedCheckoutDataManager.tapGoPayChipsHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.tapGatewayChipHorizontalListViewModel.attachedView,self!.sharedCheckoutDataManager.tapCardTelecomPaymentViewModel.attachedView,self!.sharedCheckoutDataManager.tapSaveCardSwitchViewModel.attachedView], with: [.init(for: .fadeIn)])
        }
    }
    
    func showScanner() {
        tapVerticalView.showScanner(with: self)
    }
    
    func showWebView(with url:URL) {
        
        self.tapVerticalView.remove(viewType: TapMerchantHeaderView.self, with: .init(), and: true)
        
        self.tapActionButtonViewModel.startLoading()
        webViewModel = .init()
        webViewModel.delegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) { [weak self] in
            self?.tapVerticalView.hideActionButton()
            self?.tapVerticalView.add(view: self!.webViewModel.attachedView, with: [.init(for: .fadeIn)],shouldFillHeight: true)
            self?.webViewModel.load(with: url)
        }
    }
    
    
    func closeWebView() {
        self.view.endEditing(true)
        self.tapVerticalView.remove(view: webViewModel.attachedView, with: .init(for: .fadeOut))
        self.tapVerticalView.showActionButton()
        
        self.tapActionButtonViewModel.startLoading()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) { [weak self] in
            self?.tapActionButtonViewModel.endLoading(with: true, completion: {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    self?.dismiss(animated: true, completion: nil)
                }
            })
        }
    }
    
    
    func hideGoPay() {
        self.view.endEditing(true)
        self.tapVerticalView.remove(view: sharedCheckoutDataManager.tapGoPayChipsHorizontalListViewModel.attachedView, with: .init(for: .fadeOut))
        self.sharedCheckoutDataManager.tapGatewayChipHorizontalListViewModel.editMode(changed: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(0)) {
            self.sharedCheckoutDataManager.tapGatewayChipHorizontalListViewModel.headerType = .GatewayListHeader
            UserDefaults.standard.set(false, forKey: TapCheckoutConstants.GoPayLoginUserDefaultsKey)
            self.sharedCheckoutDataManager.loggedInToGoPay = false
        }
    }
}






extension TapBottomCheckoutControllerViewController:TapChipHorizontalListViewModelDelegate {
    func logoutChip(for viewModel: TapLogoutChipViewModel) {
        let logoutConfirmationAlert:UIAlertController = .init(title: "Are you sure you would like to sign out?", message: "The goPay cards will be hidden from the page and you will need to login again to use any of them.", preferredStyle: .alert)
        let confirmLogoutAction:UIAlertAction = .init(title: "Yes", style: .default) { [weak self] (_) in
            self?.hideGoPay()
        }
        let cancelLogoutAction:UIAlertAction = .init(title: "No", style: .cancel, handler: nil)
        logoutConfirmationAlert.addAction(confirmLogoutAction)
        logoutConfirmationAlert.addAction(cancelLogoutAction)
        present(logoutConfirmationAlert, animated: true, completion: nil)
    }
    
    
    func currencyChip(for viewModel: CurrencyChipViewModel) {
        sharedCheckoutDataManager.transactionUserCurrencyObserver.accept(viewModel.currency)
    }
    
    func applePayAuthoized(for viewModel: ApplePayChipViewCellModel, with token: TapApplePayToken) {
        showAlert(title: " Pay", message: "Token:\n\(token.stringAppleToken ?? "")")
    }
    
    func savedCard(for viewModel: SavedCardCollectionViewCellModel) {
        //showAlert(title: "\(viewModel.title ?? "") clicked", message: "Look we know that you saved the card. We promise we will make you use it soon :)")
        tapActionButtonViewModel.buttonStatus = .ValidPayment
        
        // Check the type of saved card source
        
        if viewModel.listSource == .GoPayListHeader {
            // First of all deselct any selected cards in the gateways list
            sharedCheckoutDataManager.tapGatewayChipHorizontalListViewModel.deselectAll()
            let authenticator = TapAuthenticate(reason: "Login into tap account")
            if authenticator.type != .none {
                tapActionButtonViewModel.buttonStatus = (authenticator.type == BiometricType.faceID) ? .FaceID : .TouchID
                authenticator.delegate = self
                authenticator.authenticate()
            }
        }else {
            // First of all deselct any selected cards in the goPay list
            sharedCheckoutDataManager.tapGoPayChipsHorizontalListViewModel.deselectAll()
            // perform the charge when clicking on pay button
            tapActionButtonViewModel.buttonActionBlock = { self.startPayment(then: true) }
        }
    }
    
    func gateway(for viewModel: GatewayChipViewModel) {
        //showAlert(title: "gateway cell clicked", message: "You clicked on a \(viewModel.title ?? ""). In real life example, this will open a web view to complete the payment")
        //tapActionButtonViewModel.buttonStatus = .ValidPayment
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue:  TapConstantManager.TapActionSheetStatusNotification), object: nil, userInfo: [TapConstantManager.TapActionSheetStatusNotification:TapActionButtonStatusEnum.ValidPayment] )
        
        let gatewayActionBlock:()->() = { [weak self] in
            self?.showWebView(with: URL(string: "https://www.google.com")!)
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue:  TapConstantManager.TapActionSheetBlockNotification), object: nil, userInfo: [TapConstantManager.TapActionSheetBlockNotification:gatewayActionBlock] )
    }
    
    func goPay(for viewModel: TapGoPayViewModel) {
        //showAlert(title: "GoPay cell clicked", message: "You clicked on GoPay.")
        showGoPay()
    }
    
    func headerLeftButtonClicked(in headerType: TapHorizontalHeaderType) {
        if headerType == .GatewayListHeader {
            return
        }
    }
    
    func headerRightButtonClicked(in headerType: TapHorizontalHeaderType) {
        sharedCheckoutDataManager.tapGoPayChipsHorizontalListViewModel.deselectAll()
        sharedCheckoutDataManager.tapGatewayChipHorizontalListViewModel.deselectAll()
        
        sharedCheckoutDataManager.tapGatewayChipHorizontalListViewModel.editMode(changed: true)
        sharedCheckoutDataManager.tapGoPayChipsHorizontalListViewModel.editMode(changed: true)
    }
    
    
    func headerEndEditingButtonClicked(in headerType: TapHorizontalHeaderType) {
        sharedCheckoutDataManager.tapGatewayChipHorizontalListViewModel.editMode(changed: false)
        sharedCheckoutDataManager.tapGoPayChipsHorizontalListViewModel.editMode(changed: false)
    }
    
    func deleteChip(for viewModel: SavedCardCollectionViewCellModel) {
        showAlert(title: "DELETE A CARD", message: "You wanted to delete the card \(viewModel.title ?? "")")
    }
    
    func didSelect(item viewModel: GenericTapChipViewModel) {
        
    }
    
    
    func handleTelecomPayment(for cardBrand: CardBrand, with validation: CrardInputTextFieldStatusEnum) {
        if validation == .Valid {
            tapActionButtonViewModel.buttonStatus = .ValidPayment
            let payAction:()->() = { self.startPayment(then:true) }
            tapActionButtonViewModel.buttonActionBlock = payAction
            sharedCheckoutDataManager.tapSaveCardSwitchViewModel.cardState = .validTelecom
        }else {
            tapActionButtonViewModel.buttonStatus = .InvalidPayment
            tapActionButtonViewModel.buttonActionBlock = {}
            sharedCheckoutDataManager.tapSaveCardSwitchViewModel.cardState = .invalidTelecom
        }
    }
    
    func handleCardPayment(for cardBrand: CardBrand, with validation: CrardInputTextFieldStatusEnum) {
        if validation == .Valid,
            sharedCheckoutDataManager.tapCardTelecomPaymentViewModel.decideHintStatus() == .None {
            tapActionButtonViewModel.buttonStatus = .ValidPayment
            let payAction:()->() = { self.startPayment(then:false) }
            tapActionButtonViewModel.buttonActionBlock = payAction
            sharedCheckoutDataManager.tapSaveCardSwitchViewModel.cardState = .validCard
        }else{
            tapActionButtonViewModel.buttonStatus = .InvalidPayment
            tapActionButtonViewModel.buttonActionBlock = {}
            sharedCheckoutDataManager.tapSaveCardSwitchViewModel.cardState = .invalidCard
        }
    }
    
    func startPayment(then success:Bool) {
        view.endEditing(true)
        self.tapVerticalView.remove(viewType: TapAmountSectionView.self, with: .init(), and: true, skipSelf: true)
        self.tapActionButtonViewModel.startLoading()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(3500)) {
            self.tapActionButtonViewModel.endLoading(with: success, completion: {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) {
                    self.dismiss(animated: true, completion: nil)
                }
            })
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
        sharedCheckoutDataManager.tapGatewayChipHorizontalListViewModel.deselectAll()
        sharedCheckoutDataManager.tapGoPayChipsHorizontalListViewModel.deselectAll()
    }
    
    func brandDetected(for cardBrand: CardBrand, with validation: CrardInputTextFieldStatusEnum) {
        //tapActionButtonViewModel.buttonStatus = (validation == .Valid) ? .ValidPayment : .InvalidPayment
        // Based on the detected brand type we decide the action button status
        if cardBrand.brandSegmentIdentifier == "telecom" {
            handleTelecomPayment(for: cardBrand, with: validation)
        }else if cardBrand.brandSegmentIdentifier == "cards" {
            handleCardPayment(for: cardBrand, with: validation)
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
}


extension TapBottomCheckoutControllerViewController:TapGenericTableViewModelDelegate {
    func didSelectTable(item viewModel: TapGenericTableCellViewModel) {
        return
    }
    
    func itemClicked(for viewModel: ItemCellViewModel) {
        showAlert(title: viewModel.itemTitle(), message: "You clicked on the item.. Look until now, clicking an item is worthless we are just showcasing 🙂")
    }
}

extension TapBottomCheckoutControllerViewController:TapInlineScannerProtocl {
    func tapFullCardScannerDimissed() {
        
    }
    
    func tapCardScannerDidFinish(with tapCard: TapCard) {
        
        let hintViewModel:TapHintViewModel = .init(with: .Scanned)
        let hintView:TapHintView = hintViewModel.createHintView()
        tapVerticalView.attach(hintView: hintView, to: TapAmountSectionView.self,with: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) { [weak self] in
            self?.closeScannerClicked()
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) { [weak self] in
                self?.sharedCheckoutDataManager.tapCardTelecomPaymentViewModel.setCard(with: tapCard)
            }
        }
    }
    
    func tapInlineCardScannerTimedOut(for inlineScanner: TapInlineCardScanner) {
        
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
}
