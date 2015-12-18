//
//  OAuthSwiftClient.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

var OAuthSwiftDataEncoding: NSStringEncoding = NSUTF8StringEncoding

public class OAuthSwiftClient {

    private(set) public var credential: OAuthSwiftCredential

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

    // MARK: client methods
    public func get(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: .GET, parameters: parameters, headers: headers, success: success, failure: failure)
    }
    
    public func post(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: .POST, parameters: parameters, headers: headers, success: success, failure: failure)
    }

    public func put(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: .PUT, parameters: parameters, headers: headers,success: success, failure: failure)
    }

    public func delete(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: .DELETE, parameters: parameters, headers: headers,success: success, failure: failure)
    }

    public func patch(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: .PATCH, parameters: parameters, headers: headers,success: success, failure: failure)
    }

    public func request(url: String, method: OAuthSwiftHTTPRequest.Method, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        if let request = makeRequest(url, method: method, parameters: parameters, headers: headers) {
            
            request.successHandler = success
            request.failureHandler = failure
            request.start()
        }
    }

    public func makeRequest(urlString: String, method: OAuthSwiftHTTPRequest.Method, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil) -> OAuthSwiftHTTPRequest? {
        if let url = NSURL(string: urlString) {

            let request = OAuthSwiftHTTPRequest(URL: url, method: method, parameters: parameters)
            
            var requestHeaders = [String:String]()
            var signatureUrl = url
            var signatureParameters = parameters
    
            // Check if body must be hashed (oauth1)
            let body: NSData? = nil
            if method.isBody {
                if let addHeaders = headers, contentType = addHeaders["Content-Type"]?.lowercaseString {
                    
                    if contentType.rangeOfString("application/json") != nil {
                        // TODO: oauth_body_hash create body before signing if implementing body hashing
                        /*do {
                        let jsonData: NSData = try NSJSONSerialization.dataWithJSONObject(parameters, options: [])
                        request.HTTPBody = jsonData
                        requestHeaders["Content-Length"] = "\(jsonData.length)"
                        body = jsonData
                        }
                        catch {
                        }*/
                        
                        signatureParameters = [:] // parameters are not used for general signature (could only be used for body hashing
                    }
                    // else other type are not supported, see setupRequestForOAuth()
                }
            }

            // Need to account for the fact that some consumers will have additional parameters on the
            // querystring, including in the case of fetching a request token. Especially in the case of
            // additional parameters on the request, authorize, or access token exchanges, we need to
            // normalize the URL and add to the parametes collection.
            
            var queryStringParameters = Dictionary<String, AnyObject>()
            let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: false )
            if let queryItems = urlComponents?.queryItems {
                for queryItem in queryItems {
                    let value = queryItem.value?.safeStringByRemovingPercentEncoding ?? ""
                    queryStringParameters.updateValue(value, forKey: queryItem.name)
                }
            }
            
            // According to the OAuth1.0a spec, the url used for signing is ONLY scheme, path, and query
            if(queryStringParameters.count>0)
            {
                urlComponents?.query = nil
                // This is safe to unwrap because these just came from an NSURL
                signatureUrl = urlComponents?.URL ?? url
            }
            signatureParameters = signatureParameters.join(queryStringParameters)
            
            requestHeaders += self.credential.makeHeaders(signatureUrl, method: method, parameters: signatureParameters, body: body)
            if let addHeaders = headers {
                requestHeaders += addHeaders
            }
            request.headers = requestHeaders

            request.dataEncoding = OAuthSwiftDataEncoding
            return request
        }
        return nil
    }

    public func postImage(urlString: String, parameters: Dictionary<String, AnyObject>, image: NSData, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.multiPartRequest(urlString, method: .POST, parameters: parameters, image: image, success: success, failure: failure)
    }

    func multiPartRequest(url: String, method: OAuthSwiftHTTPRequest.Method, parameters: Dictionary<String, AnyObject>, image: NSData, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {

        if let request = makeRequest(url, method: method, parameters: parameters) {
            
            var paramImage = [String: AnyObject]()
            paramImage["media"] = image
            let boundary = "AS-boundary-\(arc4random())-\(arc4random())"
            let type = "multipart/form-data; boundary=\(boundary)"
            let body = self.multiPartBodyFromParams(paramImage, boundary: boundary)
            
            request.HTTPBody = body
            request.headers += ["Content-Type": type] // "Content-Length": body.length.description
            
            request.successHandler = success
            request.failureHandler = failure
            request.start()
        }
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

    public func postMultiPartRequest(url: String, method: OAuthSwiftHTTPRequest.Method, parameters: Dictionary<String, AnyObject>, multiparts: Array<OAuthSwiftMultipartData> = [], success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        
        if let request = makeRequest(url, method: method, parameters: parameters) {

            let boundary = "POST-boundary-\(arc4random())-\(arc4random())"
            let type = "multipart/form-data; boundary=\(boundary)"
            let body = self.multiDataFromObject(parameters, multiparts: multiparts, boundary: boundary)

            request.HTTPBody = body
            request.headers += ["Content-Type": type] // "Content-Length": body.length.description
            
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
