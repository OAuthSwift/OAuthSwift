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

    var targetURL: URL?
    let webView: WebView = WebView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if os(iOS)
            self.webView.frame = UIScreen.main.bounds
            self.webView.scalesPageToFit = true
            self.webView.delegate = self
            self.view.addSubview(self.webView)
            loadAddressURL()
        #elseif os(OSX)
            
            self.webView.frame = self.view.bounds
            self.webView.navigationDelegate = self
            self.webView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.webView)
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[view]-0-|", options: [], metrics: nil, views: ["view":self.webView]))
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: [], metrics: nil, views: ["view":self.webView]))
        #endif
    }

    override func handle(_ url: URL) {
        targetURL = url
        super.handle(url)
        self.loadAddressURL()
    }

    func loadAddressURL() {
        guard let url = targetURL else {
            return
        }
        let req = URLRequest(url: url)
        #if os(iOS)
            self.webView.loadRequest(req)
        #elseif os(OSX)
            self.webView.load(req)
        #endif
    }
}

// MARK: delegate
#if os(iOS)
    extension WebViewController: UIWebViewDelegate {
        func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
            if let url = request.url, url.scheme == "oauth-swift" {
                // Call here AppDelegate.sharedInstance.applicationHandleOpenURL(url) if necessary ie. if AppDelegate not configured to handle URL scheme
                // compare the url with your own custom provided one in `authorizeWithCallbackURL`
                self.dismissWebViewController()
            }
            return true
        }
    }

#elseif os(OSX)
    extension WebViewController: WKNavigationDelegate {

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            // here we handle internally the callback url and call method that call handleOpenURL (not app scheme used)
            if let url = navigationAction.request.url , url.scheme == "oauth-swift" {
                AppDelegate.sharedInstance.applicationHandle(url: url)
                decisionHandler(.cancel)
                
                self.dismissWebViewController()
                return
            }
            
            decisionHandler(.allow)
        }
        
        /* override func  webView(webView: WebView!, decidePolicyForNavigationAction actionInformation: [NSObject : AnyObject]!, request: URLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {
        
        if request.URL?.scheme == "oauth-swift" {
        self.dismissWebViewController()
        }
        
        } */
        
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("\(error)")
            self.dismissWebViewController()
            // maybe cancel request...
        }
    }
#endif
