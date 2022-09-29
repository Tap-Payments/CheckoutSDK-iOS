//
//  TapCheckout + ScannerHandler.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/14/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import TapUIKit_iOS
import CommonDataModelsKit_iOS
import TapCardScanner_iOS

// MARK:- Events and methods related to scanning logic
extension TapCheckout {
    
    /// Will instruct the checkout sheet controller to show within the scanner
    /// - Parameter with hintStatus: The status of the hint to be shown
    func showScannedHint(with hintStatus:TapHintViewStatusEnum) {
        // Create the hint view model and the hint view UI
        let hintViewModel:TapHintViewModel = .init(with: hintStatus)
        let hintView:TapHintView = hintViewModel.createHintView()
        
        // Instruct the ui delegate to show the hint view
        UIDelegate?.attach(hintView: hintView, to: TapAmountSectionView.self,with: true)
    }
    
    /**
     Apply the scanned card
     - Parameter with tapCard: The card scanned data
     */
    func applyScannedCardData(with tapCard:TapCard) {
        dataHolder.viewModels.tapCardTelecomPaymentViewModel.setCard(with: tapCard, then: false,for: .NormalCard)
    }
    
    /**
     Validates the scanned card against the allowed card brands and types
     - Parameter with tapCard: The scanned card data
     - Parameter onValidationSuccess: A block to execute if the validation passed
     - Parameter onValidationFailure: A block to execute if the validation failed
     */
    func validateScannedCard(with tapCard:TapCard, onValidationSuccess: @escaping ()->() = {}, onValidationFailure : @escaping ()->() = {}) {
        // First we need to call the bin lookup then check if it is from the allowed card brands and from the allowed card types
        // Call the binlook up
        guard let cardNumber = tapCard.tapCardNumber,
              cardNumber.tap_length >= 6 else {
            onValidationFailure()
            return
        }
        
        getBINDetails(for: cardNumber.tap_substring(to: 6)) { [weak self] (binResponseModel) in
            // Now let us check if it is from the allowed types and from the allowed card brands
            guard self?.dataHolder.transactionData.allowedCardTypes.contains(binResponseModel.cardType) ?? false,
                  self?.fetchSupportedCardBrands().contains(binResponseModel.cardBrand) ?? false else {
                onValidationFailure()
                return
            }
            
            onValidationSuccess()
            
        } onErrorOccured: { [weak self] (session, result, error) in
            self?.handleError(session: session, result: result, error: error)
        }
    }
}

// MARK:- Listen to the fired events from the scanner controller
extension TapCheckout:TapInlineScannerProtocl {
    public func tapFullCardScannerDimissed() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) { [weak self] in
            self?.UIDelegate?.closeScannerClicked()
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) { [weak self] in
                self?.dataHolder.viewModels.tapCardTelecomPaymentViewModel.setCard(with: .init(tapCardNumber: "4242424242424242", tapCardName: "DEFAULT CARD NAME", tapCardExpiryMonth: "11", tapCardExpiryYear: "22", tapCardCVV: "100"), then: false,for: .NormalCard)
            }
        }
    }
    
    public func tapCardScannerDidFinish(with tapCard: TapCard) {
        // First show a scanning success hint to inform the user
        showScannedHint(with: .Scanned)
        
        //validate with bin lookup to make sure shall we put the card data or not
        
        // Check if the scanned card has 6 digits+
        guard tapCard.tapCardNumber?.tap_length ?? 0 >= 6 else {
            applyScannedCardData(with: tapCard)
            return
        }
        
        // let us validate the card to make sure it is allowed as per the card brands (AMEX,etc) and the cars types (CREDIT,DEBIT)
        validateScannedCard(with: tapCard) { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) {
                self?.dataHolder.viewModels.tapCardTelecomPaymentViewModel.setCard(with: tapCard, then: false, for: .NormalCard)
                self?.UIDelegate?.closeScannerClicked()
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
                    //self?.dataHolder.viewModels.tapCardTelecomPaymentViewModel.setCard(with: tapCard, then: false)
                    //self?.UIDelegate?.closeScannerClicked()
                }
            }
        } onValidationFailure: { [weak self] in
            self?.UIDelegate?.closeScannerClicked()
        }
    }
    
    public func tapInlineCardScannerTimedOut(for inlineScanner: TapInlineCardScanner) {
        
    }
}
