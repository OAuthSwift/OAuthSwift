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

class OAuth1SwiftRequestTests: XCTestCase {
    
    var port: in_port_t = 8765
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testFailure() {
        let oAuthSwiftHTTPRequest = OAuthSwiftHTTPRequest(URL: URL(string: "http://127.0.0.1:\(port)")!)
        
        let failureExpectation = expectation(description: "Expected `failure` to be called")
        oAuthSwiftHTTPRequest.failureHandler = { _ in
            failureExpectation.fulfill()
        }
        oAuthSwiftHTTPRequest.successHandler = { _ in
            XCTFail("The success handler should not be called. This can happen if you have a\nlocal server running on :\(self.port)")
        }
        
        oAuthSwiftHTTPRequest.start()
        waitForExpectations(timeout: DefaultTimeout, handler: nil)
    }

    func testSuccess() {
        let server  = HttpServer()
        server["/"] = { request in
            return HttpResponse.ok(HttpResponseBody.text("Success!" as String) )
        }
        
        try! server.start(self.port)
        defer {
            server.stop()
        }
        
        let oAuthSwiftHTTPRequest = OAuthSwiftHTTPRequest(URL: URL(string: "http://127.0.0.1:\(port)")!)
        let successExpectation = expectation(description: "Expected `failure` to be called")
        oAuthSwiftHTTPRequest.failureHandler = { error in
            XCTFail("The failure handler should not be called.\(error)")
        }
        oAuthSwiftHTTPRequest.successHandler = { (data, response) in
            if String(data: data, encoding: String.Encoding.utf8) == "Success!" {
                successExpectation.fulfill()
            }
        }
        
        oAuthSwiftHTTPRequest.start()
        waitForExpectations(timeout: DefaultTimeout, handler: nil)
    }

	func testCancel() {
		let origExecContext = OAuthSwiftHTTPRequest.executionContext
		OAuthSwiftHTTPRequest.executionContext = { $0() }
		defer  {
			OAuthSwiftHTTPRequest.executionContext = origExecContext
		}

		let server  = HttpServer()
		server["/"] = { request in
			sleep(2)
			return HttpResponse.ok(HttpResponseBody.text("Success!" as String) )
		}
		try! server.start(self.port)
		defer {
			server.stop()
		}

		let oAuthSwiftHTTPRequest = OAuthSwiftHTTPRequest(URL: URL(string: "http://127.0.0.1:\(port)")!)

		let failureExpectation = expectation(description: "Expected `failure` to be called because of canceling the request")
		oAuthSwiftHTTPRequest.failureHandler = { error in
			XCTAssertEqual(error.code, NSURLErrorCancelled)
			failureExpectation.fulfill()
		}
		oAuthSwiftHTTPRequest.successHandler = { _ in
			XCTFail("The success handler should not be called. This can happen if you have a\nlocal server running on :\(self.port)")
		}

		oAuthSwiftHTTPRequest.start()
		oAuthSwiftHTTPRequest.cancel()
		waitForExpectations(timeout: DefaultTimeout, handler: nil)
	}

	func testCreationFromNSURLRequest() {
		let urlWithoutQueryString = URL(string: "www.example.com")!
		let queryParams = ["a":"123", "b": "", "complex param":"ha öäü ?$"]
		let headers = ["SomeHeader":"With a value"]
		let method = OAuthSwiftHTTPRequest.Method.PUT
		let bodyText = "Test Body"
		let timeout: TimeInterval = 78

		var urlComps = URLComponents(url: urlWithoutQueryString, resolvingAgainstBaseURL: false)
		urlComps?.queryItems = queryParams.keys.map { URLQueryItem(name: $0, value: queryParams[$0]) }
		let urlWithQueryString = urlComps!.url!
		let request = NSMutableURLRequest(url: urlWithQueryString)
		request.allHTTPHeaderFields = headers
		request.httpMethod = method.rawValue
		request.httpBody = bodyText.data(using: OAuthSwiftDataEncoding)
		request.timeoutInterval = timeout
		request.httpShouldHandleCookies = true

		let oauthRequest = OAuthSwiftHTTPRequest(request: request as URLRequest)

		XCTAssertEqualURL(oauthRequest.URL, urlWithQueryString)
		XCTAssertEqualDictionaries(oauthRequest.parameters as! [String:String], [:])
		XCTAssertEqualDictionaries(oauthRequest.headers, headers)
		XCTAssertEqual(oauthRequest.HTTPMethod, method)
		XCTAssertEqual(String(data: oauthRequest.HTTPBody!, encoding:OAuthSwiftDataEncoding)!, bodyText)
		XCTAssertEqual(oauthRequest.timeoutInterval, timeout)
		XCTAssertTrue(oauthRequest.HTTPShouldHandleCookies)
	}
}
