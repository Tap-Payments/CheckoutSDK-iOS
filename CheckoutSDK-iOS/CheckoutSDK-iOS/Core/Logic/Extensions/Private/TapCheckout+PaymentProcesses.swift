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
        // Create the charge request and call it
        let chargeRequest:TapChargeRequestModel = createChargeOrAuthorizeRequestModel(with: paymentOption, token: nil, cardBIN: nil)
        callChargeOrAuthorizeAPI(chargeRequestModel: chargeRequest) { [weak self] charge in
            DispatchQueue.main.async{
                // Process the charge protocol response we got from the server
                guard let nonNullSelf = self else { return }
                nonNullSelf.handleCharge(with: charge)
            }
        } onErrorOccured: { [weak self] error in
            self?.handleError(error: error)
        }

    }
    
    /**
     Handles the charge response to see what should be the next action
     - Parameter with charge: The charge response we want to analyse and decide the next action based on it
     */
    func handleCharge(with chargeOrAuthorize:ChargeProtocol?) {
        // Save the object for further processing
        if chargeOrAuthorize is Charge {
            dataHolder.transactionData.currentCharge = chargeOrAuthorize as? Charge
        }
        
        // Based on the status we will know what to do
        let chargeStatus = chargeOrAuthorize?.status
        switch chargeStatus {
        case .captured:
            handleCaptured(for:chargeOrAuthorize)
            break
        case .authorized:
            handleAuthorized(for:chargeOrAuthorize)
            break
        case .failed,.declined:
            handleFailed(for:chargeOrAuthorize)
            break
        case .initiated:
            handleInitated(for:chargeOrAuthorize)
            break
        default:
            handleCancelled(for:chargeOrAuthorize)
        }
    }
    
    
    /**
     Will be called once the charge response shows that, the charge has been successfully captured.
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleCaptured(for charge:ChargeProtocol?) {
        // First let us inform the caller app that the charge/authorization had been done successfully
        if let charge:Charge = charge as? Charge {
            tapCheckoutScreenDelegate?.checkoutCaptured?(with: charge)
        }else if let authorize:Authorize = charge as? Authorize {
            tapCheckoutScreenDelegate?.checkoutCaptured?(with: authorize)
        }
        // Now it is time to safely dismiss ourselves showing a green tick :)
        dismissCheckout(with: true)
    }
    
    /**
     Will be called once the charge response shows that, the authorize has been successfully captured.
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleAuthorized(for charge:ChargeProtocol?) {
        
    }
    
    /**
     Will be called once the charge response shows that, the charge has been successfully captured.
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleFailed(for charge:ChargeProtocol?) {
        // First let us inform the caller app that the charge/authorization had been done successfully
        if let charge:Charge = charge as? Charge {
            tapCheckoutScreenDelegate?.checkoutFailed?(with: charge)
        }else if let authorize:Authorize = charge as? Authorize {
            tapCheckoutScreenDelegate?.checkoutFailed?(with: authorize)
        }
        // Now it is time to safely dismiss ourselves showing a green tick :)
        dismissCheckout(with: false)
    }
    
    /**
     Will be called once the charge response shows that, the charge has been successfully captured.
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleInitated(for charge:ChargeProtocol?) {
        // Check if we need to make a redirection
        if let redirectionURL:URL = charge?.transactionDetails.url {
            DispatchQueue.main.async{ [weak self] in
                // Instruct the view to open a web view with the redirection url
                guard let nonNullSelf = self else { return }
                nonNullSelf.UIDelegate?.showWebView(with: redirectionURL,and: nonNullSelf)
            }
        }
    }
    
    /**
     Will be called once the charge response shows that, the charge has been successfully captured.
     - Parameter for charge: The charge object we will pass back to the user
     */
    func handleCancelled(for charge:ChargeProtocol?) {
        handleFailed(for: charge)
    }
    
}
