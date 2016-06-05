//
//  OAuthSwiftHTTPRequestConfig.swift
//  OAuthSwift
//
//  Created by Goessler, Florian on 07/04/16.
//  Copyright © 2016 Dongri Jin. All rights reserved.
//

import Foundation

public struct OAuthSwiftHTTPRequestConfig {
    public let request: NSURLRequest
    /// These parameters are either added to the query string for GET, HEAD and DELETE requests or
    /// used as the http body in case of POST, PUT or PATCH requests.
    ///
    /// If used in the body they are either encoded as JSON or as encoded plaintext based on the
    /// Content-Type header field.
    public let additionalParameters: [String: AnyObject]
    /// The location of the OAuth parameters (header, query, ...).
    public let paramsLocation: OAuthSwiftHTTPRequest.ParamsLocation
    public let dataEncoding: NSStringEncoding

    public init(request: NSURLRequest, additionalParameters: [String: AnyObject] = [:], paramsLocation : OAuthSwiftHTTPRequest.ParamsLocation = .AuthorizationHeader, dataEncoding: NSStringEncoding = OAuthSwiftDataEncoding) {
        self.request = request
        self.additionalParameters = additionalParameters
        self.paramsLocation = paramsLocation
        self.dataEncoding = dataEncoding
    }

    // MARK: Convenience Initializer

    public init(url: NSURL, method: OAuthSwiftHTTPRequest.Method = .GET, parameters: Dictionary<String, AnyObject> = [:], headers: [String:String] = [:], body: NSData? = nil, paramsLocation: OAuthSwiftHTTPRequest.ParamsLocation = .AuthorizationHeader) {
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.HTTPBody = body
        self.init(request: request, additionalParameters: parameters, paramsLocation: paramsLocation)
    }

    init(imageRequestWithURL url: NSURL, method: OAuthSwiftHTTPRequest.Method, parameters: Dictionary<String, AnyObject>, image: NSData, headers: [String:String] = [:], paramsLocation: OAuthSwiftHTTPRequest.ParamsLocation = .AuthorizationHeader) {
        var paramImage = [String: AnyObject]()
        paramImage["media"] = image
        let boundary = "AS-boundary-\(arc4random())-\(arc4random())"
        let type = "multipart/form-data; boundary=\(boundary)"
        let body = OAuthSwiftHTTPRequestConfig.multiPartBodyFromParams(paramImage, boundary: boundary)
        let adjustedHeaders = headers + ["Content-Type": type]

        self.init(url: url, method: method, parameters: parameters, headers: adjustedHeaders, body: body, paramsLocation: paramsLocation)
    }

    init(multipartRequestWithURL url: NSURL, method: OAuthSwiftHTTPRequest.Method, parameters: Dictionary<String, AnyObject>, multiparts: Array<OAuthSwiftMultipartData> = [], headers: [String:String] = [:], paramsLocation: OAuthSwiftHTTPRequest.ParamsLocation = .AuthorizationHeader) {
        let boundary = "POST-boundary-\(arc4random())-\(arc4random())"
        let type = "multipart/form-data; boundary=\(boundary)"
        let body = OAuthSwiftHTTPRequestConfig.multiDataFromObject(parameters, multiparts: multiparts, boundary: boundary)
        let adjustedHeaders = headers + ["Content-Type": type]

        self.init(url: url, method: method, parameters: parameters, headers: adjustedHeaders, body: body, paramsLocation: paramsLocation)
    }

    // MARK: Multipart Body Creation

    private static let separator: String = "\r\n"
    private static var separatorData: NSData = {
        return OAuthSwiftHTTPRequestConfig.separator.dataUsingEncoding(OAuthSwiftDataEncoding)!
    }()

    private static func multiPartBodyFromParams(parameters: [String: AnyObject], boundary: String) -> NSData {
        let data = NSMutableData()

        let prefixString = "--\(boundary)\r\n"
        let prefixData = prefixString.dataUsingEncoding(OAuthSwiftDataEncoding)!


        for (key, value) in parameters {
            var sectionData: NSData
            var sectionType: String?
            var sectionFilename: String?
            if  let multiData = value as? NSData where key == "media" {
                sectionData = multiData
                sectionType = "image/jpeg"
                sectionFilename = "file"
            } else {
                sectionData = "\(value)".dataUsingEncoding(OAuthSwiftDataEncoding)!
            }

            data.appendData(prefixData)
            let multipartData = OAuthSwiftMultipartData(name: key, data: sectionData, fileName: sectionFilename, mimeType: sectionType)
            data.appendMultipartData(multipartData, encoding: OAuthSwiftDataEncoding, separatorData: OAuthSwiftHTTPRequestConfig.separatorData)
        }

        let endingString = "--\(boundary)--\r\n"
        let endingData = endingString.dataUsingEncoding(OAuthSwiftDataEncoding)!
        data.appendData(endingData)
        return data
    }

    private static func multiDataFromObject(object: [String:AnyObject], multiparts: Array<OAuthSwiftMultipartData>, boundary: String) -> NSData? {
        let data = NSMutableData()

        let prefixString = "--\(boundary)\r\n"
        let prefixData = prefixString.dataUsingEncoding(OAuthSwiftDataEncoding)!

        for (key, value) in object {
            guard let valueData = "\(value)".dataUsingEncoding(OAuthSwiftDataEncoding) else {
                continue
            }
            data.appendData(prefixData)
            let multipartData = OAuthSwiftMultipartData(name: key, data: valueData, fileName: nil, mimeType: nil)
            data.appendMultipartData(multipartData, encoding: OAuthSwiftDataEncoding, separatorData: OAuthSwiftHTTPRequestConfig.separatorData)
        }

        for multipart in multiparts {
            data.appendData(prefixData)
            data.appendMultipartData(multipart, encoding: OAuthSwiftDataEncoding, separatorData: OAuthSwiftHTTPRequestConfig.separatorData)
        }

        let endingString = "--\(boundary)--\r\n"
        let endingData = endingString.dataUsingEncoding(OAuthSwiftDataEncoding)!
        data.appendData(endingData)
        
        return data
    }
}
