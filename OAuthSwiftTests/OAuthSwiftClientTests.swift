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
        testMakeRequest(.GET, url:url, emptyParameters, url)
        testMakeRequest(.GET, url:url, ["a":"a"], "\(url)?a=a")
        testMakeRequest(.GET, url:url, ["a":"a", "b":"b"], "\(url)?a=a&b=b")
    }
    
    func testMakeRequestViaNSURLRequest() {
        testMakeNSURLRequest(.GET, url)
        testMakeNSURLRequest(.POST, url)
        testMakeNSURLRequest(.GET, url + "?a=a")
        testMakeNSURLRequest(.GET, url + "?a=a&b=b")
    }

    func testMakePOSTRequest() {
        testMakeRequest(.POST, url:url, emptyParameters, url, nil)
        testMakeRequest(.POST, url:url, ["a":"a"], url, ["a":"a"])
        testMakeRequest(.POST, url:url, ["a":"a", "b":"b"], url, ["a":"a", "b":"b"])
        testMakeRequest(.POST, url:"\(url)?c=c", ["a":"a", "b":"b"], "\(url)?c=c", ["a":"a", "b":"b"])
    }

    func testMakeRequestURLWithQuery() {
        testMakeRequest(.GET, url:"\(url)?a=a", emptyParameters, "\(url)?a=a")
        testMakeRequest(.GET, url:"\(url)?a=a&b=b", emptyParameters, "\(url)?a=a&b=b")
    }
    
    func testMakeRequestURLWithQueryAndParams() {
        testMakeRequest(.GET, url:"\(url)?a=a", ["c":"c"], "\(url)?a=a&c=c")
        testMakeRequest(.GET, url:"\(url)?a=a&b=b", ["c":"c"], "\(url)?a=a&b=b&c=c")
    }
    
    func testMakePUTRequestWithBody() {
        testMakeRequestWithBody(.PUT, url:url, emptyParameters, url, "BodyContent".data(using: String.Encoding.utf8)!)
    }

    func testMakeRequest(_ method: OAuthSwiftHTTPRequest.Method, url: String,_ parameters: [String:String],_ expectedURL: String, _ expectedBodyJSONDictionary: [String:String]? = nil) {

        let request = client.makeRequest(url, method: method, parameters: parameters, headers: ["Content-Type": "application/json"])!

        XCTAssertEqual(request.URL, URL(string: url)!)
        XCTAssertEqual(request.HTTPMethod, method)
        XCTAssertEqualDictionaries(request.parameters as! [String:String], parameters)
        
        do {
            let urlRequest = try request.makeRequest()
            if let expectedJSON = expectedBodyJSONDictionary {
                let json = try! JSONSerialization.jsonObject(with: urlRequest.httpBody!, options: JSONSerialization.ReadingOptions()) as! [String:String]
                XCTAssertEqualDictionaries(json, expectedJSON)
            }
            XCTAssertEqualURL(urlRequest.url!, URL(string: expectedURL)!)
            
        } catch let e {
            XCTFail("\(e)")
        }
    }

    func testMakeRequestWithBody(_ method: OAuthSwiftHTTPRequest.Method, url: String, _ parameters: [String:String], _ expectedURL: String, _ expectedBody: Data) {
        let request = client.makeRequest(url, method: method, parameters: parameters, headers: ["Content-Type": "foobar"], body: expectedBody)!

        XCTAssertEqual(request.URL, URL(string: url)!)
        XCTAssertEqual(request.HTTPMethod, method)
        XCTAssertEqualDictionaries(request.parameters as! [String:String], parameters)
        XCTAssertEqual(request.HTTPBody, expectedBody)
    }

    func testMakeNSURLRequest(_ method: OAuthSwiftHTTPRequest.Method,_ urlString: String) {

        let url = URL(string: urlString)!
        let nsURLRequest = NSMutableURLRequest(url: url)
        nsURLRequest.httpMethod = method.rawValue

        let request = client.makeRequest(nsURLRequest as URLRequest)

        XCTAssertEqual(request.URL, url)
        XCTAssertEqual(request.HTTPMethod, method)
        XCTAssertEqualDictionaries(request.parameters as! [String:String], [:])

        do {
            let urlFromRequest = try request.makeRequest()
            XCTAssertEqualURL(urlFromRequest.url!, url)
        } catch let e {
            XCTFail("\(e)")
        }
    }
}

extension XCTestCase {
    
    func XCTAssertEqualURL(_ first: URL, _ second: URL, _ message: String = "") {
        
        let firstC = URLComponents(url: first, resolvingAgainstBaseURL: false)!
        let secondC = URLComponents(url: second, resolvingAgainstBaseURL: false)!
        
        XCTAssertEqual(firstC.host, secondC.host, "host:" + message)
        XCTAssertEqual(firstC.scheme, secondC.scheme, "scheme:" + message)
        XCTAssertEqual(firstC.path, secondC.path, "path:" + message)
        XCTAssertEqual(firstC.user, secondC.user, "user:" + message)
        XCTAssertEqual(firstC.password, secondC.password, "password:" + message)
        if let firstItems = firstC.queryItems {
            if let secondItems = secondC.queryItems {
                XCTAssertEqual(firstItems.sorted(by: { $0.name > $1.name }), secondItems.sorted(by: { $0.name > $1.name }),  "queryItems:" + message)
            } else {
                XCTFail("queryItems:" + message)
            }
        }
        else  if let _ = secondC.queryItems {
            XCTFail("queryItems:" + message)
        }
    }

    func XCTAssertEqualDictionaries<S, T: Equatable>(_ first: [S:T], _ second: [S:T], _ message: String = "") {
        XCTAssertTrue(first == second, message.isEmpty ? "\(first) != \(second)" : message)
    }

}
