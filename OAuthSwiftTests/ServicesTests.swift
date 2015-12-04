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
    let FileManager: NSFileManager = NSFileManager.defaultManager()
    
    
    let DocumentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    
    
    var confPath: String {
        let appPath = "\(DocumentDirectory)/.oauth/"
        if !FileManager.fileExistsAtPath(appPath) {
            do {
                try FileManager.createDirectoryAtPath(appPath, withIntermediateDirectories: false, attributes: nil)
            }catch {
                print("Failed to create \(appPath)")
            }
        }
        return "\(appPath)Services.plist"
    }


    override func setUp() {
        super.setUp()
        
        if let path = NSBundle(forClass: self.dynamicType).pathForResource("Services", ofType: "plist") {
            services.loadFromFile(path)
            
            if !FileManager.fileExistsAtPath(confPath) {
                do {
                    try FileManager.copyItemAtPath(path, toPath: confPath)
                }catch {
                    print("Failed to copy empty conf to\(confPath)")
                }
            }
        }
        services.loadFromFile(confPath)
        
        if let path = NSBundle(forClass: self.dynamicType).pathForResource("ServicesTest", ofType: "plist") {
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
    
    func testService(service: String) {
        if let param = services[service] {
            self.testService(service, serviceParameters: param)
        } else {
            XCTFail("No parameters for \(service)")
        }
    }
    
    func testService(service: String, serviceParameters: [String: String]) {
        if !Services.parametersEmpty(serviceParameters) {
            if let versionString = serviceParameters["version"] , version = Int(versionString) {
                
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

    func testServiceOAuth1(service: String, serviceParameters: [String: String]) {
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
        oauthswift.authorize_url_handler = handler
        
        if let allowMissingOauthVerifier = serviceParameters["allowMissingOauthVerifier"]  {
            oauthswift.allowMissingOauthVerifier = allowMissingOauthVerifier == "1" || allowMissingOauthVerifier == "true"
        }

        let expectation = self.expectationWithDescription(service)
        
        oauthswift.authorizeWithCallbackURL(NSURL(string: callbackURL)!, success: {
            credential, response, parameters in
               expectation.fulfill()
            
               print("\(service) token ok")
            }, failure: { error in
                print(error.localizedDescription)
            }
        )

        self.waitForExpectationsWithTimeout(10) { (error) -> Void in
            if let e = error {
                print("\(service): \(e.localizedDescription)")
            }
        }

    }
    
    func testServiceOAuth2(service: String, serviceParameters: [String: String]) {
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
        oauthswift.authorize_url_handler = handler
        
        let expectation = self.expectationWithDescription(service)
        
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL(NSURL(string: callbackURL)!, scope: scope, state: state, success: {
            credential, response, parameters in
            expectation.fulfill()
            
            print("\(service) token ok")
            }, failure: { error in
                print(error.localizedDescription)
            }
        )
        
        self.waitForExpectationsWithTimeout(30) { (error) -> Void in
            if let e = error {
                print("\(service): \(e.localizedDescription)")
            }
        }
        
    }
}

class ServicesURLHandlerType:NSObject, OAuthSwiftURLHandlerType {
    
    let browser = Erik()

    var service: String
    var serviceParameters: [String: String]
    var callbackURL: String
    var handled: Bool = false
    
    init?(service: String, serviceParameters: [String: String], callbackURL: String) {
        self.service = service
        self.serviceParameters = serviceParameters
        self.callbackURL = callbackURL
        
        super.init()
        
        guard let _ = self.serviceParameters["form_username_selector"],
            _ = self.serviceParameters["form_password_selector"],
            _ = self.serviceParameters["form_selector"]
            else {
                print("\(service): No selector defined for form [form_username_selector, form_password_selector, form_selector]")
                return nil
        }
        guard let _ = self.serviceParameters["form_username_value"],
            _ = self.serviceParameters["form_password_value"]
            else {
                print("\(self.service): No value defined to fill form [form_username_value, form_password_value]")
                return nil
        }

        if let engine = browser.layoutEngine as? WebKitLayoutEngine {
            engine.webView.navigationDelegate = self
        }
    }
    
    internal func handle(url: NSURL) {

        guard let form_username_selector = serviceParameters["form_username_selector"],
            form_password_selector = serviceParameters["form_password_selector"],
            form_selector = serviceParameters["form_selector"]
            else {
                XCTFail("\(service): Cannot handle \(url), no selector defined for form [form_username_selector, form_password_selector, form_selector]")
            return
        }
        
        browser.visitURL(url) {[unowned self] (document, error) in
            if self.handled {
                return // already handled (many already connected)
            }
            
            if let doc = document {
                // Fill form
                if let usernameInput = doc.querySelector(form_username_selector),
                    passwordInput = doc.querySelector(form_password_selector),
                    _ = doc.querySelector(form_selector) as? Form  {

                        guard let username = self.serviceParameters["form_username_value"],
                            password = self.serviceParameters["form_password_value"]
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
                                    passwordInput = doc.querySelector(form_password_selector) else {
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
                                    
                                    if let currentURL = self.browser.currentURL {
                                        print("\(currentURL)")
                                    }
                                    if let doc = document {
                                        self.authorizeButton(doc)
                                    }
                                }
                            }

                            // Submit form
                            if let formButton = self.serviceParameters["form_button_selector"], button = form.querySelector(formButton) {
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
                XCTFail("\(self.service): Cannot handle \(url) \(error)")
            }
        }
    }
    
    func authorizeButton(doc: Document) {
        // Submit authorization
        if let autorizeButton = self.serviceParameters["authorize_button_selector"] {
            if let button = doc.querySelector(autorizeButton) {
                button.click()
            } else {
                XCTFail("\(self.service): \(autorizeButton) not found to valid authentification]. \(self.browser.currentURL)")
            }
        } else if !self.handled {
            XCTFail("\(self.service): No [authorize_button_selector) to valid authentification]. \(self.browser.currentURL)")
        }
    }

}
import WebKit
extension ServicesURLHandlerType: WKNavigationDelegate {

    internal func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.URL {
            let urlString = "\(url)"
            if urlString.hasPrefix(self.callbackURL) {
                self.handled = true
                OAuthSwift.handleOpenURL(url)
                decisionHandler(.Cancel)
            }
            else {
                decisionHandler(.Allow)
            }
        }
    }
}