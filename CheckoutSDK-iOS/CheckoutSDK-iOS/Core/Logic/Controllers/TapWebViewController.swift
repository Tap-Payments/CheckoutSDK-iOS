//
//  TapWebViewController.swift
//  CheckoutSDK-iOS
//
//  Created by Osama Rabie on 03/05/2023.
//  Copyright © 2023 Tap Payments. All rights reserved.
//

import UIKit
import SnapKit
import WebKit
/// Handles showing the checkout web sdk
internal class TapWebViewController: UIViewController {
    /// The web view used to load the checkout popup
    let webView:WKWebView = .init(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // let us apply the theme
        applyTheme()
        // Add the web view
        configureWebView()
    }
    
    /// Adds the web view and resizes it
    func configureWebView() {
        view.addSubview(webView)
        
        
        
        let keyWindow = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        
        let topPadding = keyWindow?.safeAreaInsets.top ?? 0
        let bottomPadding = keyWindow?.safeAreaInsets.bottom ?? 0
        
        webView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(-topPadding)
            make.bottom.equalToSuperview().offset(bottomPadding)
            make.trailing.equalToSuperview()
            make.leading.equalToSuperview()
        }
        webView.layoutIfNeeded()
    }
    
    /// This will amke sure everything is clear as we will use the theme coming from the web sdk
    func applyTheme() {
        view.backgroundColor = .clear
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
    }
    
    /// Load the url into the web view
    /// - Parameter url: The url to be loaded
    func load(url:URL) {
        webView.navigationDelegate = TapCheckout.sharedCheckoutManager()
        webView.load(.init(url: url,cachePolicy: .reloadIgnoringLocalAndRemoteCacheData))
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
