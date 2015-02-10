//
//  WebView.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 2/11/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import UIKit
import OAuthSwift

class WebViewController: OAuthWebViewController, UIWebViewDelegate {

    var targetURL : NSURL = NSURL()
    var webView : UIWebView = UIWebView()
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.frame = UIScreen.mainScreen().applicationFrame
        webView.scalesPageToFit = true
        webView.delegate = self
        self.view.addSubview(webView)
        loadAddressURL()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func setUrl(url: NSURL) {
        targetURL = url
    }
    func loadAddressURL() {
        let req = NSURLRequest(URL: targetURL)
        webView.loadRequest(req)
    }
    func webView(webView: UIWebView!, shouldStartLoadWithRequest request: NSURLRequest!, navigationType: UIWebViewNavigationType) -> Bool {
        println(request.URL.scheme)
        if (request.URL.scheme == "oauth-swift"){
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        return true
    }
}
