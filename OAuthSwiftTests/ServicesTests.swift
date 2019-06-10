//
//  ServicesTests.swift
//  OAuthSwift
//
//  Created by phimage on 25/11/15.
//  Copyright © 2015 Dongri Jin. All rights reserved.
//

import XCTest
import OAuthSwift
import Erik

class ServicesTests: XCTestCase {
    
    let services = Services()
    let FileManager: Foundation.FileManager = Foundation.FileManager.default
    
    
    let DocumentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    
    var confPath: String {
        let appPath = "\(DocumentDirectory)/.oauth/"
        if !FileManager.fileExists(atPath: appPath) {
            do {
                try FileManager.createDirectory(atPath: appPath, withIntermediateDirectories: false, attributes: nil)
            }catch {
                print("Failed to create \(appPath)")
            }
        }
        return "\(appPath)Services.plist"
    }


    override func setUp() {
        super.setUp()
        
        if let path = Bundle(for: type(of: self)).path(forResource: "Services", ofType: "plist") {
            services.loadFromFile(path)
            
            if !FileManager.fileExists(atPath: confPath) {
                do {
                    try FileManager.copyItem(atPath: path, toPath: confPath)
                }catch {
                    print("Failed to copy empty conf to\(confPath)")
                }
            }
        }
        services.loadFromFile(confPath)
        
        if let path = Bundle(for: type(of: self)).path(forResource: "ServicesTest", ofType: "plist") {
            services.loadFromFile(path)
        }

    }
    
    override func tearDown() {
        super.tearDown()
    }

    func _testAllServices() {
        for (service, parameters) in services.parameters {
            testService(service, serviceParameters: parameters)
        }
    }
    
    func testDropBox() {
        testService("Dropbox")
    }
    
    func testBitBucket() {
        testService("BitBucket")
    }
    
    func testService(_ service: String) {
        if let param = services[service] {
            self.testService(service, serviceParameters: param)
        } else {
            XCTFail("No parameters for \(service). Test ignored")
        }
    }
    
    func testService(_ service: String, serviceParameters: [String: String]) {
        if !Services.parametersEmpty(serviceParameters) {
            if let versionString = serviceParameters["version"] , let version = Int(versionString) {
                
                if version == 1 {
                    testServiceOAuth1(service, serviceParameters: serviceParameters)
                }
                else if version == 2 {
                    testServiceOAuth2(service, serviceParameters: serviceParameters)
                }
                else {
                    XCTFail("Wrong version \(version) for \(service)")
                }
            }
        }
    }

    func testServiceOAuth1(_ service: String, serviceParameters: [String: String]) {
        guard let oauthswift = OAuth1Swift(parameters: serviceParameters) else {
                print("\(service) not well configured for test [consumerKey, consumerSecret, requestTokenUrl, authorizeUrl, accessTokenUrl]")
                return
        }
        print("\(service) testing")
        
        let callbackURL = serviceParameters["callbackURL"] ?? "oauth-swift://oauth-callback/\(service)"

        guard let handler = ServicesURLHandlerType(
            service: service,
            serviceParameters: serviceParameters,
            callbackURL: callbackURL
            ) else {
                return
        }
        oauthswift.authorizeURLHandler = handler
        
        if let allowMissingOAuthVerifier = serviceParameters["allowMissingOAuthVerifier"]  {
            oauthswift.allowMissingOAuthVerifier = allowMissingOAuthVerifier == "1" || allowMissingOAuthVerifier == "true"
        }

        let expectation = self.expectation(description: service)
        
        let _ = oauthswift.authorize(withCallbackURL: URL(string: callbackURL)!) { result in
            switch result {
            case .success:
                expectation.fulfill()
                print("\(service) token ok")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }

        self.waitForExpectations(timeout: 20) { (error) -> Void in
            if let e = error {
                print("\(service): \(e.localizedDescription)")
            }
        }

    }
    
    func testServiceOAuth2(_ service: String, serviceParameters: [String: String]) {
        guard let oauthswift = OAuth2Swift(parameters: serviceParameters) else {
            print("\(service) not well configured for test [consumerKey, consumerSecret, responseType, authorizeUrl, accessTokenUrl]")
            return
        }
        print("\(service) testing")
        
        let callbackURL = serviceParameters["callbackURL"] ?? "oauth-swift://oauth-callback/\(service)"
        let scope = serviceParameters["scope"] ?? "all"
        
        guard let handler = ServicesURLHandlerType(
            service: service,
            serviceParameters: serviceParameters,
            callbackURL: callbackURL
            ) else {
                return
        }
        oauthswift.authorizeURLHandler = handler
        
        let expectation = self.expectation(description: service)
        
        let state = generateState(withLength: 20)
        let _ = oauthswift.authorize(withCallbackURL: URL(string: callbackURL)!, scope: scope, state: state) { result in
            switch result {
            case .success:
                expectation.fulfill()
                
                print("\(service) token ok")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        
        self.waitForExpectations(timeout: 20) { (error) -> Void in
            if let e = error {
                print("\(service): \(e.localizedDescription)")
            }
        }
        
    }
}

import WebKit
class ServicesURLHandlerType: LayoutEngineNavigationDelegate, OAuthSwiftURLHandlerType {
    
    let browser: Erik

    var service: String
    var serviceParameters: [String: String]
    var callbackURL: String
    var handled: Bool = false
    
    init?(service: String, serviceParameters: [String: String], callbackURL: String) {
        self.service = service
        self.serviceParameters = serviceParameters
        self.callbackURL = callbackURL
        
        let webView = WKWebView()
        browser = Erik(webView: webView)
        super.init()
        webView.navigationDelegate = self
        
        guard let _ = self.serviceParameters["form_username_selector"],
            let _ = self.serviceParameters["form_password_selector"],
            let _ = self.serviceParameters["form_selector"]
            else {
                print("\(service): No selector defined for form [form_username_selector, form_password_selector, form_selector]")
                return nil
        }
        guard let _ = self.serviceParameters["form_username_value"],
            let _ = self.serviceParameters["form_password_value"]
            else {
                print("\(self.service): No value defined to fill form [form_username_value, form_password_value]")
                return nil
        }
    }
    
    internal func handle(_ url: URL) {

        guard let form_username_selector = serviceParameters["form_username_selector"],
            let form_password_selector = serviceParameters["form_password_selector"],
            let form_selector = serviceParameters["form_selector"]
            else {
                XCTFail("\(service): Cannot handle \(url), no selector defined for form [form_username_selector, form_password_selector, form_selector]")
            return
        }
        
        browser.visit(url: url) {[unowned self] (document, error) in
            if self.handled {
                return // already handled (many already connected)
            }
            
            if let doc = document {
                // Fill form
                if let usernameInput = doc.querySelector(form_username_selector),
                    let passwordInput = doc.querySelector(form_password_selector),
                    let _ = doc.querySelector(form_selector) as? Form  {

                        guard let username = self.serviceParameters["form_username_value"],
                            let password = self.serviceParameters["form_password_value"]
                            else {
                                print("\(self.service): Cannot handle \(url), no value defined to fill form [form_username_value, form_password_value]")
                                return
                        }
                        
                        usernameInput["value"] = username
                        passwordInput["value"] = password
                        
                        // check form affectation
                        self.browser.currentContent {[unowned self] (document, error) in
                            if let doc = document {
                                guard let usernameInput = doc.querySelector(form_username_selector),
                                    let passwordInput = doc.querySelector(form_password_selector) else {
                                        print("\(self.service): Unable to get form element ")
                                        return
                                }
                                
                                XCTAssertEqual(usernameInput["value"], username)
                                XCTAssertEqual(passwordInput["value"], password)
                            }
                            
                            guard let form = doc.querySelector(form_selector) as? Form else {
                                print("\(self.service): Unable to get the form")
                                return

                            }
                            
                            let authorizeButtonBlock = {
                                // Wait redirection
                                self.browser.currentContent {[unowned self] (document, error) in
                                    if let e = error {
                                        print("\(e)")
                                    }
                                    
                                    if let currentURL = self.browser.url {
                                        print("\(currentURL)")
                                    }
                                    if let doc = document {
                                        self.authorizeButton(doc)
                                    }
                                }
                            }

                            // Submit form
                            if let formButton = self.serviceParameters["form_button_selector"], let button = form.querySelector(formButton) {
                                button.click { obj, err in
                                    if let error = err {
                                        print("\(error)")
                                    } else {
                                        authorizeButtonBlock()
                                    }
                                }
                            } else {
                                form.submit{ obj, err in
                                    if let error = err {
                                        print("\(error)")
                                    } else {
                                        authorizeButtonBlock()
                                    }
                                }
                            }
                        }
                        
                }
                else {
                    self.authorizeButton(doc)
                }
            }
            else {
                XCTFail("\(self.service): Cannot handle \(url) \(String(describing: error))")
            }
        }
    }
    
    func authorizeButton(_ doc: Document) {
        // Submit authorization
        if let autorizeButton = self.serviceParameters["authorize_button_selector"] {
            if let button = doc.querySelector(autorizeButton) {
                button.click()
            } else {
                print(doc.toHTML ?? "ERROR: no HTML doc")
                XCTFail("\(self.service): \(autorizeButton) not found to valid authentification]. \(String(describing: self.browser.url))")
            }
        } else if !self.handled {
            XCTFail("\(self.service): No [authorize_button_selector) to valid authentification]. \(String(describing: self.browser.url))")
        }
    }
    
    override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        super.webView(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
        
        if let url = navigationAction.request.url {
            let urlString = "\(url)"
            if urlString.hasPrefix(self.callbackURL) {
                self.handled = true
                OAuthSwift.handle(url: url)
                decisionHandler(.cancel)
            }
            else {
                decisionHandler(.allow)
            }
        }
    }

}
