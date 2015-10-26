//
//  OAuthSwiftHTTPRequestTests.swift
//  OAuthSwift
//
//  Created by Benjamin Boxler on 26/10/2015.
//  Copyright © 2015 Dongri Jin. All rights reserved.
//

import XCTest
@testable import OAuthSwift
import OHHTTPStubs

class OAuthSwiftHTTPRequestTests: OAuthSwiftTests {

    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }
    
    func testFailure() {
        let oAuthSwiftHTTPRequest = OAuthSwiftHTTPRequest(URL: NSURL(string: "http://127.0.0.1")!)
        let failureExpectation = expectationWithDescription("Expexted `failure` to be called")
        oAuthSwiftHTTPRequest.failureHandler = { _ in
            failureExpectation.fulfill()
        }
        oAuthSwiftHTTPRequest.successHandler = { _ in
            XCTFail("The success handler should not be called. This can happen if you have a\nlocal server running on :80")
        }

        oAuthSwiftHTTPRequest.start()
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testSuccess() {
        // Stub the request to return something
        OHHTTPStubs.stubRequestsPassingTest({ request in
                return request.URL!.host == "127.0.0.1"
            }, withStubResponse: { _ in
                return OHHTTPStubsResponse(
                    data: NSString(string: "Success!").dataUsingEncoding(NSUTF8StringEncoding)!,
                    statusCode: 200, headers: nil)

        })

        let oAuthSwiftHTTPRequest = OAuthSwiftHTTPRequest(URL: NSURL(string: "http://127.0.0.1")!)
        let successExpectation = expectationWithDescription("Expexted `failure` to be called")
        oAuthSwiftHTTPRequest.failureHandler = { _ in
            XCTFail("The failure handler should not be called.")
        }
        oAuthSwiftHTTPRequest.successHandler = { (data, response) in
            if String(data: data, encoding: NSUTF8StringEncoding) == "Success!" {
                successExpectation.fulfill()
            }
        }

        oAuthSwiftHTTPRequest.start()
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
}
