# CheckoutSDK-iOS
[Tap payments](https://www.tap.company "Tap payments") provides for you a one drop solution to enable a seamless checkout process in your iOS app flow.

![](https://img.shields.io/badge/Swift-4.0-F16D39.svg?style=flat) ![](https://img.shields.io/badge/License-MIT-blue.svg) ![](https://img.shields.io/cocoapods/v/CheckoutSDK-iOS.svg?style=flat)

**Access all local, regional, & global payment methods**

Your customers can scale globally by offering all popular payment methods across MENA, whether that's mada, KNET, Fawry, Apple Pay, Visa, Mastercard, Amex, Tabby, and many more.
![](https://files.readme.io/4dc0d3e-payment-methods-tap-transparent.png)

**Look at it!**

[<img src="https://i.ibb.co/KzhdTJP/Screenshot-2023-06-25-at-8-32-55-AM.png" width="200">](https://tap-assets.b-cdn.net/dark.mov) <img width="100" /> [<img src="https://i.ibb.co/QYSmHSr/Screenshot-2023-06-25-at-8-37-07-AM.png" width="200">](https://tap-assets.b-cdn.net/light.mov)

------------


## Installation

### CocoaPods

Add this spec to your podfile:

`pod "CheckoutSDK-iOS "`

------------

## Pre SDK Setup
> If you already have a Tap account, please skip this part.

In order to be able to use the SDK, you have to create a Tap account first. Once you finish your account with our [Integration team](https://www.tap.company "Integration team"), please make sure they provided you with the following:
1. Your sandbox public key.
	1. This will be used to perform testing transactions in our sandbox environment. Will be useful for you in your development phase.
2. Your production public key.
	1. This will be used to perform actual transactions in our production environment. Will be required for you before releasing your application.
1. Your tap merchant id.
	1. This will be used as an identifier for the app entity under your Tap account. As you can have multiple apps/websites integrated with Tap under your same Tap account.
1. Apple pay CSR.
	1. If you are willing to enable Apple pay, you have to provide them with your Apple merchant id and they will provide back Apple pay CSR, where you will generate an Apple pay certification using it and you have to pass it back to them.


## Apple pay setup
> If you are not willing to enable Apple pay, please skip this part.
1. Ask for the CSR from Tap team.

2. From your Apple Developer account:

3. 1. Create a merchant identifier

      A *merchant identifier* uniquely identifies you to Apple Pay as a merchant who is able to accept payments. You can use the same merchant identifier for multiple native and web apps. It never expires.

      1. In [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources), select Identifiers from the sidebar, then click the Add button (+) in the upper-left corner. ![img](https://i.imgur.com/50MJuuk.png)
      2. Select Merchant IDs, then click Continue. ![img](https://i.imgur.com/lYAE2am.png)
      3. Enter the merchant description and identifier name, then click Continue. ![img](https://i.imgur.com/w6gpIo4.png)
      4. Review the settings, then click Register.

   2. Create Payment Processing Certificate:A *payment processing certificate* is associated with your merchant identifier and used to encrypt payment information. The payment processing certificate expires every 25 months. If the certificate is revoked, you can recreate it.

      1. In [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources), select Identifiers from the sidebar. ![img](https://i.imgur.com/eBKFkvo.png)

      2. Under Identifiers, select Merchant IDs using the filter in the top-right.

      3. On the right, select your merchant identifier.

         *Note:* If a banner appears at the top of the page saying that you need to accept an agreement, click the Review Agreement button and follow the instructions before continuing.

      4. Under Apple Pay Payment Processing Certificate, click Create Certificate.

      5. [Create a certificate signing request](https://help.apple.com/developer-account/#/devbfa00fef7) on your Mac, and click Continue.

      6. Click Choose File.

      7. In the dialog that appears, select the certificate request file (a file with a `.certSigningRequest` file extension), then click Choose.

      8. Click Continue.

      9. Click Download.

         The certificate file (a file with a `.cer` file extension) appears in your `Downloads` folder.

4. Share your .cer file, merchant identifier and app bundle id back to Tap team.

5. Enable Apple Pay capability into your project from Xcode and select the merchant identifier. ![img](https://i.imgur.com/PT29us3.png)

6. Tap Apple Pay button will appear if:

   1. You did all the previous steps.
   2. The customer is paying with a currency that has Apple Pay option enabled from our side.
   3. The customer paying already activate Apple pay in his device.
   4. The customer paying has already added at least one valid card in his Apple Wallet with one our Apple pay payment networks.


