//
//  WebView.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 2/11/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import OAuthSwift

#if os(iOS)
    import UIKit
    typealias WebView = UIWebView // WKWebView
#elseif os(OSX)
    import AppKit
    import WebKit
    typealias WebView = WKWebView
#endif

class WebViewController: OAuthWebViewController {

    var targetURL : NSURL = NSURL()
    let webView : WebView = WebView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if os(iOS)
            self.webView.frame = UIScreen.mainScreen().bounds
            self.webView.scalesPageToFit = true
            self.webView.delegate = self
            self.view.addSubview(self.webView)
            loadAddressURL()
        #elseif os(OSX)
            
            self.webView.frame = self.view.bounds
            self.webView.navigationDelegate = self
            self.webView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.webView)
            self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[view]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view":self.webView]))
            self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[view]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["view":self.webView]))
        #endif
    }

    override func handle(url: NSURL) {
        targetURL = url
        super.handle(url)
        
        loadAddressURL()
    }

    func loadAddressURL() {
        let req = NSURLRequest(URL: targetURL)
        self.webView.loadRequest(req)
    }
}

// MARK: delegate
#if os(iOS)
    extension WebViewController: UIWebViewDelegate {
        func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
            if let url = request.URL where (url.scheme == "oauth-swift"){
                self.dismissWebViewController()
            }
            return true
        }
    }

#elseif os(OSX)
    extension WebViewController: WKNavigationDelegate {
        
        func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
            
            // here we handle internally the callback url and call method that call handleOpenURL (not app scheme used)
            if let url = navigationAction.request.URL where url.scheme == "oauth-swift" {
                AppDelegate.sharedInstance.applicationHandleOpenURL(url)
                decisionHandler(.Cancel)
                
                self.dismissWebViewController()
                return
            }
            
            decisionHandler(.Allow)
        }
        
        /* override func  webView(webView: WebView!, decidePolicyForNavigationAction actionInformation: [NSObject : AnyObject]!, request: NSURLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {
        
        if request.URL?.scheme == "oauth-swift" {
        self.dismissWebViewController()
        }
        
        } */
    }
#endif
