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
        
        let _ = oauth.authorize(withCallbackURL: URL(string:callbackURL)!,
            success: { (credential, response, parameters) -> Void in
                expectation.fulfill()
            },
            failure:  { (error) -> Void in
                XCTFail("The failure handler should not be called.\(error)")
        })
        
        waitForExpectations(timeout: DefaultTimeout, handler: nil)
        
        XCTAssertEqual(oauth.client.credential.oauthToken, server.oauth_token)
        XCTAssertEqual(oauth.client.credential.oauthTokenSecret, server.oauth_token_secret)
    }

    func testOAuthbinSuccess() {
        let fakeAuthorizeURL = "automatic://host/autorize"
        let oauth = OAuth1Swift(
            consumerKey: "key",
            consumerSecret: "secret",
            requestTokenUrl: "http://oauthbin.com/v1/request-token",
            authorizeUrl: fakeAuthorizeURL,
            accessTokenUrl: "http://oauthbin.com/v1/access-token"
        )
        oauth.allowMissingOAuthVerifier = true
        oauth.authorizeURLHandler = TestOAuthSwiftURLHandler(
            callbackURL: callbackURL,
            authorizeURL: fakeAuthorizeURL,
            version: .oauth1
        )
        
        let expectation = self.expectation(description: "request should succeed")
        
        let _ = oauth.authorize(
            withCallbackURL: URL(string:callbackURL)!,
            success: { credential, response, parameters in
                expectation.fulfill()
            },
            failure:  { e in
                XCTFail("The failure handler should not be called. \(e)")
            }
        )
        
        waitForExpectations(timeout: DefaultTimeout, handler: nil)
        
        let oauth_token = "accesskey"
        let oauth_token_secret = "accesssecret"
        XCTAssertEqual(oauth.client.credential.oauthToken, oauth_token)
        XCTAssertEqual(oauth.client.credential.oauthTokenSecret, oauth_token_secret)
    }
    
    func testOAuthbinBadConsumerKey() {
        let fakeAuthorizeURL = "automatic://host/autorize"
        let oauth = OAuth1Swift(
            consumerKey: "badkey",
            consumerSecret: "secret",
            requestTokenUrl: "http://oauthbin.com/v1/request-token",
            authorizeUrl: fakeAuthorizeURL,
            accessTokenUrl: "http://oauthbin.com/v1/access-token"
        )
        oauth.allowMissingOAuthVerifier = true
        oauth.authorizeURLHandler = TestOAuthSwiftURLHandler(
            callbackURL: callbackURL,
            authorizeURL: fakeAuthorizeURL,
            version: .oauth1
        )
        
        let expectation = self.expectation(description: "request should failed")
        
        let _ = oauth.authorize(
            withCallbackURL: URL(string:callbackURL)!,
            success: { credential, response, parameters in
                XCTFail("The success handler should not be called.")
            },
            failure: { error in
                //  check exact exception ? missing token?
                expectation.fulfill()
            }
        )
        
        waitForExpectations(timeout: DefaultTimeout, handler: nil)
    }
    
    func testOAuthbinBadConsumerSecret() {
        let fakeAuthorizeURL = "automatic://host/autorize"
        let oauth = OAuth1Swift(
            consumerKey: "key",
            consumerSecret: "badsecret",
            requestTokenUrl: "http://oauthbin.com/v1/request-token",
            authorizeUrl: fakeAuthorizeURL,
            accessTokenUrl: "http://oauthbin.com/v1/access-token"
        )
        oauth.allowMissingOAuthVerifier = true
        oauth.authorizeURLHandler = TestOAuthSwiftURLHandler(
            callbackURL: callbackURL,
            authorizeURL: fakeAuthorizeURL,
            version: .oauth1
        )
        
        let expectation = self.expectation(description: "request should failed")
        
        let _ = oauth.authorize(
            withCallbackURL: callbackURL,
            success: { credential, response, parameters in
                XCTFail("The success handler should not be called.")
            },
            failure:  { error in
                expectation.fulfill()
            }
        )
        
        waitForExpectations(timeout: DefaultTimeout, handler: nil)
    }

    
}
 
