//
//  URLTests.swift
//  OAuthSwiftTests
//
//  Created by Eric Marchand on 17/04/2018.
//  Copyright © 2018 Dongri Jin. All rights reserved.
//

import Foundation

import XCTest
@testable import OAuthSwift

class URLTest: XCTestCase {

    func testNoQuery() {
        let url = URL(string: "http://localhost/")
        var responseParameters = [String: String]()
        if let query = url?.query {
            responseParameters += query.parametersFromQueryString
        }
        XCTAssertTrue(responseParameters.isEmpty)
    }
    func testWithQuery() {
        let url = URL(string: "http://localhost/?code=azeaze")
        var responseParameters = [String: String]()
        if let query = url?.query {
            responseParameters += query.parametersFromQueryString
        }
        XCTAssertFalse(responseParameters.isEmpty)
        XCTAssertNotNil(responseParameters["code"])
        XCTAssertEqual(responseParameters["code"], "azeaze")
    }

    func testWithQueryMultiple() {
        let url = URL(string: "http://localhost/?code=azeaze&code2=zaeaze")
        var responseParameters = [String: String]()
        if let query = url?.query {
            responseParameters += query.parametersFromQueryString
        }
        XCTAssertFalse(responseParameters.isEmpty)
        XCTAssertNotNil(responseParameters["code"])
        XCTAssertEqual(responseParameters["code"], "azeaze")
        XCTAssertNotNil(responseParameters["code2"])
        XCTAssertEqual(responseParameters["code2"], "zaeaze")
    }

    func testWithQueryWithFlag() {
        let url = URL(string: "http://localhost/?close&code=azeaze")
        var responseParameters = [String: String]()
        if let query = url?.query {
            responseParameters += query.parametersFromQueryString
        }
        XCTAssertFalse(responseParameters.isEmpty)
        XCTAssertNotNil(responseParameters["close"])
        XCTAssertNotNil(responseParameters["code"])
        XCTAssertEqual(responseParameters["code"], "azeaze")
    }

    func testWithQueryWithMultipleFlag() {
        let url = URL(string: "http://localhost/?close&test&code=azeaze&flag")
        var responseParameters = [String: String]()
        if let query = url?.query {
            responseParameters += query.parametersFromQueryString
        }
        XCTAssertFalse(responseParameters.isEmpty)
        XCTAssertNotNil(responseParameters["close"])
        XCTAssertNotNil(responseParameters["code"])
        XCTAssertEqual(responseParameters["code"], "azeaze")
        XCTAssertNotNil(responseParameters["flag"])
    }

    func testWithQueryWithMultipleFlagAndValue() {
        let url = URL(string: "http://localhost/?close&test&code=azeaze&code2=zaeaze&flag")
        var responseParameters = [String: String]()
        if let query = url?.query {
            responseParameters += query.parametersFromQueryString
        }
        XCTAssertFalse(responseParameters.isEmpty)
        XCTAssertNotNil(responseParameters["close"])
        XCTAssertNotNil(responseParameters["code"])
        XCTAssertEqual(responseParameters["code"], "azeaze")
        XCTAssertNotNil(responseParameters["code2"])
        XCTAssertEqual(responseParameters["code2"], "zaeaze")
        XCTAssertNotNil(responseParameters["flag"])
    }
}
