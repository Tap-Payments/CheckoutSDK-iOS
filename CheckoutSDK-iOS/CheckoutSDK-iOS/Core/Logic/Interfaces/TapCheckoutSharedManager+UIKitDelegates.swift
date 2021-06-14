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
    
    /**
     Perofm the api call to validate the goPay credentials
     - Parameter body: The body you want to send to the api request will has to have email & password or phone & OTP
     */
    func goPaySign(with body:[String:String]) {
        // STart loading the button
        tapActionButtonViewModel.startLoading()
        
        // perform the login gopay api call
        NetworkManager.shared.makeApiCall(routing: .GoPayLoginAPI, resultType: TapGoPayLoginResponseModel.self) { [weak self] (session, result, error) in
            
            guard let goPayLoginModel:TapGoPayLoginResponseModel = result as? TapGoPayLoginResponseModel else {
                self?.tapActionButtonViewModel.endLoading(with: false)
                return }
            
            // Save the result for next checkout
            UserDefaults.standard.set(goPayLoginModel.success, forKey: TapCheckoutConstants.GoPayLoginUserDefaultsKey)
            self?.loggedInToGoPay = goPayLoginModel.success
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) { [weak self] in
                self?.UIDelegate?.goPaySignIn(status: goPayLoginModel.success)
            }
        } onError: { (session, result, error) in
            
        }
    }
}
