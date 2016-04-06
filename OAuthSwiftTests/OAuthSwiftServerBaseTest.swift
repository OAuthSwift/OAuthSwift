//
//  OAuthSwiftServerBaseTest.swift
//  OAuthSwift
//
//  Created by Goessler, Florian on 04/04/16.
//  Copyright © 2016 Dongri Jin. All rights reserved.
//

import XCTest

class OAuthSwiftServerBaseTest: XCTestCase {

    static let server = TestServer()
    var server: TestServer {
        get {
            return OAuthSwiftServerBaseTest.server
        }
    }

    override class func setUp() {
        super.setUp()
        do {
            try server.start()
        }catch {
            XCTFail("Failed to start server")
        }
    }

    override class func tearDown() {
        server.stop()
        super.tearDown()
    }
}
