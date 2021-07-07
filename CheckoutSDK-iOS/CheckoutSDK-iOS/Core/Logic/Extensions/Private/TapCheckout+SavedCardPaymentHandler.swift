//
//  TapCheckout+SavedCardPaymentHandler.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/7/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
/// Logic to handle saved card payment flow
extension TapCheckout {
    
    
    /**
     Handles the logic needed to verify the OTP given by the user against the authentication id
     - Parameter for otpAuthenticationID: The authentication id from the backend
     - Parameter with otp: The otp string given by the user
     - Parameter chargeOrAuthorize: The current charge or authorize operation
     */
    func verifyAuthenticationOTP<T:Authenticatable>(for otpAuthenticationID:String, with otp:String,chargeOrAuthorize:T) {
        // Let us make sure that we have the data needed for the authentication id passed
        guard let authentication = fetchAuthentication(with: otpAuthenticationID) else {
            handleError(error: "Unexpected error, trying to validate OTP for a missing authentication model")
            return
        }
        
        // Let us show a loading status for the action button
        dataHolder.viewModels.tapActionButtonViewModel.startLoading()
        
        // let us make the authentication verification api
        // Create the authentication request
        guard let authenticationRequest:TapAuthenticationRequest = createOTPAuthenticationRequest(for: authentication, and: otp) else {
            handleError(error: "Unexpected error, cannot parse model into TapAuthenticationRequest")
            return
        }
        
        // Perform the authentication verification api
        authenticate(chargeOrAuthorize, details: authenticationRequest, onResponeReady: { [weak self] (authenticatedChargeOrAuthorize) in
            // Based on the response type we will decide what to do afterwards
            if let charge:Charge = authenticatedChargeOrAuthorize as? Charge {
                self?.handleCharge(with: charge)
            }else if let authorize:Authorize =  authenticatedChargeOrAuthorize as? Authorize {
                self?.handleAuthorized(for: authorize)
            }else{
                self?.handleError(error: "Unexpected error, parsing authentication of a wrong type. Should be Charge or Authorize")
            }
        }, onErrorOccured: { [weak self] (error) in
            self?.handleError(error: error)
        })
    }
}
