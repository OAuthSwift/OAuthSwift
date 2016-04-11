//
//  OAuthSwiftHTTPRequestConfigTest.swift
//  OAuthSwift
//
//  Created by Goessler, Florian on 08/04/16.
//  Copyright © 2016 Dongri Jin. All rights reserved.
//

import Foundation
@testable import OAuthSwift
import XCTest

class OAuthSwiftHTTPRequestConfigTest: XCTestCase {

    func testCreateRequestConfigFromNSURLRequest() {
        let req = NSMutableURLRequest(URL: NSURL(string: "example.com/test")!)
        req.HTTPBody = "abcdef".dataUsingEncoding(OAuthSwiftDataEncoding)
        let reqConfig = OAuthSwiftHTTPRequestConfig(
            request: req,
            additionalParameters: [:],
            paramsLocation: .AuthorizationHeader,
            dataEncoding: OAuthSwiftDataEncoding
        )

        assertRequestConfig(
            reqConfig,
            urlString: "example.com/test",
            method: .GET,
            additionalParameters: [:],
            headers: [:],
            body: "abcdef".dataUsingEncoding(OAuthSwiftDataEncoding),
            paramsLocation: .AuthorizationHeader,
            dataEncoding: OAuthSwiftDataEncoding
        )
    }

    func testCreateRequestConfigFromURLAndCo() {
        let reqConfig = OAuthSwiftHTTPRequestConfig(
            url: NSURL(string: "example.com/test")!,
            method: .PUT,
            parameters: ["Fancy Stuff": "With a value!"],
            headers: ["A header": "Its value"],
            body: "qwerty".dataUsingEncoding(OAuthSwiftDataEncoding),
            paramsLocation: .RequestURIQuery
        )

        assertRequestConfig(
            reqConfig,
            urlString: "example.com/test",
            method: .PUT,
            additionalParameters: ["Fancy Stuff": "With a value!"],
            headers: ["A header": "Its value"],
            body: "qwerty".dataUsingEncoding(OAuthSwiftDataEncoding),
            paramsLocation: .RequestURIQuery,
            dataEncoding: OAuthSwiftDataEncoding
        )
    }

    func testCreateRequestConfigFromURLWithDefaults() {
        let reqConfig = OAuthSwiftHTTPRequestConfig(url: NSURL(string: "example.com/test")!)

        assertRequestConfig(
            reqConfig,
            urlString: "example.com/test",
            method: .GET,
            additionalParameters: [:],
            headers: [:],
            body: nil,
            paramsLocation: .AuthorizationHeader,
            dataEncoding: OAuthSwiftDataEncoding
        )
    }

    func testCreateRequestConfigForPostImageRequest() {
        // create test image
        let size = NSSize(width: 10, height: 10)
        let img = NSImage(size: size)
        img.lockFocus()
        NSColor.blueColor().drawSwatchInRect(NSMakeRect(0, 0, size.width, size.height))
        img.unlockFocus()
        let imgData = NSBitmapImageRep(data: img.TIFFRepresentation!)!.representationUsingType(.NSPNGFileType, properties: [:])!
        // prepare request
        let reqConfig = OAuthSwiftHTTPRequestConfig(
            imageRequestWithURL: NSURL(string: "example.com/test")!,
            method: .POST,
            parameters: ["Fancy Stuff": "With a value!"],
            image: imgData,
            headers: ["A header": "Its value"],
            paramsLocation: .RequestURIQuery
        )

        // assert
        assertRequestConfig(
            reqConfig,
            urlString: "example.com/test",
            method: .POST,
            additionalParameters: ["Fancy Stuff": "With a value!"],
            paramsLocation: .RequestURIQuery,
            dataEncoding: OAuthSwiftDataEncoding
        )
        // assert headers
        let headers = reqConfig.request.allHTTPHeaderFields!
        let contentType = headers["Content-Type"]!
        XCTAssertEqual(headers.count, 2)
        XCTAssertEqual(headers["A header"], "Its value")
        XCTAssertTrue(contentType.containsString("multipart/form-data; boundary=AS-boundary-"))
        // assert body
        let boundarySeparator = contentType.stringByReplacingOccurrencesOfString("multipart/form-data; boundary=", withString: "")
        guard let bodyParts = reqConfig.request.HTTPBody?.splitHTTPBodyDataInMuliparts(boundarySeparator)
            else { XCTFail("Couldn't split HTTP body data"); return }
        XCTAssertEqual(bodyParts[0].metaData, "Content-Disposition: form-data; name=\"media\"; filename=\"file\"\r\nContent-Type: image/jpeg")
        XCTAssertEqual(bodyParts[0].contentData, imgData)
    }

    func testCreateRequestConfigForMultipartRequest() {
        // prepare request
        let part1 = OAuthSwiftMultipartData(name: "First part", data: "TestTEST".dataUsingEncoding(OAuthSwiftDataEncoding)!, fileName: "sometext", mimeType: "text/plain")
        let part2 = OAuthSwiftMultipartData(name: "Second part", data: "Test 2".dataUsingEncoding(OAuthSwiftDataEncoding)!, fileName: nil, mimeType: nil)
        let reqConfig = OAuthSwiftHTTPRequestConfig(
            multipartRequestWithURL: NSURL(string: "example.com/test")!,
            method: .POST,
            parameters: ["A parameter": "With the parameter value!"],
            multiparts: [part1, part2],
            headers: ["A header": "Its value"],
            paramsLocation: .RequestURIQuery
        )

        // assert
        assertRequestConfig(
            reqConfig,
            urlString: "example.com/test",
            method: .POST,
            additionalParameters: ["A parameter": "With the parameter value!"],
            paramsLocation: .RequestURIQuery,
            dataEncoding: OAuthSwiftDataEncoding
        )
        // assert headers
        let headers = reqConfig.request.allHTTPHeaderFields!
        let contentType = headers["Content-Type"]!
        XCTAssertEqual(headers.count, 2)
        XCTAssertEqual(headers["A header"], "Its value")
        XCTAssertTrue(contentType.containsString("multipart/form-data; boundary=POST-boundary-"))
        // assert body
        let boundarySeparator = contentType.stringByReplacingOccurrencesOfString("multipart/form-data; boundary=", withString: "")
        guard let bodyParts = reqConfig.request.HTTPBody?.splitHTTPBodyDataInMuliparts(boundarySeparator)
            else { XCTFail("Couldn't split HTTP body data"); return }
        XCTAssertEqual(bodyParts[0].metaData, "Content-Disposition: form-data; name=\"A parameter\";")
        XCTAssertEqual(bodyParts[1].metaData, "Content-Disposition: form-data; name=\"First part\"; filename=\"sometext\"\r\nContent-Type: text/plain")
        XCTAssertEqual(bodyParts[2].metaData, "Content-Disposition: form-data; name=\"Second part\";")
        XCTAssertEqual(String(data:bodyParts[0].contentData, encoding:OAuthSwiftDataEncoding)!, "With the parameter value!")
        XCTAssertEqual(String(data:bodyParts[1].contentData, encoding:OAuthSwiftDataEncoding)!, "TestTEST")
        XCTAssertEqual(String(data:bodyParts[2].contentData, encoding:OAuthSwiftDataEncoding)!, "Test 2")
    }


    private func assertRequestConfig(reqConfig: OAuthSwiftHTTPRequestConfig, urlString: String, method: OAuthSwiftHTTPRequest.Method, additionalParameters: [String: AnyObject], headers: [String:String], body: NSData?, paramsLocation: OAuthSwiftHTTPRequest.ParamsLocation, dataEncoding: NSStringEncoding) {
        XCTAssertEqual(reqConfig.request.URL!.absoluteString, urlString)
        XCTAssertEqual(reqConfig.request.HTTPMethod, method.rawValue)
        XCTAssertEqualDictionaries(reqConfig.request.allHTTPHeaderFields ?? [:], headers)
        XCTAssertEqual(reqConfig.request.HTTPBody, body)
        XCTAssertEqual(reqConfig.paramsLocation, paramsLocation)
        XCTAssertEqual(reqConfig.dataEncoding, dataEncoding)
    }

    private func assertRequestConfig(reqConfig: OAuthSwiftHTTPRequestConfig, urlString: String, method: OAuthSwiftHTTPRequest.Method, additionalParameters: [String: AnyObject], paramsLocation: OAuthSwiftHTTPRequest.ParamsLocation, dataEncoding: NSStringEncoding) {
        XCTAssertEqual(reqConfig.request.URL!.absoluteString, urlString)
        XCTAssertEqual(reqConfig.request.HTTPMethod, method.rawValue)
        XCTAssertEqual(reqConfig.paramsLocation, paramsLocation)
        XCTAssertEqual(reqConfig.dataEncoding, dataEncoding)
    }
}

extension NSData {

    private func splitHTTPBodyDataInMuliparts(boundary: String) -> [(metaData:String, contentData:NSData)] {
        let boundaryData = "--\(boundary)\r\n".dataUsingEncoding(OAuthSwiftDataEncoding)!
        let finalBoundaryData = "--\(boundary)--\r\n".dataUsingEncoding(OAuthSwiftDataEncoding)!

        var data = self
        var parts = [(metaData:String, contentData:NSData)]()
        while data.length > 0 {
            // find next boundary
            var boundaryRange = data.rangeOfData(boundaryData, options: NSDataSearchOptions(), range: NSMakeRange(0, data.length))
            if boundaryRange.location == NSNotFound {
                boundaryRange = data.rangeOfData(finalBoundaryData, options: NSDataSearchOptions(), range: NSMakeRange(0, data.length))
            }
            // analyze data until next boundary
            if boundaryRange.location != 0 {
                let metaDataSeparator = "\r\n\r\n".dataUsingEncoding(OAuthSwiftDataEncoding)!
                let metaDataSeparatorRange = data.rangeOfData(metaDataSeparator, options: NSDataSearchOptions(), range: NSMakeRange(0, data.length))
                // split into meta data (String) and actual content data (NSData)
                let metaData = data.subdataWithRange(NSMakeRange(0, metaDataSeparatorRange.location))
                let contentData = data.subdataWithRange(NSMakeRange(
                    metaDataSeparatorRange.location + metaDataSeparatorRange.length,
                    boundaryRange.location - metaDataSeparatorRange.location - metaDataSeparatorRange.length - "\r\n".dataUsingEncoding(OAuthSwiftDataEncoding)!.length)
                )
                parts.append((String(data: metaData, encoding: OAuthSwiftDataEncoding)!, contentData))
            }
            data = data.subdataWithRange(NSMakeRange(
                boundaryRange.location + boundaryRange.length,
                data.length - boundaryRange.location - boundaryRange.length)
            )
        }

        return parts
    }
}

