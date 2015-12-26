//
//  OAuthSwiftRequestTests.swift
//  OAuthSwift
//
//  Created by phimage on 17/11/15.
//  Copyright © 2015 Dongri Jin. All rights reserved.
//

import XCTest
@testable import OAuthSwift
import Swifter

class OAuthSwiftRequestTests: XCTestCase {
    
    var port: in_port_t = 8765
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testFailure() {
        let oAuthSwiftHTTPRequest = OAuthSwiftHTTPRequest(URL: NSURL(string: "http://127.0.0.1:\(port)")!)
        
        let failureExpectation = expectationWithDescription("Expected `failure` to be called")
        oAuthSwiftHTTPRequest.failureHandler = { _ in
            failureExpectation.fulfill()
        }
        oAuthSwiftHTTPRequest.successHandler = { _ in
            XCTFail("The success handler should not be called. This can happen if you have a\nlocal server running on :\(self.port)")
        }
        
        oAuthSwiftHTTPRequest.start()
        waitForExpectationsWithTimeout(DefaultTimeout, handler: nil)
    }

    func testSuccess() {
        let server  = HttpServer()
        server["/"] = { request in
            return HttpResponse.OK(HttpResponseBody.Text("Success!" as String) )
        }
        
        try! server.start(self.port)
        defer {
            server.stop()
        }
        
        let oAuthSwiftHTTPRequest = OAuthSwiftHTTPRequest(URL: NSURL(string: "http://127.0.0.1:\(port)")!)
        let successExpectation = expectationWithDescription("Expected `failure` to be called")
        oAuthSwiftHTTPRequest.failureHandler = { error in
            XCTFail("The failure handler should not be called.\(error)")
        }
        oAuthSwiftHTTPRequest.successHandler = { (data, response) in
            if String(data: data, encoding: NSUTF8StringEncoding) == "Success!" {
                successExpectation.fulfill()
            }
        }
        
        oAuthSwiftHTTPRequest.start()
        waitForExpectationsWithTimeout(DefaultTimeout, handler: nil)
    }
    
}
