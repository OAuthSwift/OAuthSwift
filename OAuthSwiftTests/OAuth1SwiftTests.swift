//
//  OAuthSwiftTests.swift
//  OAuthSwiftTests
//
//  Created by phimage on 17/11/15.
//  Copyright © 2015 Dongri Jin. All rights reserved.
//

import XCTest
@testable import OAuthSwift


let DefaultTimeout: TimeInterval = 10
class OAuth1SwiftTests: XCTestCase {
    
    static let server = TestServer()
    var server: TestServer { return OAuth1SwiftTests.server }
    
    override class func setUp() {
        super.setUp()
        do {
            server.port = 8901
            try server.start()
        }catch let e {
            XCTFail("Failed to start server \(e)")
        }
    }
    
    override class func tearDown() {
        server.stop()
        super.tearDown()
    }
    
    let callbackURL = "test://callback"
    
    func testSuccess() {
        let oauth = OAuth1Swift(
            consumerKey: server.valid_key,
            consumerSecret: server.valid_secret,
            requestTokenUrl: server.requestTokenURL,
            authorizeUrl: server.authorizeURL,
            accessTokenUrl: server.accessTokenURL
        )
        oauth.allowMissingOAuthVerifier = true
        oauth.authorizeURLHandler = TestOAuthSwiftURLHandler(
            callbackURL: callbackURL,
            authorizeURL: server.authorizeURL,
            version: .oauth1
        )
        
        let expectation = self.expectation(description: "request should succeed")
        
        let _ = oauth.authorize(withCallbackURL: URL(string:callbackURL)!) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("The failure handler should not be called.\(error)")
            }
        }
        
        waitForExpectations(timeout: DefaultTimeout, handler: nil)
        
        XCTAssertEqual(oauth.client.credential.oauthToken, server.oauth_token)
        XCTAssertEqual(oauth.client.credential.oauthTokenSecret, server.oauth_token_secret)
    }
    
    // MARK: OAuthBin: not respoding anymore, TODO new test on fake server must be implemented
    let requestTokenUrl = "http://www.oauthbin.com/v1/request-token"
    let accessTokenUrl = "http://www.oauthbin.com/v1/access-token"
    func _testOAuthbinSuccess() {
        let fakeAuthorizeURL = "automatic://host/autorize"
        let oauth = OAuth1Swift(
            consumerKey: "key",
            consumerSecret: "secret",
            requestTokenUrl: requestTokenUrl,
            authorizeUrl: fakeAuthorizeURL,
            accessTokenUrl: accessTokenUrl
        )
        oauth.allowMissingOAuthVerifier = true
        oauth.authorizeURLHandler = TestOAuthSwiftURLHandler(
            callbackURL: callbackURL,
            authorizeURL: fakeAuthorizeURL,
            version: .oauth1
        )
        
        let expectation = self.expectation(description: "request should succeed")
        
        let _ = oauth.authorize(withCallbackURL: URL(string:callbackURL)!) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let e):
                XCTFail("The failure handler should not be called. \(e)")
            }
        }
        
        waitForExpectations(timeout: DefaultTimeout, handler: nil)
        
        let oauth_token = "accesskey"
        let oauth_token_secret = "accesssecret"
        XCTAssertEqual(oauth.client.credential.oauthToken, oauth_token)
        XCTAssertEqual(oauth.client.credential.oauthTokenSecret, oauth_token_secret)
    }
    
    func _testOAuthbinBadConsumerKey() {
        let fakeAuthorizeURL = "automatic://host/autorize"
        let oauth = OAuth1Swift(
            consumerKey: "badkey",
            consumerSecret: "secret",
            requestTokenUrl: requestTokenUrl,
            authorizeUrl: fakeAuthorizeURL,
            accessTokenUrl: accessTokenUrl
        )
        oauth.allowMissingOAuthVerifier = true
        oauth.authorizeURLHandler = TestOAuthSwiftURLHandler(
            callbackURL: callbackURL,
            authorizeURL: fakeAuthorizeURL,
            version: .oauth1
        )
        
        let expectation = self.expectation(description: "request should failed")
        
        let _ = oauth.authorize(withCallbackURL: URL(string:callbackURL)!) { result in
            switch result {
            case .success:
                XCTFail("The success handler should not be called.")
            case .failure:
                //  check exact exception ? missing token?
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: DefaultTimeout, handler: nil)
    }
    
    func _testOAuthbinBadConsumerSecret() {
        let fakeAuthorizeURL = "automatic://host/autorize"
        let oauth = OAuth1Swift(
            consumerKey: "key",
            consumerSecret: "badsecret",
            requestTokenUrl: requestTokenUrl,
            authorizeUrl: fakeAuthorizeURL,
            accessTokenUrl: accessTokenUrl
        )
        oauth.allowMissingOAuthVerifier = true
        oauth.authorizeURLHandler = TestOAuthSwiftURLHandler(
            callbackURL: callbackURL,
            authorizeURL: fakeAuthorizeURL,
            version: .oauth1
        )
        
        let expectation = self.expectation(description: "request should failed")
        
        let _ = oauth.authorize(withCallbackURL: callbackURL) { result in
            switch result {
            case .success:
                XCTFail("The success handler should not be called.")
            case .failure:
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: DefaultTimeout, handler: nil)
    }
    
}
