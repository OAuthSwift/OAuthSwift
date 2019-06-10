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
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testFailure() {
        let oAuthSwiftHTTPRequest = OAuthSwiftHTTPRequest(url: URL(string: "http://127.0.0.1:\(8765)")!)
        
        let failureExpectation = expectation(description: "Expected `failure` to be called")

        let completionHandler: OAuthSwiftHTTPRequest.CompletionHandler = { result in
            switch result {
            case .success:
                XCTFail("The success handler should not be called. This can happen if you have a\nlocal server running on :\(8765)")
            case .failure:
                 failureExpectation.fulfill()
            }
        }
        
        oAuthSwiftHTTPRequest.start(completionHandler: completionHandler)
        waitForExpectations(timeout: DefaultTimeout, handler: nil)
    }

    func testSuccess() {
        let server  = HttpServer()
        server["/"] = { request in
            return HttpResponse.ok(HttpResponseBody.text("Success!" as String) )
        }
        let port: in_port_t = 8765
        do {
            try server.start(port)
        } catch let e {
            XCTFail("\(e)")
        }
        defer {
            server.stop()
        }
        
        let oAuthSwiftHTTPRequest = OAuthSwiftHTTPRequest(url: URL(string: "http://127.0.0.1:\(port)")!)
        let successExpectation = expectation(description: "Expected `failure` to be called")
        
        let completionHandler: OAuthSwiftHTTPRequest.CompletionHandler = { result in
            switch result {
            case .success(let response):
                if response.string == "Success!" {
                    successExpectation.fulfill()
                }
            case .failure(let error):
                XCTFail("The failure handler should not be called.\(error)")
            }
        }
        
        oAuthSwiftHTTPRequest.start(completionHandler: completionHandler)
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
        let port: in_port_t = 8769
		try? server.start(port)
		defer {
			server.stop()
		}

		let oAuthSwiftHTTPRequest = OAuthSwiftHTTPRequest(url: URL(string: "http://127.0.0.1:\(port)")!)

		let failureExpectation = expectation(description: "Expected `failure` to be called because of canceling the request")

		let completionHandler: OAuthSwiftHTTPRequest.CompletionHandler  = { result in
            
            switch result {
            case .success:
                XCTFail("The success handler should not be called. This can happen if you have a\nlocal server running on :\(port)")
            case .failure(let error):
                switch error {
                case .cancelled:
                    failureExpectation.fulfill()
                case .requestError(let error, _):
                    XCTAssertEqual(error._code, NSURLErrorCancelled) // old ways
                default:
                    XCTFail("Wrong error type: \(error)")
                }
            }
		}

		oAuthSwiftHTTPRequest.start(completionHandler: completionHandler)
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
		var request = URLRequest(url: urlWithQueryString)
		request.allHTTPHeaderFields = headers
		request.httpMethod = method.rawValue
		request.httpBody = bodyText.data(using: OAuthSwiftDataEncoding)
		request.timeoutInterval = timeout
		request.httpShouldHandleCookies = true

		let oauthRequest = OAuthSwiftHTTPRequest(request: request)

		XCTAssertEqualURL(oauthRequest.config.urlRequest.url!, urlWithQueryString)
		XCTAssertEqualDictionaries(oauthRequest.config.parameters as! [String:String], [:])
		XCTAssertEqualDictionaries(oauthRequest.config.urlRequest.allHTTPHeaderFields!, headers)
		XCTAssertEqual(oauthRequest.config.httpMethod, method)
		XCTAssertEqual(String(data: oauthRequest.config.urlRequest.httpBody!, encoding:OAuthSwiftDataEncoding)!, bodyText)
		XCTAssertEqual(oauthRequest.config.urlRequest.timeoutInterval, timeout)
		XCTAssertTrue(oauthRequest.config.urlRequest.httpShouldHandleCookies)
	}
}
