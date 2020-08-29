//
//  TapCheckoutSharedManager+UIKitDelegates.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 8/29/20.
//  Copyright © 2020 Tap Payments. All rights reserved.
//

import Foundation

/// Has the needed methods to act upon fired events from the uikit based on user activity
internal extension TapCheckoutSharedManager {
    
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
    
    func goPaySign(with body:[String:String]) {
        self.tapActionButtonViewModel.startLoading()
        
    }
}
