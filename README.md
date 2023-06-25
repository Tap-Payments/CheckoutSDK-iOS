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



