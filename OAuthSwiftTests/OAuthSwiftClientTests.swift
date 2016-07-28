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
        
        //client.credential.version = .OAuth2
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

    func testMakePOSTRequest_EmptyParameter() {
        testMakeRequest(.POST, url:url, emptyParameters, url, nil)
    }
    
    func testMakePOSTRequestOneParameter() {
        testMakeRequest(.POST, url:url, ["a":"a"], url, ["a":"a"])
    }

    func testMakePOSTRequestTwoParameters() {
        testMakeRequest(.POST, url:url, ["a":"a", "b":"b"], url, ["a":"a", "b":"b"])
    }

    func testMakePOSTRequestParameterInURL() {
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
        testMakeRequestWithBody(.PUT, url:url, emptyParameters, url, "BodyContent".dataUsingEncoding(NSUTF8StringEncoding)!)
    }

    func testMakeRequest(method: OAuthSwiftHTTPRequest.Method, url: String,_ parameters: [String:String],_ expectedURL: String, _ expectedBodyJSONDictionary: [String:String]? = nil) {

        let request = client.makeRequest(url, method: method, parameters: parameters, headers: ["Content-Type": "application/json"])!

        XCTAssertEqual(request.config.URL, NSURL(string: url))
        XCTAssertEqual(request.config.HTTPMethod, method)
        XCTAssertEqualDictionaries(request.config.parameters as! [String:String], parameters)
        
        do {
            let urlRequest = try request.makeRequest()
            if let expectedJSON = expectedBodyJSONDictionary {
                if let body = urlRequest.HTTPBody {
                    if let json = try? NSJSONSerialization.JSONObjectWithData(body, options: NSJSONReadingOptions()) as? [String:String] {
                        XCTAssertEqualDictionaries(json!, expectedJSON)
                    } else {
                        if let string = String(data: body, encoding: request.config.dataEncoding) {
                            XCTFail("Not json but string \(string)")
                        } else {
                            XCTFail("Not decodable")
                        }
                    }
                } else {
                    XCTFail("No body")
                }
            }
            XCTAssertEqualURL(urlRequest.URL!, NSURL(string: expectedURL)!)
            
        } catch let e {
            XCTFail("\(e)")
        }
    }

    func testMakeRequestWithBody(method: OAuthSwiftHTTPRequest.Method, url: String, _ parameters: [String:String], _ expectedURL: String, _ expectedBody: NSData) {
        let request = client.makeRequest(url, method: method, parameters: parameters, headers: ["Content-Type": "foobar"], body: expectedBody)!

        XCTAssertEqual(request.config.URL, NSURL(string: url))
        XCTAssertEqual(request.config.HTTPMethod, method)
        XCTAssertEqualDictionaries(request.config.parameters as! [String:String], parameters)
        XCTAssertEqual(request.config.urlRequest.HTTPBody, expectedBody)
    }

    func testMakeNSURLRequest(method: OAuthSwiftHTTPRequest.Method,_ urlString: String) {

        let url = NSURL(string: urlString)!
        let nsURLRequest = NSMutableURLRequest(URL: url)
        nsURLRequest.HTTPMethod = method.rawValue

        let request = client.makeRequest(nsURLRequest)

        XCTAssertEqual(request.config.URL!, url)
        XCTAssertEqual(request.config.HTTPMethod, method)
        XCTAssertEqualDictionaries(request.config.parameters as! [String:String], [:])

        do {
            let urlFromRequest = try request.makeRequest()
            XCTAssertEqualURL(urlFromRequest.URL!, url)
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
