//
//  OAuthSwiftHTTPRequestTests.swift
//  OAuthSwift
//
//  Created by Benjamin Boxler on 26/10/2015.
//  Copyright © 2015 Dongri Jin. All rights reserved.
//

import XCTest
@testable import OAuthSwift

class OAuthSwiftHTTPRequestTests: OAuthSwiftTests {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFailure() {
        let oAuthSwiftHTTPRequest = OAuthSwiftHTTPRequest(URL: NSURL(string: "http://127.0.0.1")!)
        let failureExpectation = expectationWithDescription("Expexted `failure` to be called")
        oAuthSwiftHTTPRequest.start()
        oAuthSwiftHTTPRequest.failureHandler = { _ in
            failureExpectation.fulfill()
        }
        oAuthSwiftHTTPRequest.successHandler = { _ in
            XCTFail("The success handler should not be called. This can happen if you have a\nlocal server running on :80")
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testSuccess() {
        let oAuthSwiftHTTPRequest = OAuthSwiftHTTPRequest(URL: NSURL(string: "http://127.0.0.1")!)
        let successExpectation = expectationWithDescription("Expexted `failure` to be called")
        oAuthSwiftHTTPRequest.start()
        oAuthSwiftHTTPRequest.failureHandler = { _ in
            XCTFail("The failure handler should not be called.")
        }
        oAuthSwiftHTTPRequest.successHandler = { _ in
            successExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
}
