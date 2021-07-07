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
     */
    func verifyAuthenticationOTP(for otpAuthenticationID:String, with otp:String) {
        // Let us make sure that we have the data needed for the authentication id passed
        guard let authentication = fetchAuthentication(with: otpAuthenticationID) else {
            handleError(error: "Unexpected error, trying to validate OTP for a missing authentication model")
            return
        }
        
        // Let us show a loading status for the action button
        dataHolder.viewModels.tapActionButtonViewModel.startLoading()
        
        // let us make the authentication verification api
        
    }
    
}
