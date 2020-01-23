//
//  OAuthSwiftErrorTest.swift
//  OAuthSwift
//
//  Created by Goessler, Florian on 04/04/16.
//  Copyright © 2016 Dongri Jin. All rights reserved.
//

import XCTest
@testable import OAuthSwift

class OAuthSwiftErrorTest: XCTestCase {

	func testDetectInvalidTokenError() {
		// given
		let userInfo = [
			"Response-Headers": [
				"WWW-Authenticate": "Bearer realm=\"example\", error=\"invalid_token\", error_description=\"The access token expired\""
			]
		]
		let error = NSError(domain: OAuthSwiftError.Domain, code: 401, userInfo: userInfo)

		// assert
		XCTAssertTrue(error.isExpiredToken)
        XCTAssertTrue(((error as Error) as NSError).isExpiredToken)
	}

    func testDetectInvalidTokenFromTwitter() {
        // given
        let userInfo = [
            NSURLErrorFailingURLErrorKey: "https://api.twitter.com/1.1/account/verify_credentials.json",
            "Response-Body": "{\"errors\":[{\"code\":89,\"message\":\"Invalid or expired token.\"}]}"
        ]
        // Twitter error details are here: https://developer.twitter.com/en/docs/basics/response-codes
        let error = NSError(domain: OAuthSwiftError.Domain, code: 401, userInfo: userInfo)

        // assert
        XCTAssertTrue(error.isExpiredToken)
        XCTAssertTrue(((error as Error) as NSError).isExpiredToken)
    }

    func testDetectInvalidTokensFromFacebook() {
        // given
        let createUserInfo = { (errorCode: Int, errorSubCode: Int?) -> [String:Any] in
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
        XCTAssertTrue(NSError(domain: OAuthSwiftError.Domain, code: 400, userInfo: createUserInfo(102, nil)).isExpiredToken)
        XCTAssertTrue(NSError(domain: OAuthSwiftError.Domain, code: 400, userInfo: createUserInfo(102, 463)).isExpiredToken)
        XCTAssertTrue(NSError(domain: OAuthSwiftError.Domain, code: 400, userInfo: createUserInfo(102, 467)).isExpiredToken)

        XCTAssertFalse(NSError(domain: OAuthSwiftError.Domain, code: 400, userInfo: createUserInfo(10, nil)).isExpiredToken)
        XCTAssertFalse(NSError(domain: OAuthSwiftError.Domain, code: 400, userInfo: createUserInfo(102, 462)).isExpiredToken)
        XCTAssertFalse(NSError(domain: OAuthSwiftError.Domain, code: 400, userInfo: createUserInfo(102, 465)).isExpiredToken)
    }

	func testIgnoreOtherErrors() {
		// given
		let userInfo = [
			"Response-Headers": [
				"WWW-Authenticate": "Bearer realm=\"example\""
			]
		]

		// assert
		XCTAssertFalse(NSError(domain: OAuthSwiftError.Domain, code: 401, userInfo: userInfo).isExpiredToken)
		XCTAssertFalse(NSError(domain: OAuthSwiftError.Domain, code: 400, userInfo: userInfo).isExpiredToken)
		XCTAssertFalse(NSError(domain: OAuthSwiftError.Domain, code: 500, userInfo: userInfo).isExpiredToken)
	}
    
    
    /* // dome test about code (now private)
     func testOAuthSwiftError() {
     testOAuthSwiftError(.configurationError(message: "message"))
     testOAuthSwiftError(.tokenExpired)
     testOAuthSwiftError(.missingState)
     testOAuthSwiftError(.stateNotEqual(state: "state", responseState: "responseState"))
     testOAuthSwiftError(.serverError(message: "message"))
     testOAuthSwiftError(.encodingError(urlString: "urlString"))
     testOAuthSwiftError(.authorizationPending)
     testOAuthSwiftError(.requestCreation(message: "message"))
     testOAuthSwiftError(.missingToken)
     testOAuthSwiftError(.retain)
     }
     
     func testOAuthSwiftError(_ error: OAuthSwiftError) {
     let code = error.code
     let rawValue = code.rawValue
     
     var nsCode = error.nsError.code
     XCTAssertEqual(nsCode, rawValue)
     
     let nsError = (error as NSError)
     nsCode = nsError.code
     XCTAssertEqual(nsCode, rawValue)
     let userInfo = nsError.userInfo
     print(userInfo)
     }
     */

}
