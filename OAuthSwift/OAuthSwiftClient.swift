//
//  OAuthSwiftClient.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

var OAuthSwiftDataEncoding: NSStringEncoding = NSUTF8StringEncoding

public protocol OAuthSwiftRequestHandle {
    func cancel()
}

public class OAuthSwiftClient: NSObject {

    private(set) public var credential: OAuthSwiftCredential
    public var paramsLocation: OAuthSwiftHTTPRequest.ParamsLocation = .AuthorizationHeader

    static let separator: String = "\r\n"
    static var separatorData: NSData = {
        return OAuthSwiftClient.separator.dataUsingEncoding(OAuthSwiftDataEncoding)!
    }()

    // MARK: init
    public init(consumerKey: String, consumerSecret: String) {
        self.credential = OAuthSwiftCredential(consumer_key: consumerKey, consumer_secret: consumerSecret)
    }
    
    public init(consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String) {
        self.credential = OAuthSwiftCredential(oauth_token: accessToken, oauth_token_secret: accessTokenSecret)
        self.credential.consumer_key = consumerKey
        self.credential.consumer_secret = consumerSecret
    }
    
    public init(credential: OAuthSwiftCredential) {
        self.credential = credential
    }

    // MARK: client methods
    public func get(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .GET, parameters: parameters, headers: headers, success: success, failure: failure)
    }
    
    public func post(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .POST, parameters: parameters, headers: headers, success: success, failure: failure)
    }

    public func put(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, body: NSData? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .PUT, parameters: parameters, headers: headers, body: body, success: success, failure: failure)
    }

    public func delete(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .DELETE, parameters: parameters, headers: headers,success: success, failure: failure)
    }

    public func patch(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .PATCH, parameters: parameters, headers: headers,success: success, failure: failure)
    }
    
    public func request(urlString: String, method: OAuthSwiftHTTPRequest.Method, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, body: NSData? = nil, checkTokenExpiration: Bool = true, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        
        if checkTokenExpiration && self.credential.isTokenExpired()  {
            let errorInfo = [NSLocalizedDescriptionKey: NSLocalizedString("The provided token is expired.", comment:"Token expired, retrieve new token by using the refresh token")]
            
            if let failureHandler = failure {
                failureHandler(error: NSError(domain: OAuthSwiftErrorDomain, code: OAuthSwiftErrorCode.TokenExpiredError.rawValue, userInfo: errorInfo))
            }
            
            return nil
        }

        guard let _ = NSURL(string: urlString) else {
            failure?(error: NSError(domain: OAuthSwiftErrorDomain, code: OAuthSwiftErrorCode.RequestCreationError.rawValue, userInfo: nil))
            return nil
        }

        if let request = makeRequest(urlString, method: method, parameters: parameters, headers: headers, body: body) {
            request.successHandler = success
            request.failureHandler = failure
            request.start()
            return request
        }
        return nil
    }
    
    public func makeRequest(request: NSURLRequest) -> OAuthSwiftHTTPRequest {
        let request = OAuthSwiftHTTPRequest(request: request, paramsLocation: self.paramsLocation)
        request.makeOAuthSwiftHTTPRequest(self.credential)
        return request
    }

    public func makeRequest(urlString: String, method: OAuthSwiftHTTPRequest.Method, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, body: NSData? = nil) -> OAuthSwiftHTTPRequest? {
        guard let url = NSURL(string: urlString) else {
            return nil
        }

        let request = OAuthSwiftHTTPRequest(URL: url, method: method, parameters: parameters, paramsLocation: self.paramsLocation, HTTPBody: body, headers: headers ?? [:])
        request.makeOAuthSwiftHTTPRequest(self.credential)
        return request
    }

    @available(*, deprecated=0.6.0, message="This method will be removed to make OAuthSwiftHTTPRequest.Config not mutable")
    public func makeOAuthSwiftHTTPRequest(request: OAuthSwiftHTTPRequest) -> OAuthSwiftHTTPRequest {
        request.makeOAuthSwiftHTTPRequest(self.credential)
        return request
    }

    public func postImage(urlString: String, parameters: [String:AnyObject], image: NSData, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?)  -> OAuthSwiftRequestHandle? {
        return self.multiPartRequest(urlString, method: .POST, parameters: parameters, image: image, success: success, failure: failure)
    }

    func multiPartRequest(url: String, method: OAuthSwiftHTTPRequest.Method, parameters: [String:AnyObject], image: NSData, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?)  -> OAuthSwiftRequestHandle? {
        
        let paramImage: [String: AnyObject] = ["media": image]
        let boundary = "AS-boundary-\(arc4random())-\(arc4random())"
        let type = "multipart/form-data; boundary=\(boundary)"
        let body = self.multiPartBodyFromParams(paramImage, boundary: boundary)
        let headers = [kHTTPHeaderContentType: type]

        if let request = makeRequest(url, method: method, parameters: parameters, headers: headers, body: body) { // TODO check if headers do not override others...

            request.successHandler = success
            request.failureHandler = failure
            request.start()
            return request
        }
        return nil
    }

    public func multiPartBodyFromParams(parameters: [String: AnyObject], boundary: String) -> NSData {
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
            data.appendMultipartData(multipartData, encoding: OAuthSwiftDataEncoding, separatorData: OAuthSwiftClient.separatorData)
        }

        let endingString = "--\(boundary)--\r\n"
        let endingData = endingString.dataUsingEncoding(OAuthSwiftDataEncoding)!
        data.appendData(endingData)
        return data
    }
    
    public func postMultiPartRequest(url: String, method: OAuthSwiftHTTPRequest.Method, parameters: [String:AnyObject], headers: [String: String]? = nil, multiparts: Array<OAuthSwiftMultipartData> = [], checkTokenExpiration: Bool = true, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        
        let boundary = "POST-boundary-\(arc4random())-\(arc4random())"
        let type = "multipart/form-data; boundary=\(boundary)"
        let body = self.multiDataFromObject(parameters, multiparts: multiparts, boundary: boundary)
        
        var finalHeaders = [kHTTPHeaderContentType: type]
        finalHeaders += headers ?? [:]
        
        if let request = makeRequest(url, method: method, parameters: parameters, headers: finalHeaders, body: body) { // TODO check if headers do not override 
            request.successHandler = success
            request.failureHandler = failure
            request.start()
        }
    }

    func multiDataFromObject(object: [String:AnyObject], multiparts: Array<OAuthSwiftMultipartData>, boundary: String) -> NSData? {
        let data = NSMutableData()

        let prefixString = "--\(boundary)\r\n"
        let prefixData = prefixString.dataUsingEncoding(OAuthSwiftDataEncoding)!

        for (key, value) in object {
            guard let valueData = "\(value)".dataUsingEncoding(OAuthSwiftDataEncoding) else {
                continue
            }
            data.appendData(prefixData)
            let multipartData = OAuthSwiftMultipartData(name: key, data: valueData, fileName: nil, mimeType: nil)
            data.appendMultipartData(multipartData, encoding: OAuthSwiftDataEncoding, separatorData: OAuthSwiftClient.separatorData)
        }

        for multipart in multiparts {
            data.appendData(prefixData)
            data.appendMultipartData(multipart, encoding: OAuthSwiftDataEncoding, separatorData: OAuthSwiftClient.separatorData)
        }

        let endingString = "--\(boundary)--\r\n"
        let endingData = endingString.dataUsingEncoding(OAuthSwiftDataEncoding)!
        data.appendData(endingData)

        return data
    }

}
