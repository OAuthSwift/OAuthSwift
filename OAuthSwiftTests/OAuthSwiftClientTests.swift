//
//  OAuthSwiftClientTests.swift
//  OAuthSwift
//
//  Created by phimage on 19/11/15.
//  Copyright © 2015 Dongri Jin. All rights reserved.
//

import XCTest
@testable import OAuthSwift

class OAuthSwiftClientTests: XCTestCase {

    let client = OAuthSwiftClient(consumerKey: "", consumerSecret: "")
    let url = "http://www.example.com"
    let emptyParameters = [String:String]()

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testMakeRequest() {
        testMakeRequest(url, emptyParameters, url, emptyParameters)
        testMakeRequest(url, ["a":"a"], url, ["a":"a"])
        testMakeRequest(url, ["a":"a", "b":"b"], url,   ["a":"a", "b":"b"])
    }
    
    /*func testMakeRequestURLWithQuery() { // deprecated test if no url change
        testMakeRequest("\(url)?a=a", emptyParameters, url, ["a":"a"])
        testMakeRequest("\(url)?a=a&b=b", emptyParameters, url,   ["a":"a", "b":"b"])
        testMakeRequest("\(url)?b=b&a=a", emptyParameters, url,   ["a":"a", "b":"b"])
    }*/
    
    /*func testMakeRequestURLWithQueryAndParams() { // deprecated test if no url change
        testMakeRequest("\(url)?a=a", ["c":"c"], url, ["a":"a", "c":"c"])
        testMakeRequest("\(url)?a=a&b=b", ["c":"c"], url,   ["a":"a", "b":"b", "c":"c"])
        testMakeRequest("\(url)?b=b&a=a", ["c":"c"], url,   ["a":"a", "b":"b", "c":"c"])
    }*/
    
    
    func testMakeRequest(url: String,_ parameters: [String:AnyObject],_ expectedURL: String,_ expectedParameters: [String:String]) {

        let request = client.makeRequest(url, method: .GET, parameters: parameters)!

        let requestURL = request.valueForKey("URL") as! NSURL
        let requestParameters = request.valueForKey("parameters") as! [String:String]
        
        XCTAssertEqual(requestURL, NSURL(string: expectedURL)!)
        XCTAssertEqualDictionaries(requestParameters, expectedParameters)
        
        do {
            let urlFromRequest = try request.makeRequest()
            
            var url = NSURL(string: url)
            let queryString = parameters.urlEncodedQueryStringWithEncoding(OAuthSwiftDataEncoding)
            url = url?.URLByAppendingQueryString(queryString)

            XCTAssertEqualURL(urlFromRequest.URL!, url!)
            
        } catch let e {
            XCTFail("\(e)")
        }
    }
}

extension XCTestCase {
    
    func XCTAssertEqualURL(first: NSURL, _ second: NSURL, _ message: String = "") {
        
        let firstC = NSURLComponents(URL: first, resolvingAgainstBaseURL: false)!
        let secondC = NSURLComponents(URL: second, resolvingAgainstBaseURL: false)!
        
        XCTAssertEqual(firstC.host, secondC.host, "host:" + message)
        XCTAssertEqual(firstC.scheme, secondC.scheme, "scheme:" + message)
        XCTAssertEqual(firstC.path, secondC.path, "path:" + message)
        XCTAssertEqual(firstC.user, secondC.user, "user:" + message)
        XCTAssertEqual(firstC.password, secondC.password, "password:" + message)
        if let firstItems = firstC.queryItems {
            if let secondItems = secondC.queryItems {
                XCTAssertEqual(firstItems.sort({ $0.name > $1.name }), secondItems.sort({ $0.name > $1.name }),  "queryItems:" + message)
            } else {
                XCTFail("queryItems:" + message)
            }
        }
        else  if let _ = secondC.queryItems {
            XCTFail("queryItems:" + message)
        }
    }

    func XCTAssertEqualDictionaries<S, T: Equatable>(first: [S:T], _ second: [S:T], _ message: String = "") {
        XCTAssertTrue(first == second, message.isEmpty ? "\(first) != \(second)" : message)
    }

}
