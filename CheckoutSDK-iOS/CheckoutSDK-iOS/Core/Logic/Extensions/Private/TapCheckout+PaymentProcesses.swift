//
//  TapCheckoutManager+PaymentProcesses.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/18/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// Collection of logic to process a payment with different flows
internal extension TapCheckout {
    
    /**
     Used to process a checkout process with a given payment option
     - Parameter with paymentOption: The payment option to start the checkout process with
     */
    func processCheckout(with paymentOption:PaymentOption) {
        // For all payment options types, we need to ask for extra fees first if any
        askForExtraFees(with: paymentOption) { [weak self] in
            guard let nonNullSelf = self else { return }
            nonNullSelf.startPayment(with: paymentOption)
        }
    }
    
    /**
     Used to call the correct checkout logic based on the selected payment option
     - Parameter with paymentOption: The payment option to start the checkout process with
     */
    func startPayment(with paymentOption:PaymentOption) {
        switch paymentOption.paymentType {
        case .Web:
            startWebPayment(with: paymentOption)
        default:
            return
        }
    }
    
    /**
     Used to call the correct checkout logic for the web based payment options
     - Parameter with paymentOption: The payment option to start the checkout process with
     */
    func startWebPayment(with paymentOption:PaymentOption) {
        // Change the action button to loading status
        TapCheckout.sharedCheckoutManager().dataHolder.viewModels.tapActionButtonViewModel.startLoading()
        // Create the charge request
        let chargeRequest:TapChargeRequestModel = createChargeOrAuthorizeRequestModel(with: paymentOption, token: nil, cardBIN: nil)
        TapCheckout.callChargeOrAuthorizeAPI(chargeRequestModel: chargeRequest) { [weak self] charge in
            DispatchQueue.main.async{
                guard let nonNullSelf = self else { return }
                nonNullSelf.UIDelegate?.showWebView(with: charge.transactionDetails.url!,and: nonNullSelf)
            }
        } onErrorOccured: { [weak self] error in
            self?.UIDelegate?.actionButton(shouldLoad: false, success: false, onComplete: {
                self?.UIDelegate?.dismissCheckout(with: error)
            })
        }

    }
    
    /**
     Used to confirm the extra fees for a given payment option
     - Parameter with paymentOption: The payment option to ask for its extra fees
     */
    func askForExtraFees(with paymentOption:PaymentOption, onConfimation: @escaping () -> () = {}) {
        // get the extra fees value
        let extraFeesValue:Double = calculateExtraFees(for: paymentOption)
        // check if there is an extra fee to pay or not. If the fees <= 0, then we proceed with the confirmation block right away
        guard extraFeesValue > 0 else {
            onConfimation()
            return
        }
        // Create the formatted extra fee + the formatted new total amount
        let formatter = TapAmountedCurrencyFormatter { [weak self] in
            $0.currency = self?.dataHolder.transactionData.transactionUserCurrencyValue.currency ?? .USD
            $0.locale = CurrencyLocale.englishUnitedStates
        }
        let extraFeesFormattedString = formatter.string(from: extraFeesValue) ?? "KD0.000"
        let newTotalAmountString = formatter.string(from: extraFeesValue + calculateFinalAmount()) ?? "KD0.000"
        
        // Create the formatted confirmation message
        let alertTitle      = TapLocalisationManager.shared.localisedValue(for: "ExtraFees.title",with: TapCommonConstants.pathForDefaultLocalisation())
        let alertMessage    = String(format: TapLocalisationManager.shared.localisedValue(for: "ExtraFees.message",with: TapCommonConstants.pathForDefaultLocalisation()), extraFeesFormattedString,newTotalAmountString)
        let alertConfirm    = TapLocalisationManager.shared.localisedValue(for: "ExtraFees.confirm",with: TapCommonConstants.pathForDefaultLocalisation())
        let alertCancel     = TapLocalisationManager.shared.localisedValue(for: "ExtraFees.cancel",with: TapCommonConstants.pathForDefaultLocalisation())
        
        // Display the confirmation alert
        let alertController:UIAlertController = .init(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alertController.addAction(.init(title: alertConfirm, style: .destructive, handler: { _ in
            onConfimation()
        }))
        alertController.addAction(.init(title: alertCancel, style: .cancel, handler: nil))
        
        UIDelegate?.show(alert: alertController)

    }
    
    /**
     Handles the charge response to see what should be the next action
     - Parameter with charge: The charge response we want to analyse and decide the next action based on it
     */
    func handleCharge(with charge:Charge) {
        // Based on the status we will know what to do
        let chargeStatus = charge.status
        switch chargeStatus {
        case .captured:
            handleCaptured(for:charge)
            break
        case .authorized:
            handleAuthorized(for:charge)
            break
        case .failed:
            handleFailed(for:charge)
            break
        case .initiated:
            handleInitated(for:charge)
            break
        default:
            handleCancelled(for:charge)
        }
    }
    
    
    /**
     Will be called once the charge response shows that, the charge has been successfully captured.
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleCaptured(for charge:Charge) {
        
    }
    
    /**
     Will be called once the charge response shows that, the authorize has been successfully captured.
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleAuthorized(for charge:Charge) {
        
    }
    
    /**
     Will be called once the charge response shows that, the charge has been successfully captured.
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleFailed(for charge:Charge) {
        
    }
    
    /**
     Will be called once the charge response shows that, the charge has been successfully captured.
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleInitated(for charge:Charge) {
        
    }
    
    /**
     Will be called once the charge response shows that, the charge has been successfully captured.
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleCancelled(for charge:Charge) {
        
    }
    
}
