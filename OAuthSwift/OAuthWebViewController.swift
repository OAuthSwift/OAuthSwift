//
//  WebView.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 2/11/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import Foundation

protocol WebViewProtocol {
    func setUrl(url: NSURL)
}

public class OAuthWebViewController: UIViewController, WebViewProtocol {
    public func setUrl(url: NSURL){}
}