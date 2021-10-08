//
//  OAuthSwiftCredentialTests.swift
//  OAuthSwift
//
//  Created by you on 03.05.17.
//  Copyright © 2017 Dongri Jin. All rights reserved.
//

import OAuthSwift
import XCTest

/**
 Simply calls the function `f` and returns its result. It's introduced
 for semantic meaning to highlight what code should not crash, because
 swift's `XCTest` doesn't have the `XCTAssertNoThrow` assert.
 */
func nop_ShouldNotCrash <A> (_ f: @autoclosure () -> (A)) -> A {
    return f()
}

class OAuthSwiftCredentialTests: XCTestCase {

    func testEncodeShouldNotCrashWhenMainBundleIdentifierIsNil() {
        let credential = OAuthSwiftCredential(consumerKey: "foo", consumerSecret: "bar")
        let data = nop_ShouldNotCrash(NSKeyedArchiver.archivedData(withRootObject: credential))
        XCTAssertGreaterThan(data.count, 0)
    }

    func testNSCoding() {
        let credential = OAuthSwiftCredential(consumerKey: "foo", consumerSecret: "bar")
        credential.oauthToken = "token"
        credential.oauthTokenSecret = "secret"
        let data = NSKeyedArchiver.archivedData(withRootObject: credential)

        let object = NSKeyedUnarchiver.unarchiveObject(with: data) as? OAuthSwiftCredential
        XCTAssertEqual(credential, object)
    }

    func testNSCodingWithIdToken() {
        let credential = OAuthSwiftCredential(consumerKey: "foo", consumerSecret: "bar")
        credential.oauthToken = "token"
        credential.oauthTokenSecret = "secret"
        credential.idToken = "idToken"
        let data = NSKeyedArchiver.archivedData(withRootObject: credential)

        let object = NSKeyedUnarchiver.unarchiveObject(with: data) as? OAuthSwiftCredential
        XCTAssertEqual(credential, object)
    }

    func testCoding() {
        let credential = OAuthSwiftCredential(consumerKey: "foo", consumerSecret: "bar")
        credential.oauthToken = "token"
        credential.oauthTokenSecret = "secret"
        do {
            let data = try JSONEncoder().encode(credential)
            let object = try JSONDecoder().decode(OAuthSwiftCredential.self, from: data)
            XCTAssertEqual(credential, object)
        } catch {
            XCTFail("Failed to encode or decode credential \(error)")
        }
    }

    func testCodingWithIdToken() {
        let credential = OAuthSwiftCredential(consumerKey: "foo", consumerSecret: "bar")
        credential.oauthToken = "token"
        credential.oauthTokenSecret = "secret"
        credential.idToken = "idToken"

        do {
            let data = try JSONEncoder().encode(credential)
            let object = try JSONDecoder().decode(OAuthSwiftCredential.self, from: data)
            XCTAssertEqual(credential, object)
        } catch {
            XCTFail("Failed to encode or decode credential \(error)")
        }
    }

}
