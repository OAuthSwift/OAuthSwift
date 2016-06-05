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

    func testDetectInvalidTokensFromFacebook() {
        // given
        let createUserInfo = { (errorCode: Int, errorSubCode: Int?) -> [String:AnyObject] in
            let optionalSubcodePart = errorSubCode != nil ? ",\"error_subcode\": \(errorSubCode!)" : ""
            return [
                NSURLErrorFailingURLErrorKey: "https://graph.facebook.com/search?q=coffee&type=place&center=37.76,-122.427&distance=1000",
                "Response-Headers": [
                    "WWW-Authenticate": "OAuth \"Facebook Platform\" \"invalid_token\" \"Error validating access token: Session has expired at unix time 1334415600. The current unix time is 1334822619.\""
                ],
                "Response-Body": "{\"error\": {\"message\": \"Message describing the error\",\"type\": \"OAuthException\",\"code\": \(errorCode)\(optionalSubcodePart),\"error_user_title\": \"A title\",\"error_user_msg\": \"A message\",\"fbtrace_id\": \"EJplcsCHuLu\"}}"
            ]
        }

        // assert
        XCTAssertTrue(NSError(domain: NSURLErrorDomain, code: 400, userInfo: createUserInfo(102, nil)).isExpiredTokenError)
        XCTAssertTrue(NSError(domain: NSURLErrorDomain, code: 400, userInfo: createUserInfo(102, 463)).isExpiredTokenError)
        XCTAssertTrue(NSError(domain: NSURLErrorDomain, code: 400, userInfo: createUserInfo(102, 467)).isExpiredTokenError)

        XCTAssertFalse(NSError(domain: NSURLErrorDomain, code: 400, userInfo: createUserInfo(10, nil)).isExpiredTokenError)
        XCTAssertFalse(NSError(domain: NSURLErrorDomain, code: 400, userInfo: createUserInfo(102, 462)).isExpiredTokenError)
        XCTAssertFalse(NSError(domain: NSURLErrorDomain, code: 400, userInfo: createUserInfo(102, 465)).isExpiredTokenError)
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
