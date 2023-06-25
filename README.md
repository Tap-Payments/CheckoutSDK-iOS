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

## Important Information
### Supported languages
1. English.
1. Arabic.

### Supported themes
> The sdk auto detects the device's display mode light or dark and displays itself accordingly.

1. Light mode.
	1. The `Checkout SDK` will be displayed in light mode and icons will be colored.
1. Light mode with mono color.
	1. The `Checkout SDK` will be displayed in light mode and icons will be monochromatic.
1. Dark mode.
	1. The `Checkout SDK` will be displayed in dark mode and icons will white.
1. Dark mode with colors.
	1. The `Checkout SDK` will be displayed in dark mode and icons will be colored.

### Supported SDK modes
1. Sandbox
	1. Where you can try all different payment methods with no limits and no charges will occur.
	2. Check this for our [Testing Cards](https://developers.tap.company/reference/testing-cards "Testing Cards")
1. Production
	1. Where you can try all different payment methods for real to memic your expected customers' experience. Please note, this will require using real data will incur charges.

### Supported transaction modes
1. Purchase
	1. To be used when you want to deduct the amount from your customer.
1. Authourize
	1. To be used when you want to hold the amount from your customer.

## SDK Setup
### Global variables setup
These variables to be set before starting the `Checkout SDK`. This will define important parameters for configuring and theming the `Checkout SDK` itself. Please note, missing to configure these will end up in using default values or the `Checkout SDK` will throw an error as it cannot start.

1. The required localisation.
	1. By this you define which language you want the `Checkout SDK` appears with.
	1. Now we do support: `en` & `ar`.
	1. Default value if not set is : `en`.
	1. How to set it:
		 `TapLocalisationManager.shared.localisationLocale = "en"`
		 `TapCheckout.localeIdentifier = "en"`
1. The required Tap keys.
	1. By this, you define your Tap keys so the sdk can identify you as a merchant.
	1. These are required.
	1. How to set it: `TapCheckout.secretKey = .init(sandbox: "", production:"")`
1. Optional theme variables:
	1. Display mono variant when showing the Light mode theme
		1. If not passed default value is `false`
		1. How to set it : `TapCheckout.displayMonoLight = false`
	1. Display colorized variant when showing the Dark mode theme
		1. If not passed default value is `false`
		1. How to set it : `TapCheckout.displayColoredDark = false`

## Starting the Checkout SDK
### Checkout SDK Instance
```swift
import CheckoutSDK_iOS
    class ViewController: UIViewController {
    	/// A strong reference to tap checkout variable
    	let checkout:TapCheckout = .init()
    }
```

### Checkout SDK transaction configurations
```swift
/**
     Defines the tap checkout bottom sheet controller
     - Parameter delegate: A protocol to communicate with the Presente tap sheet controller
     - Parameter currency: Represents the original transaction currency stated by the merchant on checkout start
     - Parameter supportedCurrencies: Represents the allowed currencies for the transaction. Leave nil for ALL, pass the 3 digits iso KWD, EGP, etc.
     - Parameter amount: Represents the original total transaction amount stated by the merchant on checkout start
     - Parameter items: Represents the List of payment items if any. If no items are provided one will be created by default as PAY TO [MERCHANT NAME] -- Total value
     - Parameter applePayMerchantID: The Apple pay merchant id to be used inside the apple pay kit
     - Parameter onCheckOutReady: This will be called once the checkout is ready so you can use it to present it or cancel it
     - Parameter paymentType: The allowed payment type inclyding cards, apple pay, web and telecom or ALL
     - Parameter transactionMode: Decide which transaction mode will be used in this call. Purchase, Authorization, Card Saving and Toknization. Please check [TransactionMode](x-source-tag://TransactionModeEnum)
     - Parameter customer: Decides which customer is performing this transaction. It will help you as a merchant to define the payer afterwards. Please check [TapCustomer](x-source-tag://TapCustomer)
     - Parameter destinations: Decides which destination(s) this transaction's amount should split to. Please check [Destination](x-source-tag://Destination)
     - Parameter tapMerchantID: Optional. Useful when you have multiple Tap accounts and would like to do the `switch` on the fly within the single app.
     - Parameter taxes: Optional. List of Taxes you want to apply to the order if any.
     - Parameter shipping: Optional. List of Shipping you want to apply to the order if any.
     - Parameter allowedCadTypes: Decides the allowed card types whether Credit or Debit or All. If not set all will be accepeted.
     - Parameter postURL: The URL that will be called by Tap system notifying that payment has succeed or failed.
     - Parameter paymentDescription: Description of the payment to use for further analysis and processing in reports.
     - Parameter TapMetadata: Additional information you would like to pass along with the transaction. Please check [TapMetaData](x-source-tag://TapMetaData)
     - Parameter paymentReference: Implement this property to keep a reference to the transaction on your backend. Please check [Reference](x-source-tag://Reference)
     - Parameter paymentStatementDescriptor: Description of the payment  to appear on your settlemenets statement.
     - Parameter require3DSecure: Defines if you want to apply 3DS for this transaction. By default it is set to true.
     - Parameter receiptSettings: Defines how you want to notify about the status of transaction reciept by email, sms or both. Please check [Receipt](x-source-tag://Receipt)
     - Parameter authorizeAction: Defines what to do with the authorized amount after being authorized for a certain time interval. Please check [AuthorizeAction](x-source-tag://AuthorizeAction)
     - Parameter allowsToSaveSameCardMoreThanOnce: Defines if same card can be saved more than once. Default is `true`.
     - Parameter enableSaveCard: Defines if the customer can save his card for upcoming payments. Default is `true`.
     - Parameter isSaveCardSwitchOnByDefault: Defines if save card switch is on by default.. Default is `true`.
     - Parameter sdkMode: Defines the mode sandbox or production the sdk will perform this transaction on. Please check [SDKMode](x-source-tag://SDKMode)
     - Parameter collectCreditCardName: Decides whether or not, the card input should collect the card holder name. Default is false
     - Parameter creditCardNameEditable: Decides whether or not, the card name field will be editable
     - Parameter creditCardNamePreload: Decides whether or not, the card name field should be prefilled
     - Parameter isSubscription: Defines if you want to make a subscription based transaction. Default is false
     - Parameter recurringPaymentRequest: Defines the recurring payment request Please check [Apple Pay
     docs](https://developer.apple.com/documentation/passkit/pkrecurringpaymentrequest). NOTE: This will only be availble for iOS 16+ and subscripion parameter is on.
     - Parameter applePayButtonType: Defines the type of the apple pay button like Pay with or Subscripe with  etc. Default is Pay
     - Parameter applePayButtonStyle: Defines the UI of the apple pay button white, black or outlined. Default is black
     - Parameter showSaveCreditCard:Decides whether or not, the card input should show save card option for Tap and Merchant sides. Default is None
     - Parameter shouldFlipCardData: Defines if the card info textfields should support RTL in Arabic mode or not
     */
	 
checkout.build(
            delegate: self,
            currency: .KWD,
            supportedCurrencies: [TapCurrencyCode.EGP.appleRawValue, TapCurrencyCode.KWD.appleRawValue],
            amount: 100,
            items: [.init(title: "Item Title", description: "Item Description", price: 100, quantity: 1, discount: nil, taxes: [], currency: .KWD)],
            applePayMerchantID: "merchant.tap.gosell",
            paymentType: .All,
            transactionMode: .purchase,
            customer: try! .init(emailAddress: .init(emailAddressString: "Customeremail@domain.com"), phoneNumber: .init(isdNumber: "965", phoneNumber: "50000000"), name: "Customer Name", address: nil),
            tapMerchantID: TapFormSettingsViewController.merchantSettings().3,
            taxes: [],
            shipping: nil,//.init(name: "Optional shipping fees", amount: 20),
            require3DSecure: true,
            sdkMode: .sandbox,
            collectCreditCardName: true,
            creditCardNameEditable: true,
            creditCardNamePreload: "",
            showSaveCreditCard: .Merchant,
            isSubscription: false,
            recurringPaymentRequest: nil,
            applePayButtonType: .PayWithApplePay,
            applePayButtonStyle: .Auto,
            shouldFlipCardData: false,
            onCheckOutReady: {[weak self] tapCheckOut in
                DispatchQueue.main.async() {
                    tapCheckOut.start(presentIn: self)
                }
            })
```


#### Variables closer look
Let us take a closer look at the variables configuring the `Checkout SDK`.
|  Variable | Sample value  |  Default value | Notes |
| :------------ | :------------ | :------------ | :------------ |
| currency  | .KWD  | .USD | Represents the original transaction currency stated by the merchant on checkout start |
| supportedCurrencies| [TapCurrencyCode.EGP.appleRawValue, TapCurrencyCode.KWD.appleRawValue] | nil| Represents the allowed currencies for the transaction. Leave nil for ALL, pass the 3 digits iso KWD, EGP, etc.
