//
//  TapCheckoutSharedManager+UIKitDelegates.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/29/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation
import TapUIKit_iOS
import CommonDataModelsKit_iOS
import TapApplePayKit_iOS
/// Has the needed methods to act upon fired events from the uikit based on user activity
internal extension TapCheckout {
    
    /**
     Used to set the status and the action of the tap checkout atction button
     - Parameter status: The button status we want to set
     - parameter actionBlock: The block to execute when the button is clicked
     */
    func chanegActionButton(status:TapActionButtonStatusEnum?, actionBlock:(()->())? = nil) {
        // Change the button status if provided
        if let status = status {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue:  TapConstantManager.TapActionSheetStatusNotification), object: nil, userInfo: [TapConstantManager.TapActionSheetStatusNotification:status] )
        }
        // Change the button action if provided
        if let actionBlock = actionBlock {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue:  TapConstantManager.TapActionSheetBlockNotification), object: nil, userInfo: [TapConstantManager.TapActionSheetBlockNotification:actionBlock] )
        }
    }
    
// MARK:- goPay login form delegate methods
    
    /**
     This method will be called whenever the user wants to sign in with email and passwod
     - Parameter email: the email the user needs to login wiht
     - Parameter password: the password entered by the user
     */
    func signIn(email:String,password:String) {
        goPaySign(with: ["email":email,"password":password])
    }
    
    /**
     This method will be called whenever the user wants to sign in with  phone after verifying the phone ownership
     - Parameter phone: the phone verified with OTP
     - Parameter otp:   the otp entered
     */
    func signIn(phone:String,otp:String) {
        goPaySign(with: ["phone":phone,"otp":otp])
    }
    
    /**
     Perofm the api call to validate the goPay credentials
     - Parameter body: The body you want to send to the api request will has to have email & password or phone & OTP
     */
    func goPaySign(with body:[String:String]) {
        // STart loading the button
        dataHolder.viewModels.tapActionButtonViewModel.startLoading()
        
        // perform the login gopay api call
        NetworkManager.shared.makeApiCall(routing: .GoPayLoginAPI, resultType: TapGoPayLoginResponseModel.self) { [weak self] (session, result, error) in
            
            guard let goPayLoginModel:TapGoPayLoginResponseModel = result as? TapGoPayLoginResponseModel else {
                self?.dataHolder.viewModels.tapActionButtonViewModel.endLoading(with: false)
                return }
            
            // Save the result for next checkout
            UserDefaults.standard.set(goPayLoginModel.success, forKey: TapCheckoutConstants.GoPayLoginUserDefaultsKey)
            self?.dataHolder.transactionData.loggedInToGoPay = goPayLoginModel.success
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) { [weak self] in
                self?.UIDelegate?.goPaySignIn(status: goPayLoginModel.success)
            }
        } onError: { (session, result, error) in
            
        }
    }
}



extension TapCheckout:TapChipHorizontalListViewModelDelegate {
    public func didShowDisabledItems(isShow showingDisabledItem: Bool) {
        dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.shouldShowRightButton(show: showingDisabledItem)
    }
    
    
    public func logoutChip(for viewModel:TapLogoutChipViewModel) {}
    public func didSelect(item viewModel: GenericTapChipViewModel) {}
    public func headerLeftButtonClicked(in headerType: TapHorizontalHeaderType) {}
    public func goPay(for viewModel: TapGoPayViewModel) {}
    
   
    
    public func deselectedAll() {
        // Disable the pay button regarding its current state
        dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .InvalidPayment
        
        // Deselect selected chips before starting the edit mode
        dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.deselectAll()
        dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.deselectAll()
        
        // We will need to reset the card data if we are currently selecting a saved card and we are going to deselect it
        if dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView.cardInputView.cardUIStatus == .SavedCard {
            resetCardData(shouldFireCardDataChanged: true)
        }
        
        // let the card come back
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView.alpha = 1
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView.isUserInteractionEnabled = true
        
        // If were were showing a currency widget let us remove it
        removeCurrencyWidget()
    }
    
    public func headerRightButtonClicked(in headerType: TapHorizontalHeaderType) {
        // Disable the pay button regarding its current state
        dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .InvalidPayment
        
        // Deselect selected chips before starting the edit mode
        dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.deselectAll()
        dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.deselectAll()
        
        // Inform the lists of saved chips to start editing
        dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.editMode(changed: true)
        dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.editMode(changed: true)
        
        // Disable the card form and reset it
        resetCardData(shouldFireCardDataChanged: true)
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView.alpha = 0.7
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView.isUserInteractionEnabled = false
    }
    
    public func headerEndEditingButtonClicked(in headerType: TapHorizontalHeaderType) {
        // Deselect selected chips before ending the edit mode
        dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.deselectAll()
        dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.deselectAll()
        
        // Inform the lists of saved chips to end editing
        dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.editMode(changed: false)
        dataHolder.viewModels.tapGoPayChipsHorizontalListViewModel.editMode(changed: false)
        
        // Renable the card form
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView.alpha = 1
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView.isUserInteractionEnabled = true
    }
    
    public func applePayAuthoized(for viewModel: ApplePayChipViewCellModel, with token: TapApplePayToken) {
        // make a haptic feedback
        generateHapticFeedbackForChipClicking()
        
        // log selecting apple pay chip event
        setLoggingCustomerData()
        logBF(message: "Apple pay raw token : \(token.stringAppleToken ?? "")", tag: .EVENTS)
        // Save the selected payment option model for further processing
        guard let applePayPaymentOption = fetchPaymentOption(with: viewModel.paymentOptionIdentifier) else {
            handleError(session: nil, result: nil, error: "Cannot find apple pay payment option with id \(viewModel.paymentOptionIdentifier) from the payment/types api respons.")
            return
        }
        dataHolder.transactionData.selectedPaymentOption = applePayPaymentOption
        // The button should look like a valid payment mode
        chanegActionButton(status: .ValidPayment)
        // Start the process :)
        tapCheckoutScreenDelegate?.log?(string: token.stringAppleToken ?? "")
        processCheckout(with: applePayPaymentOption, andApplePayToken: token)
    }
    
    public func savedCard(for viewModel: SavedCardCollectionViewCellModel) {
        // make a haptic feedback
        generateHapticFeedbackForChipClicking()
        
        //dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .ValidPayment
        // Check the type of saved card source
        if viewModel.listSource == .GoPayListHeader {
            handleGoPaySavedCard(for: viewModel)
        }else {
            handleSavedCard(for: viewModel)
        }
    }
    
    public func gateway(for viewModel: GatewayChipViewModel) {
        // make a haptic feedback
        generateHapticFeedbackForChipClicking()
        
        // let us first check if it is enabled or disabled
        if viewModel.isDisabled {
            handleDisabledGateway(for: viewModel)
        }else{
            handleEnabledGateway(for: viewModel)
        }
    }
    
    /// Will handle the logic needed after selecring a disabled gateway
    /// - Parameter for viewModel: The view model for the disabled selected gateway
    internal func handleDisabledGateway(for viewModel: GatewayChipViewModel) {
        // let us clear the card element
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.changeEnableStatus(to: false, doPostLogic: true)
        // Disable the pay button regarding its current state
        dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .InvalidPayment
        chanegActionButton(status: .InvalidPayment, actionBlock: nil)
        
        guard let paymentOption:PaymentOption = fetchPaymentOption(with: viewModel.paymentOptionIdentifier) else { return }
        
        showOrUpdateCurrencyWidget(paymentOption: paymentOption, type: TapCurrencyWidgetType.disabledPaymentOption, in: .PaymentChipsList)
    }
    
    /// This will remove the currency widget if it is already shown and nulify it
    internal func removeCurrencyWidget() {
        if let nonNullCurrencyViewModel = dataHolder.viewModels.tapCurrencyWidgetModel {
            // This means, it is already defined and being displayed now
            // let us remove it as UI first then nulify it
            UIDelegate?.removeView(view: nonNullCurrencyViewModel.attachedView, with: .init(for: .fadeOut, with: 0.25, and: .bottom))
            dataHolder.viewModels.tapCurrencyWidgetModel = nil
        }
    }
    
    /// Will handle showing or update currency widget
    /// - Parameter paymentOption PaymentOption: the payment option to be shown
    /// - Parameter type: The type of the widget, are we displaying a chip for an enabled or a disabled selected payment option
    /// - Parameter in position  PaymentOption: the position to be displayed e.g. PAYMENT CHIPS or CARD
    internal func showOrUpdateCurrencyWidget(paymentOption: PaymentOption, type: TapCurrencyWidgetType, in position: CurrencyWidgetPositionEnum) {
        // first let us see if we are allowed to show the currency widget based on its type or not
        guard shouldShowCurrencyWidget(for: paymentOption, and: position) else {
            // This means, the selected payment option doesn't meet all requirements needed to show a related currency widget
            // as a defensive coding, we will remove any exisiting currency widget (shouldn't happen)
            removeCurrencyWidget()
            return
        }
        
        // If we reached here,this means the user did change his currency or started selecting another payment option. Then we will clear the last confirmed widget for now
        lastConfirmedCurrencyWidget = nil
        
        // Then if the currency widget is already visible, we just need to update the content, otherwise we add it to the view
        guard let nonNullViewModel = dataHolder.viewModels.tapCurrencyWidgetModel else {
            // This means, it is nil and it is not currently visible on the screen
            dataHolder.viewModels.tapCurrencyWidgetModel = TapCurrencyWidgetViewModel(convertedAmounts: fetchAmountedCurrencies(for: paymentOption), paymentOption: paymentOption, type: type)
            dataHolder.viewModels.tapCurrencyWidgetModel?.setTapCurrencyWidgetViewModelDelegate(delegate: self)
            UIDelegate?.showCurrencyWidget(for: dataHolder.viewModels.tapCurrencyWidgetModel!, in: position)
            
            return
        }
        // This means, it is already visible and we just need to update its content
        nonNullViewModel.updateData(with:  fetchAmountedCurrencies(for: paymentOption), and: paymentOption)
    }
    
    
    /// Will handle the logic needed after selecring an enabled gateway
    /// - Parameter for viewModel: The view model for the enabled selected gateway
    internal func handleEnabledGateway(for viewModel: GatewayChipViewModel) {
        // First reset the enetred data in the card form if any if the current visible status is for a saved card view
        if dataHolder.viewModels.tapCardTelecomPaymentViewModel.attachedView.cardInputView.cardUIStatus == .SavedCard {
            resetCardData(shouldFireCardDataChanged: false)
        }else{
            // Otherwise we have to disable the card view
            dataHolder.viewModels.tapCardTelecomPaymentViewModel.changeEnableStatus(to: false, doPostLogic: true)
        }
        // Save the selected payment option model for further processing
        dataHolder.transactionData.selectedPaymentOption = fetchPaymentOption(with: viewModel.paymentOptionIdentifier)
        // Log the event of selecting a gateway chip
        setLoggingCustomerData()
        logBF(message: "Payment scheme selected: title : \(dataHolder.transactionData.selectedPaymentOption?.title ?? "") & ID : \(dataHolder.transactionData.selectedPaymentOption?.identifier ?? "")", tag: .EVENTS)
        // Make the payment button in a Valid payment mode
        // Make the button action to start the paymet with the selected gateway
        // Start the payment with the selected payment option
        let gatewayActionBlock:()->() = { self.processCheckout(with: self.dataHolder.transactionData.selectedPaymentOption!) }
        chanegActionButton(status: .ValidPayment, actionBlock: gatewayActionBlock)
        updateCurrencyWidgetForEnabledGateway(for: viewModel)
    
    }
    /// Handle showing or removing currency widget for enabled gateway method
    /// - Parameter for viewModel: The view model for the enabled selected gateway
    internal func updateCurrencyWidgetForEnabledGateway(for viewModel: GatewayChipViewModel) {
        guard let paymentOption:PaymentOption = fetchPaymentOption(with: viewModel.paymentOptionIdentifier) else {
            removeCurrencyWidget()
            return
        }
        // Check if payment method enabled and have another currencies options
        // Current selected payment option has same currency as transaction currency user not selected another currency
        // Selected payment option doesn't have extra supported currencies
        guard dataHolder.transactionData.transactionCurrencyValue.currency != dataHolder.viewModels.currentUsedCurrency, paymentOption.supportedCurrencies.count > 1  else {
            removeCurrencyWidget()
            return
        }
        // Remove the selected currency from payment option list
        var updatedSupportedCurrencies = paymentOption.supportedCurrencies
        updatedSupportedCurrencies.removeAll {
            $0 == dataHolder.viewModels.currentUsedCurrency
        }
        let updatedPaymentOption = PaymentOption(identifier: paymentOption.identifier,
                                                 brand: paymentOption.brand,
                                                 title: paymentOption.title,
                                                 titleAr: paymentOption.titleAr,
                                                 displayableTitle: paymentOption.displayableTitle,
                                                 backendImageURL: paymentOption.backendImageURL,
                                                 isAsync: paymentOption.isAsync,
                                                 paymentType: paymentOption.paymentType,
                                                 sourceIdentifier: paymentOption.sourceIdentifier,
                                                 supportedCardBrands: paymentOption.supportedCardBrands,
                                                 supportedCurrencies: updatedSupportedCurrencies,
                                                 orderBy: paymentOption.orderBy,
                                                 threeDLevel: paymentOption.threeDLevel,
                                                 savedCard: paymentOption.savedCard,
                                                 extraFees: paymentOption.extraFees,
                                                 paymentOptionsLogos:paymentOption.paymentOptionsLogos,
                                                 buttonStyle: paymentOption.buttonStyle)
      
        // Update or show currency widget for the another payment option currency
        showOrUpdateCurrencyWidget(paymentOption: updatedPaymentOption, type: TapCurrencyWidgetType.enabledPaymentOption, in: .PaymentChipsList)
    }
    
    public func currencyChip(for viewModel: CurrencyChipViewModel) {
        // make a haptic feedback
        generateHapticFeedbackForChipClicking()
        removeCurrencyWidget()
        dataHolder.transactionData.transactionUserCurrencyValue = viewModel.currency
        setLoggingCustomerData()
        logBF(message: "Currency changed to : \( viewModel.currency.displaybaleSymbol )", tag: .EVENTS)
    }
    
    public func deleteChip(for viewModel: SavedCardCollectionViewCellModel) {
        askForCardDeletion(with: viewModel)
    }
    
    /// Will make a haptic feedback to indicate selecting a chip
    internal func generateHapticFeedbackForChipClicking() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
    }
}

//MARK: The currency widget delegate
extension TapCheckout: TapCurrencyWidgetViewModelDelegate {
    
    public func confirmClicked(for viewModel: TapUIKit_iOS.TapCurrencyWidgetViewModel) {
        // make sure all is good we can fetch the currency and the payment option
        guard let selectedCurrency = viewModel.selectedAmountCurrency else { return }
        let selectedPaymentOption:PaymentOption = viewModel.paymentOption
        
        // let us set the currency first
        // We will have to declare to the checkout manager that we are coming from the currency widget, so it doesn't apply sorting
        TapCheckout.sharedCheckoutManager().currencyConvertedFromWidget = true
        dataHolder.transactionData.transactionUserCurrencyValue = selectedCurrency
        // let us remove the widget
        removeCurrencyWidget()
        // Store this currency widget view model, so we don't reshow it again for same currency + same payment option
        TapCheckout.sharedCheckoutManager().lastConfirmedCurrencyWidget = viewModel
        // set the payment option to be auto selected based on its type, whether we will select the chip or revalidate the card element
        if selectedPaymentOption.paymentType == .Card  {
            dataHolder.viewModels.tapCardTelecomPaymentViewModel.reValidateTheCard()
            //handleCardValidationStatus(for: selectedPaymentOption.brand, with: dataHolder.viewModels.tapCardTelecomPaymentViewModel.decideHintStatus(isCVVFocused: false) == .None ? .Valid : .Incomplete, cardStatusUI: .NormalCard, isCVVFocused: false)
        } else {
            dataHolder.viewModels.tapGatewayChipHorizontalListViewModel.selectCell(with: selectedPaymentOption.identifier, shouldAnimate: true)
        }
    }
    
}
