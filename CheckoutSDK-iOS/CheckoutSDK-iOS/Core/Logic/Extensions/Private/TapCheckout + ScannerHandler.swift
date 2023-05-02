//
//  TapCheckout + ScannerHandler.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 7/14/21.
//  Copyright © 2021 Tap Payments. All rights reserved.
//

import Foundation
import CommonDataModelsKit_iOS
import TapCardScanner_iOS

// MARK:- Listen to the fired events from the scanner controller
extension TapCheckout:TapInlineScannerProtocl {
    public func tapFullCardScannerDimissed() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) { [weak self] in
//            self?.UIDelegate?.closeScannerClicked()
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) { [weak self] in
                //self?.dataHolder.viewModels.tapCardTelecomPaymentViewModel.setCard(with: .init(tapCardNumber: "4242424242424242", tapCardName: "DEFAULT CARD NAME", tapCardExpiryMonth: "11", tapCardExpiryYear: "22", tapCardCVV: "100"), then: false,for: .NormalCard)
            }
        }
    }
    
    public func tapCardScannerDidFinish(with tapCard: TapCard) {
        // First show a scanning success hint to inform the user
        //showScannedHint(with: .Scanned)
        
        //validate with bin lookup to make sure shall we put the card data or not
        
        // Check if the scanned card has 6 digits+
        guard tapCard.tapCardNumber?.tap_length ?? 0 >= 6 else {
            //applyScannedCardData(with: tapCard)
            return
        }
        
        // let us validate the card to make sure it is allowed as per the card brands (AMEX,etc) and the cars types (CREDIT,DEBIT)
        /*validateScannedCard(with: tapCard) { [weak self] in
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
        }*/
    }
    
    public func tapInlineCardScannerTimedOut(for inlineScanner: TapInlineCardScanner) {
        
    }
}
