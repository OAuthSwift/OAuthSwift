//
//  WebViewController.swift
//  OAuthSwift
//
//  Created by phimage on 07/05/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import AppKit
import OAuthSwiftOSX
import WebKit

class WebViewController: OAuthWebViewController {
    
    var targetURL : NSURL = NSURL()
    let webView : WKWebView = WKWebView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.frame = self.view.bounds
        self.webView.navigationDelegate = self
        
        
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.webView)
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-0-[view]-0-|", options: nil, metrics: nil, views: ["view":self.webView]))
        self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[view]-0-|", options: nil, metrics: nil, views: ["view":self.webView]))
    }
    
    override func handle(url: NSURL) {
        self.targetURL = url
        super.handle(url)
        
        loadAddressURL()
    }
 
    func loadAddressURL() {
        let req = NSURLRequest(URL: targetURL)
        self.webView.loadRequest(req)
    }

    /* override func  webView(webView: WebView!, decidePolicyForNavigationAction actionInformation: [NSObject : AnyObject]!, request: NSURLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {
        
        if request.URL?.scheme == "oauth-swift" {
           self.dismissWebViewController()
        }

    } */
}

extension WebViewController: WKNavigationDelegate {
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.URL where url.scheme == "oauth-swift" {
            AppDelegate.sharedInstance.applicationHandleOpenURL(url)
            decisionHandler(.Cancel)
            
            self.dismissWebViewController()
            return
        }

        decisionHandler(.Allow)
    }
}
