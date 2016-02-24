//
//  OAuthSwiftTests.swift
//  OAuthSwiftTests
//
//  Created by phimage on 17/11/15.
//  Copyright © 2015 Dongri Jin. All rights reserved.
//

import XCTest
@testable import OAuthSwift


let DefaultTimeout: NSTimeInterval = 10
class OAuthSwiftTests: XCTestCase {
    
    let server = TestServer()
    let callbackURL = "test://callback"
    
    override func setUp() {
        super.setUp()
        do {
            try server.start()
        }catch {
            XCTFail("Failed to start server")
        }
    }
    
    override func tearDown() {
        server.stop()
        super.tearDown()
    }
    
    func testSuccess() {
        let oauth = OAuth1Swift(
            consumerKey: server.valid_key,
            consumerSecret: server.valid_secret,
            requestTokenUrl: server.requestTokenURL,
            authorizeUrl: server.authorizeURL,
            accessTokenUrl: server.accessTokenURL
        )
        oauth.allowMissingOauthVerifier = true
        oauth.authorize_url_handler = TestOAuthSwiftURLHandler(
            callbackURL: callbackURL,
            authorizeURL: server.authorizeURL,
            version: .OAuth1
        )
        
        let expectation = expectationWithDescription("request should succeed")
        
        oauth.authorizeWithCallbackURL(NSURL(string:callbackURL)!,
            success: { (credential, response, parameters) -> Void in
                expectation.fulfill()
            },
            failure:  { (error) -> Void in
                XCTFail("The failure handler should not be called.\(error)")
        })
        
        waitForExpectationsWithTimeout(DefaultTimeout, handler: nil)
        
        XCTAssertEqual(oauth.client.credential.oauth_token, server.oauth_token)
        XCTAssertEqual(oauth.client.credential.oauth_token_secret, server.oauth_token_secret)
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
        oauth.allowMissingOauthVerifier = true
        oauth.authorize_url_handler = TestOAuthSwiftURLHandler(
            callbackURL: callbackURL,
            authorizeURL: fakeAuthorizeURL,
            version: .OAuth1
        )
        
        let expectation = expectationWithDescription("request should succeed")
        
        oauth.authorizeWithCallbackURL(NSURL(string:callbackURL)!,
            success: { (credential, response, parameters) -> Void in
                expectation.fulfill()
            },
            failure:  { (error) -> Void in
                XCTFail("The failure handler should not be called.")
        })
        
        waitForExpectationsWithTimeout(DefaultTimeout, handler: nil)
        
        let oauth_token = "accesskey"
        let oauth_token_secret = "accesssecret"
        XCTAssertEqual(oauth.client.credential.oauth_token, oauth_token)
        XCTAssertEqual(oauth.client.credential.oauth_token_secret, oauth_token_secret)
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
        oauth.allowMissingOauthVerifier = true
        oauth.authorize_url_handler = TestOAuthSwiftURLHandler(
            callbackURL: callbackURL,
            authorizeURL: fakeAuthorizeURL,
            version: .OAuth1
        )
        
        let expectation = expectationWithDescription("request should failed")
        
        oauth.authorizeWithCallbackURL(NSURL(string:callbackURL)!,
            success: { (credential, response, parameters) -> Void in
                XCTFail("The success handler should not be called.")
            },
            failure:  { (error) -> Void in
                expectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(DefaultTimeout, handler: nil)
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
        oauth.allowMissingOauthVerifier = true
        oauth.authorize_url_handler = TestOAuthSwiftURLHandler(
            callbackURL: callbackURL,
            authorizeURL: fakeAuthorizeURL,
            version: .OAuth1
        )
        
        let expectation = expectationWithDescription("request should failed")
        
        oauth.authorizeWithCallbackURL(NSURL(string:callbackURL)!,
            success: { (credential, response, parameters) -> Void in
                XCTFail("The success handler should not be called.")
            },
            failure:  { (error) -> Void in
                expectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(DefaultTimeout, handler: nil)
    }

    
    
    
}
 