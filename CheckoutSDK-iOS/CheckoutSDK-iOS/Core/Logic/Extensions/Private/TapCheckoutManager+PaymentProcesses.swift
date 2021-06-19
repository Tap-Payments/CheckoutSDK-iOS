//
//  TapCheckoutManager+PaymentProcesses.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/18/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation

/// Collection of logic to process a payment with different flows
internal extension TapCheckoutSharedManager {
    
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
        UIDelegate?.actionButton(shouldLoad: true, success: false, onComplete: {})
        // Create the charge request
        let chargeRequest:TapChargeRequestModel = createChargeOrAuthorizeRequestModel(with: paymentOption, token: nil, cardBIN: nil)
        TapCheckout.callChargeOrAuthorizeAPI(chargeRequestModel: chargeRequest) { charge in
            print(charge)
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
        // check if there is an extra fee to pay or not
        //guard extraFeesValue > 0 else { return }
        // Create the formatted extra fee + the formatted new total amount
        let formatter = TapAmountedCurrencyFormatter { [weak self] in
            $0.currency = self?.transactionUserCurrencyValue.currency ?? .USD
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
    
}
