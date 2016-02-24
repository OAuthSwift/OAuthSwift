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
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        
        guard let hash = OAuthSwiftCredential.SignatureMethod.HMAC_SHA1.sign(data) else {
            XCTFail("Failed to hash")
            return
        }
        let hashString = hash.base64EncodedStringWithOptions([])
        XCTAssertEqual(hashString, "Lve95gjOVATpfV8EL5X4nxwjKHE=")
    }
    
    func testHMAC_SHA1() {
        testHMAC_SHA1( "abcedfg123456789", "simon says", "vyeIZc3+tF6F3i95IEV+AJCWBYQ=")
        testHMAC_SHA1( "kd94hf93k423kf44&pfkkdhi9sl3r4s00", "GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg%26oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1191242096%26oauth_token%3Dnnch734d00sl2jdk%26oauth_version%3D1.0%26size%3Doriginal&kd94hf93k423kf44&pfkkdhi9sl3r4s00", "Gcg/323lvAsQ707p+y41y14qWfY=")
    }
    
    func testHMAC_SHA1(key: String,_ message: String,_ expected: String) {
        let messageData = message.dataUsingEncoding(NSUTF8StringEncoding)!
        let keyData = key.dataUsingEncoding(NSUTF8StringEncoding)!
        
        guard let hash = OAuthSwiftCredential.SignatureMethod.HMAC_SHA1.sign(keyData, message: messageData) else {
            XCTFail("Failed to hash")
            return
        }
        let hashString = hash.base64EncodedStringWithOptions([])
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
            expected: "bY1K6fPxYDwb34nUm8CIZjKtWWY=") // ?? g2HpPCyQIVxLC3NNVn2x9oeUtyg= 

    }

    func testSignature(  url : String
        , consumer : String
        , secret: String
        , token: String
        , token_secret : String
        , var parameters : [String:String]
        , nonce : String
        , timestamp : String
        , method:  OAuthSwiftHTTPRequest.Method = .GET
        , expected : String
        ) {
            let credential = OAuthSwiftCredential(consumer_key: consumer, consumer_secret: secret)
            credential.oauth_token = token
            credential.oauth_token_secret = token_secret

            parameters.merge(credential.authorizationParameters(nil, timestamp: timestamp, nonce: nonce))

            guard let nsurl = NSURL(string: url) else {
                XCTFail("Not able to create NSURL \(url)")
                return
            }
            print(nsurl.absoluteString)
            XCTAssertEqual(nsurl.absoluteString, url)

            let signature = credential.signatureForMethod(method, url: nsurl, parameters: parameters)

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
        
        let header = credential.authorizationHeaderForMethod(.GET, url: NSURL(string: url)!, parameters: parameters, timestamp: timestamp, nonce: nonce)

        XCTAssertEqual(header, "")// TODO add checked header
    }*/
    
    
    func testGenerateNonce()  {
        let tolerance = 100000
        var dico = [String: String]()
        for _ in 0...tolerance {
            let nonce = OAuthSwiftCredential.generateNonce()
            dico[nonce] = ""
        }
        
        XCTAssertEqual(tolerance, dico.count)
    }

}
