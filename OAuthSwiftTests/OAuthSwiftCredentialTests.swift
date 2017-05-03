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
}
