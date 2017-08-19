//
//  OAuth2SwiftTests.swift
//  OAuthSwift
//
//  Created by phimage on 17/11/15.
//  Copyright © 2015 Dongri Jin. All rights reserved.
//

import XCTest
@testable import OAuthSwift

class OAuth2SwiftTests: XCTestCase {
    
    static let server = TestServer()
    var server: TestServer { return OAuth2SwiftTests.server }

    override class func setUp() {
        super.setUp()
        do {
            server.port = 8902
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

    func testDataSuccess() {
        objc_sync_enter(server)
        let state = generateState(withLength: 20)
        testSuccess(.data, response: .code("code", state:state))
        objc_sync_exit(server)
    }
    func testJSON_Code_Success() {
        objc_sync_enter(server)
        let state = generateState(withLength: 20)
        testSuccess(.json, response: .code("code", state:state))
        objc_sync_exit(server)
    }
    func testJSON_AccessToken_Success() {
        objc_sync_enter(server)
        testSuccess(.json, response: .accessToken(server.oauth_token))
        objc_sync_exit(server)
    }

    func testSuccess(_ accessReturnType: TestServer.AccessReturnType, response: AccessTokenResponse) {
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
            version: .oauth2
        )
        handler.accessTokenResponse = response
        oauth.authorizeURLHandler = handler
        
        let expectation = self.expectation(description: "request should succeed")

		var state = ""
		if case .code(_, let extractedState) = response {
			state = extractedState ?? ""
		}
        let _ = oauth.authorize(
            withCallbackURL: URL(string:callbackURL)!, scope: "all", state: state, parameters: [:],
            success: { credential, response, parameters in
                expectation.fulfill()
            },
            failure: { error in
                XCTFail("The failure handler should not be called.\(error)")
            }
        )
        
        waitForExpectations(timeout: DefaultTimeout, handler: nil)
        
        XCTAssertEqual(oauth.client.credential.oauthToken, server.oauth_token)
    }
    
    func testJSON_Error_Failure() {
        objc_sync_enter(server)
        testFailure(.json, response: .error("bad", "very bad"))
        objc_sync_exit(server)
    }

    func testJSON_None_Failure() {
        objc_sync_enter(server)
        testFailure(.json, response: .none)
        objc_sync_exit(server)
    }
    
    func testFailure(_ accessReturnType: TestServer.AccessReturnType, response: AccessTokenResponse) {
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
            version: .oauth2
        )
        handler.accessTokenResponse = response
        oauth.authorizeURLHandler = handler
        
        let expectation = self.expectation(description: "request should failed")
        
        let state = generateState(withLength: 20)
        let _ = oauth.authorize(
            withCallbackURL: URL(string:callbackURL)!, scope: "all", state: state, parameters: [:],
            success: { credential, response, parameters in
                XCTFail("The success handler should not be called.")
            },
            failure: { error in
                expectation.fulfill()
            }
        )
        
        waitForExpectations(timeout: DefaultTimeout, handler: nil)
    }
    
    func testExpire() {
        let expectation = self.expectation(description: "request should failed")
        
        
        let oauth = OAuth2Swift(
            consumerKey: server.valid_key,
            consumerSecret: server.valid_secret,
            authorizeUrl: server.authorizeURLV2,
            accessTokenUrl: server.accessTokenURLV2,
            responseType: "code"
        )
        let _ = oauth.client.get(
            server.expireURLV2, parameters: [:],
            success: { response in
                XCTFail("data receive \(response.data).")
            },
            failure: { error in
                switch error {
                case .tokenExpired(let error):
                    expectation.fulfill()
                    
                    // additional check about origin error
                    let nserror = error as NSError?
                    if nserror?.code == 401 {
                        if let reponseHeaders = nserror?.userInfo["Response-Headers"] as? [String:String],
                            let authenticateHeader = reponseHeaders["WWW-Authenticate"] ?? reponseHeaders["Www-Authenticate"] {
                            print(authenticateHeader)
                            
                            
                            let headerDictionary = authenticateHeader.headerDictionary
                            print(headerDictionary["error"] ?? "no error")
                            print(headerDictionary["error_description"] ?? "no error description")
                        }
                        else {
                            XCTFail("\(String(describing: error)).")
                        }
                    }
                default:
                    XCTFail("Wrong exception type \(error)")
                }
            }
        )
        waitForExpectations(timeout: DefaultTimeout, handler: nil)
    }
    

}
