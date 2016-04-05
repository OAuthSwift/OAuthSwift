//
//  NSErrorOAuthSwiftTest.swift
//  OAuthSwift
//
//  Created by Goessler, Florian on 04/04/16.
//  Copyright © 2016 Dongri Jin. All rights reserved.
//

import XCTest
@testable import OAuthSwift

class NSErrorOAuthSwiftTest: XCTestCase {

	func testDetectInvalidTokenError() {
		// given
		let userInfo = [
			"Response-Headers": [
				"WWW-Authenticate": "Bearer realm=\"example\", error=\"invalid_token\", error_description=\"The access token expired\""
			]
		]
		let error = NSError(domain: NSURLErrorDomain, code: 401, userInfo: userInfo)

		// assert
		XCTAssertTrue(error.isExpiredTokenError)
	}

	func testIgnoreOtherErrors() {
		// given
		let userInfo = [
			"Response-Headers": [
				"WWW-Authenticate": "Bearer realm=\"example\""
			]
		]

		// assert
		XCTAssertFalse(NSError(domain: NSURLErrorDomain, code: 401, userInfo: userInfo).isExpiredTokenError)
		XCTAssertFalse(NSError(domain: NSURLErrorDomain, code: 400, userInfo: userInfo).isExpiredTokenError)
		XCTAssertFalse(NSError(domain: NSURLErrorDomain, code: 500, userInfo: userInfo).isExpiredTokenError)
	}
}
