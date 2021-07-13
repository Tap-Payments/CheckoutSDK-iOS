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
            if let chargeorAuthorize:ChargeProtocol = authenticatedChargeOrAuthorize as? ChargeProtocol {
                self?.handleCharge(with: chargeorAuthorize)
            }else{
                self?.handleError(error: "Unexpected error, parsing authentication of a wrong type. Should be Charge or Authorize")
            }
        }, onErrorOccured: { [weak self] (error) in
            self?.handleError(error: error)
        })
    }
    
    /**
     Will do the logic needed to confitm deletion of a saved card
     - Parameter with cardCellViewModel: The view model for the saved card chip cell the user wants to delete
     */
    func askForCardDeletion(with cardCellViewModel:SavedCardCollectionViewCellModel) {
        
        // Fetch the card details first
        guard let savedCardID = cardCellViewModel.savedCardID,
              let savedCard = fetchSavedCardOption(with: savedCardID) else { return }
        
        // Now we need to ask the user a confirmation alert about the deletion first.
        let alertTitle      = TapLocalisationManager.shared.localisedValue(for: "DeleteCard.title",with: TapCommonConstants.pathForDefaultLocalisation())
        let alertMessage    = String(format: TapLocalisationManager.shared.localisedValue(for: "DeleteCard.message",with: TapCommonConstants.pathForDefaultLocalisation()), savedCard.displayTitle)
        let alertConfirm    = TapLocalisationManager.shared.localisedValue(for: "DeleteCard.confirm",with: TapCommonConstants.pathForDefaultLocalisation())
        let alertCancel     = TapLocalisationManager.shared.localisedValue(for: "DeleteCard.cancel",with: TapCommonConstants.pathForDefaultLocalisation())
        
        // Display the confirmation alert
        let alertController:UIAlertController = .init(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alertController.addAction(.init(title: alertConfirm, style: .destructive, handler: { [weak self] _ in
            self?.deleteSavedCard(for: savedCard, with: cardCellViewModel)
        }))
        alertController.addAction(.init(title: alertCancel, style: .cancel, handler: nil))
        
        UIDelegate?.show(alert: alertController)
    }
    
    /**
     Handels the process of deleting a saved card after confirmation
     - Parameter with cardCellViewModel: The view model for the saved card chip cell the user wants to delete
     - Parameter for savedCard: The saved card object we want to delete
     */
    func deleteSavedCard(for savedCard:SavedCard,with cardCellViewModel:SavedCardCollectionViewCellModel) {
        // First call the deletion api
        callSavedCardDeletion(for: savedCard) { [weak self] (savedCardDeleteResponse) in
            // Time to perform mthe correct post deletion logic based on the api response
            self?.performPostSavedCardDeletion(for: savedCard.identifier ?? "",with: cardCellViewModel, and: savedCardDeleteResponse)
        } onErrorOccured: { [weak self] (error) in
            self?.handleError(error: error)
        }
    }
    
    /**
     Handels the process of post deleting a saved card after calling the delete api
     - Parameter with cardCellViewModel: The view model for the saved card chip cell the user wants to delete
     - Parameter for savedCardID: The saved card object we want to delete
     - Parameter and savedCardDeleteResponse: The response we got from the save card delete api
     */
    func performPostSavedCardDeletion(for savedCardID:String,with cardCellViewModel:SavedCardCollectionViewCellModel, and savedCardDeleteResponse:TapDeleteSavedCardResponseModel) {
        // In all cases, we need to perform some commong logic post deletion
        commonPostSavedCardDeletion()
        // Now if the deletion was successful we need to update the displayed list of saved cards
        guard savedCardDeleteResponse.isDeleted else { return }
        // Delete the saved card object from the viewmodel datasource
        dataHolder.viewModels.gatewayChipsViewModel.removeAll(where: {$0.savedCard?.identifier == savedCardID})
        // Inform the view to update itself
        updateGatewayChipsList()
    }
    
    /// Performs the common things to do post card deletion, whether the deletion was successful or failed
    func commonPostSavedCardDeletion() {
        // Change the button status to invalid payment
        chanegActionButton(status: .InvalidPayment, actionBlock: nil)
        // Expand the button and stop loading
        dataHolder.viewModels.tapActionButtonViewModel.expandButton()
        // Stop the edit mode for the saved card lisr
        headerEndEditingButtonClicked(in: .GatewayListHeader)
    }
}
