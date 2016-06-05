//
//  OAuth2SwiftTests.swift
//  OAuthSwift
//
//  Created by phimage on 17/11/15.
//  Copyright © 2015 Dongri Jin. All rights reserved.
//

import XCTest
@testable import OAuthSwift

class OAuth2SwiftTests: OAuthSwiftServerBaseTest {

    let callbackURL = "test://callback"

    func testDataSuccess() {
        objc_sync_enter(server)
        let state: String = generateStateWithLength(20) as String
        testSuccess(.Data, response: .Code("code", state:state))
        objc_sync_exit(server)
    }
    func testJSON_Code_Success() {
        objc_sync_enter(server)
        let state: String = generateStateWithLength(20) as String
        testSuccess(.JSON, response: .Code("code", state:state))
        objc_sync_exit(server)
    }
    func testJSON_AccessToken_Success() {
        objc_sync_enter(server)
        testSuccess(.JSON, response: .AccessToken(server.oauth_token))
        objc_sync_exit(server)
    }

    func testSuccess(accessReturnType: TestServer.AccessReturnType, response: AccessTokenResponse) {
        let oauth = OAuth2Swift(
            consumerKey: server.valid_key,
            consumerSecret: server.valid_secret,
            authorizeUrl: server.authorizeURLV2,
            accessTokenUrl: server.accessTokenURLV2,
            responseType: response.responseType
        )
        server.accessReturnType = accessReturnType
 
        let handler = TestOAuthSwiftURLHandler(
            callbackURL: callbackURL,
            authorizeURL: server.authorizeURL,
            version: .OAuth2
        )
        handler.accessTokenResponse = response
        oauth.authorize_url_handler = handler
        
        let expectation = expectationWithDescription("request should succeed")

		var state = ""
		if case .Code(_, let extractedState) = response {
			state = extractedState ?? ""
		}
        oauth.authorizeWithCallbackURL(NSURL(string:callbackURL)!, scope: "all", state: state, params: [:],
            success: { (credential, response, parameters) -> Void in
                expectation.fulfill()
            }) { (error) -> Void in
                XCTFail("The failure handler should not be called.\(error)")
        }

        waitForExpectationsWithTimeout(DefaultTimeout, handler: nil)

        XCTAssertEqual(oauth.client.credential.oauth_token, server.oauth_token)
    }
    
    func testJSON_Error_Failure() {
        objc_sync_enter(server)
        testFailure(.JSON, response: .Error("bad", "very bad"))
        objc_sync_exit(server)
    }

    func testJSON_None_Failure() {
        objc_sync_enter(server)
        testFailure(.JSON, response: .None)
        objc_sync_exit(server)
    }
    
    func testFailure(accessReturnType: TestServer.AccessReturnType, response: AccessTokenResponse) {
        let oauth = OAuth2Swift(
            consumerKey: server.valid_key,
            consumerSecret: server.valid_secret,
            authorizeUrl: server.authorizeURLV2,
            accessTokenUrl: server.accessTokenURLV2,
            responseType: response.responseType
        )
        server.accessReturnType = accessReturnType
        
        let handler = TestOAuthSwiftURLHandler(
            callbackURL: callbackURL,
            authorizeURL: server.authorizeURL,
            version: .OAuth2
        )
        handler.accessTokenResponse = response
        oauth.authorize_url_handler = handler
        
        let expectation = expectationWithDescription("request should failed")
        
        let state: String = generateStateWithLength(20) as String
        oauth.authorizeWithCallbackURL(NSURL(string:callbackURL)!, scope: "all", state: state, params: [:],
            success: { (credential, response, parameters) -> Void in
                XCTFail("The success handler should not be called.")
            }) { (error) -> Void in
                expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(DefaultTimeout, handler: nil)
    }
    
    func testRenewsExpiredAccessToken() {
        let expectation = expectationWithDescription("request should succeed with new access token")

        let oauth = OAuth2Swift(
            consumerKey: server.valid_key,
            consumerSecret: server.valid_secret,
            authorizeUrl: server.authorizeURLV2,
            accessTokenUrl: server.accessTokenURLV2,
            responseType: "code"
        )
        oauth.client.credential.oauth_token = server.expiredAccessToken
        oauth.client.get(server.expireURLV2, parameters: [:],
            success: {
                data, response in
                XCTAssertEqual(oauth.client.credential.oauth_token, self.server.oauth_token, "Should have new access token.")
                expectation.fulfill()
            }, failure: { error in
                print(error.code)
                XCTFail("\(error).")
        })

        waitForExpectationsWithTimeout(DefaultTimeout, handler: nil)
    }
    

}
