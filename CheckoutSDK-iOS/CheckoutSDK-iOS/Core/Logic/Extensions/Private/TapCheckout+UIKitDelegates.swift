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
    
    public func logoutChip(for viewModel:TapLogoutChipViewModel) {}
    public func didSelect(item viewModel: GenericTapChipViewModel) {}
    public func headerLeftButtonClicked(in headerType: TapHorizontalHeaderType) {}
    public func goPay(for viewModel: TapGoPayViewModel) {}
    
   
    
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
        
        dataHolder.viewModels.tapActionButtonViewModel.buttonStatus = .ValidPayment
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
    }
    
    public func currencyChip(for viewModel: CurrencyChipViewModel) {
        // make a haptic feedback
        generateHapticFeedbackForChipClicking()
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
