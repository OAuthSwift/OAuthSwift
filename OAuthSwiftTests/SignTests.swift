//
//  SignTests.swift
//  OAuthSwift
//
//  Created by phimage on 25/11/15.
//  Copyright © 2015 Dongri Jin. All rights reserved.
//

import XCTest
@testable import OAuthSwift

class SignTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testHMAC_SHA1() {
        let string = "Hello World!"
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        
        guard let hash = OAuthSwiftCredential.SignatureMethod.HMAC_SHA1.sign(data) else {
            XCTFail("Failed to hash")
            return
        }
        let hashString = hash.base64EncodedStringWithOptions([])
        XCTAssertEqual(hashString, "Lve95gjOVATpfV8EL5X4nxwjKHE=")
    }
 
}
