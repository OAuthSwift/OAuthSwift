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
    
    //Using NSLock for Linux compatible locking
    let serverLock = NSLock()
    
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
       serverLock.lock()
        let state = generateState(withLength: 20)
        testSuccess(.data, response: .code("code", state:state))
        serverLock.unlock()
    }
    func testJSON_Code_Success() {
       serverLock.lock()
        let state = generateState(withLength: 20)
        testSuccess(.json, response: .code("code", state:state))
        serverLock.unlock()
    }
    func testJSON_AccessToken_Success() {
       serverLock.lock()
        testSuccess(.json, response: .accessToken(server.oauth_token))
        serverLock.unlock()
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
            withCallbackURL: URL(string:callbackURL)!, scope: "all", state: state, parameters: [:]) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("The failure handler should not be called.\(error)")
            }
        }
        
        waitForExpectations(timeout: DefaultTimeout, handler: nil)
        
        XCTAssertEqual(oauth.client.credential.oauthToken, server.oauth_token)
    }
    
    func testJSON_Error_Failure() {
       serverLock.lock()
        testFailure(.json, response: .error("bad", "very bad"))
        serverLock.unlock()
    }

    func testJSON_None_Failure() {
       serverLock.lock()
        testFailure(.json, response: .none)
        serverLock.unlock()
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
        withCallbackURL: URL(string:callbackURL)!, scope: "all", state: state, parameters: [:]) { result in
            switch result {
            case .success:
                XCTFail("The success handler should not be called.")
            case .failure:
                expectation.fulfill()
            }
        }
        
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
        let _ = oauth.client.get(server.expireURLV2, parameters: [:]) { result in
            switch result {
            case .success(let response):
                XCTFail("data receive \(response.data).")
            case .failure(let error):
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
        }
        waitForExpectations(timeout: DefaultTimeout, handler: nil)
    }
}
