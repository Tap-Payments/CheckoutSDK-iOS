//
//  TapCheckoutManager+Calculations.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 6/18/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import CommonDataModelsKit_iOS
import LocalisationManagerKit_iOS

/// Contains logic that needed to do any computation during the checkout process
internal extension TapCheckout {
    
    /**
     Used to compute the correct extra fees for a given payment option with regards to the current transaction total amount
     - Parameter for: The payment option you want to calclate its extra fees value
     - Returns: The correct extra fees to be allowed with regarding the extra fees type of the payment option and the transaction total amount
     */
    func calculateExtraFees(for paymentOption:PaymentOption) -> Double {
        // Get the correct extra fees value for the payment option
        return paymentOption.extraFees.reduce(0.0, { $0 + $1.extraFeeValue(for: calculateFinalAmount()) })
    }
    
    /**
     Used to confirm the extra fees for a given payment option
     - Parameter with paymentOption: The payment option to ask for its extra fees
     */
    func askForExtraFees(with paymentOption:PaymentOption, onConfimation: @escaping () -> () = {}) {
        // get the transaction mode
        let transactionMode = dataHolder.transactionData.transactionMode
        // Make sure the mode is capture or authorize
        guard (transactionMode == .authorizeCapture) || (transactionMode == .purchase) else {
            onConfimation()
            return
        }
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
    
}
