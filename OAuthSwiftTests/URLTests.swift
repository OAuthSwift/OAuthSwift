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
    }

    func testWithQueryWithFlag() {
        let url = URL(string: "http://localhost/?close&code=azeaze")
        var responseParameters = [String: String]()
        if let query = url?.query {
            responseParameters += query.parametersFromQueryString
        }
        XCTAssertFalse(responseParameters.isEmpty)
        XCTAssertNotNil(responseParameters["code"])
    }

    func testWithQueryWithMultipleFlag() {
        let url = URL(string: "http://localhost/?close&test&code=azeaze&flag")
        var responseParameters = [String: String]()
        if let query = url?.query {
            responseParameters += query.parametersFromQueryString
        }
        XCTAssertFalse(responseParameters.isEmpty)
        XCTAssertNotNil(responseParameters["code"])
    }

}
