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
    let emptyParameters = OAuthSwift.Parameters()

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
        testMakeRequestWithBody(.PUT, url:url, emptyParameters, url, "BodyContent".data(using: .utf8)!)
    }

    func testMakeRequest(_ method: OAuthSwiftHTTPRequest.Method, url: String,_ parameters: OAuthSwift.Parameters,_ expectedURL: String, _ expectedBodyJSONDictionary: [String:String]? = nil) {

        let request = client.makeRequest(url, method: method, parameters: parameters, headers: ["Content-Type": "application/json"])!

        XCTAssertEqual(request.config.url, URL(string: url)!)
        XCTAssertEqual(request.config.httpMethod, method)
        XCTAssertEqualDictionaries(request.config.parameters as! [String:String], parameters as! [String:String])
        
        do {
            let urlRequest = try request.makeRequest()
            if let expectedJSON = expectedBodyJSONDictionary {
                if let body = urlRequest.httpBody {
                    if let json = ((try? JSONSerialization.jsonObject(with: body, options: []) as? [String:String]) as [String : String]??) {
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
            XCTAssertEqualURL(urlRequest.url!, URL(string: expectedURL)!)
            
        } catch let e {
            XCTFail("\(e)")
        }
    }

    func testMakeRequestWithBody(_ method: OAuthSwiftHTTPRequest.Method, url: String, _ parameters: OAuthSwift.Parameters, _ expectedURL: String, _ expectedBody: Data) {
        let request = client.makeRequest(url, method: method, parameters: parameters, headers: ["Content-Type": "foobar"], body: expectedBody)!

        XCTAssertEqual(request.config.url, URL(string: url)!)
        XCTAssertEqual(request.config.httpMethod, method)
        XCTAssertEqualDictionaries(request.config.parameters as! [String:String], parameters as! [String:String])
        XCTAssertEqual(request.config.urlRequest.httpBody, expectedBody)
    }

    func testMakeNSURLRequest(_ method: OAuthSwiftHTTPRequest.Method,_ urlString: String) {

        let url = URL(string: urlString)!
        var nsURLRequest = URLRequest(url: url)
        nsURLRequest.httpMethod = method.rawValue

        let request = client.makeRequest(nsURLRequest)

        XCTAssertEqual(request.config.url!, url)
        XCTAssertEqual(request.config.httpMethod, method)
        XCTAssertEqualDictionaries(request.config.parameters as! [String:String], [:])

        do {
            let urlFromRequest = try request.makeRequest()
            XCTAssertEqualURL(urlFromRequest.url!, url)
        } catch let e {
            XCTFail("\(e)")
        }
    }

    func testMultiPartBodyFromParams() {
        let binary = "binary".data(using: OAuthSwiftDataEncoding)!
        let parameters: OAuthSwift.Parameters = [ "media": binary, "a": "b" ]
        let data = client.multiPartBody(from: parameters, boundary: "boundary")
        let result = String(data: data, encoding: OAuthSwiftDataEncoding)!

        let expectedString = "--boundary\r\nContent-Disposition: form-data; name=\"a\"\r\n\r\nb\r\n--boundary\r\nContent-Disposition: form-data; name=\"media\"; filename=\"file\"\r\nContent-Type: image/jpeg\r\n\r\nbinary\r\n--boundary--\r\n"
        XCTAssertEqual(result, expectedString)
    }

    func testMakeMultipartRequest() {
        let binary = "binary".data(using: OAuthSwiftDataEncoding)!
        let multiparts = [ OAuthSwiftMultipartData(name: "media", data: binary, fileName: "file", mimeType: "image/jpeg") ]
        let request = client.makeMultiPartRequest(url, method: .POST, multiparts: multiparts)!

        XCTAssertEqualURL(request.config.url!, URL(string: url)!)

        let bodyString = String(data: request.config.urlRequest.httpBody!, encoding: OAuthSwiftDataEncoding)
        XCTAssertTrue(bodyString?.contains("image/jpeg\r\n\r\nbinary\r\n") == true)
    }

    func testMakeMultipartRequestWithParameter() {
        let binary = "binary".data(using: OAuthSwiftDataEncoding)!
        let multiparts = [ OAuthSwiftMultipartData(name: "media", data: binary, fileName: "file", mimeType: "image/jpeg") ]
        let parameters: OAuthSwift.Parameters = [ "a": "b" ]
        let request = client.makeMultiPartRequest(url, method: .POST, parameters: parameters, multiparts: multiparts)!

        XCTAssertEqualURL(request.config.url!, URL(string: url)!)

        let bodyString = String(data: request.config.urlRequest.httpBody!, encoding: OAuthSwiftDataEncoding)
        XCTAssertTrue(bodyString?.contains("image/jpeg\r\n\r\nbinary\r\n") == true)
        XCTAssertTrue(bodyString?.contains("form-data; name=\"a\"\r\n\r\nb") == true)
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
