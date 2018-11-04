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

    func testSHA1() {
        let string = "Hello World!"
        let data = string.data(using: String.Encoding.utf8)!
        
        guard let hash = OAuthSwiftHashMethod.sha1.hash(data: data) else {
            XCTFail("Failed to hash")
            return
        }
        let hashString = hash.base64EncodedString()
        XCTAssertEqual(hashString, "Lve95gjOVATpfV8EL5X4nxwjKHE=")
    }
    
    func testHMAC_SHA1() {
        testHMAC_SHA1( "abcedfg123456789", "simon says", "vyeIZc3+tF6F3i95IEV+AJCWBYQ=")
        testHMAC_SHA1( "kd94hf93k423kf44&pfkkdhi9sl3r4s00", "GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg%26oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1191242096%26oauth_token%3Dnnch734d00sl2jdk%26oauth_version%3D1.0%26size%3Doriginal&kd94hf93k423kf44&pfkkdhi9sl3r4s00", "Gcg/323lvAsQ707p+y41y14qWfY=")
    }
    
    func testHMAC_SHA1(_ key: String,_ message: String,_ expected: String) {
        let messageData = message.data(using: String.Encoding.utf8)!
        let keyData = key.data(using: String.Encoding.utf8)!
        
        guard let hash = OAuthSwiftCredential.SignatureMethod.HMAC_SHA1.sign(key: keyData, message: messageData) else {
            XCTFail("Failed to hash")
            return
        }
        let hashString = hash.base64EncodedString()
        XCTAssertEqual(hashString, expected)
    }
    
    func testSignature() {
        testSignature("http://photos.example.net/photos",
            consumer: "dpf43f3p2l4k3l03",
            secret: "kd94hf93k423kf44",
            token: "nnch734d00sl2jdk",
            token_secret: "pfkkdhi9sl3r4s00",
            parameters: ["file":"vacation.jpg", "size":"original"],
            nonce: "kllo9940pd9333jh",
            timestamp: "1191242096",
            method: .GET,
            expected: "tR3+Ty81lMeYAr/Fid0kMTYa/WM=")

        testSignature("http://photos.example.net/photos",
            consumer: "abcd",
            secret: "efgh",
            token: "ijkl",
            token_secret: "mnop",
            parameters: ["name":"value"],
            nonce: "rkNG5bfzqFw",
            timestamp: "1451152366",
            method: .POST,
            expected: "6qB7WBgezEpKhfr2Bpl+HfcS4SA=")
    }

    func testSignatureWithSpaceInURL() {
        testSignature("http://photos.example.net/ph%20otos",
                      consumer: "abcd",
                      secret: "efgh",
                      token: "ijkl",
                      token_secret: "mnop",
                      parameters: ["name":"value"],
                      nonce: "rkNG5bfzqFw",
                      timestamp: "1451152366",
                      method: .GET,
                      // TODO: see https://github.com/OAuthSwift/OAuthSwift/issues/115 maybe bY1K6fPxYDwb34nUm8CIZjKtWWY= is the correct signature?
            expected: "g2HpPCyQIVxLC3NNVn2x9oeUtyg=")
        
    }
    
    func testSignatureWithSamePrefix() {
        testSignature("http://photos.example.net/photos",
                      consumer: "dpf43f3p2l4k3l03",
                      secret: "kd94hf93k423kf44",
                      token: "nnch734d00sl2jdk",
                      token_secret: "pfkkdhi9sl3r4s00",
                      parameters: ["file_1":"vacation.jpg", "file_10":"original"],
                      nonce: "kllo9940pd9333jh",
                      timestamp: "1191242096",
                      method: .GET,
                      expected: "2qG5S5iX/g/6NIKutdcSYACUHsg=")
    }
    
    func testSignature(_ urlString : String
        , consumer : String
        , secret: String
        , token: String
        , token_secret : String
        , parameters : [String:String]
        , nonce : String
        , timestamp : String
        , method:  OAuthSwiftHTTPRequest.Method = .GET
        , expected : String
        ) {
        var parameters = parameters
        let credential = OAuthSwiftCredential(consumerKey: consumer, consumerSecret: secret)
        credential.oauthToken = token
        credential.oauthTokenSecret = token_secret
        
        parameters.merge(credential.authorizationParameters(nil, timestamp: timestamp, nonce: nonce))
        
        guard let url = URL(string: urlString) else {
            XCTFail("Not able to create URL \(urlString)")
            return
        }
        print(url.absoluteString)
        XCTAssertEqual(url.absoluteString, urlString)
        
        let signature = credential.signature(method: method, url: url, parameters: parameters)
        
        XCTAssertEqual(signature, expected,  "HMAC-SHA1 request signature does not match OAuth Spec, Appendix A.5.3")
    }

    /*func testAuthorizationHeader() {
        let url = "http://photos.example.net/photos"
        let consumer = "dpf43f3p2l4k3l03"
        let secret = "kd94hf93k423kf44"
        let token = "nnch734d00sl2jdk"
        let token_secret = "pfkkdhi9sl3r4s00"
        let parameters = ["file":"vacation.jpg", "size":"original"]
        let nonce = "kllo9940pd9333jh"
        let timestamp = "1191242096"
        
        let credential = OAuthSwiftCredential(consumer_key: consumer, consumer_secret: secret)
        credential.oauth_token = token
        credential.oauth_token_secret = token_secret
        
        let header = credential.authorizationHeader(method: .GET, url: URL(string: url)!, parameters: parameters, timestamp: timestamp, nonce: nonce)

        XCTAssertEqual(header, "")// TODO add checked header
    }*/
    

    // This test just verifies that the nonce is pretty random, although uniqueness is not guaranteed.
    // Therefore XCTAssertEqualWithAccuracy is used.
    func testGenerateNonce()  {
        let tolerance = 100000
        var dico = [String: String]()
        for _ in 0..<tolerance {
            let nonce = OAuthSwiftCredential.generateNonce()
            dico[nonce] = ""
            XCTAssertEqual(nonce.count, 8)
        }

        XCTAssertEqual(Double(tolerance), Double(dico.count), accuracy: 10)
    }

}
