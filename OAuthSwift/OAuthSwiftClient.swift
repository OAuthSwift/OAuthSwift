//
//  OAuthSwiftClient.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

var dataEncoding: NSStringEncoding = NSUTF8StringEncoding

public class OAuthSwiftClient {

    private(set) public var credential: OAuthSwiftCredential
    
    public init(consumerKey: String, consumerSecret: String) {
        self.credential = OAuthSwiftCredential(consumer_key: consumerKey, consumer_secret: consumerSecret)
    }
    
    public init(consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String) {
        self.credential = OAuthSwiftCredential(oauth_token: accessToken, oauth_token_secret: accessTokenSecret)
        self.credential.consumer_key = consumerKey
        self.credential.consumer_secret = consumerSecret
    }
    
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

            request.dataEncoding = dataEncoding
            return request
        }
        return nil
    }

    public func postImage(urlString: String, parameters: Dictionary<String, AnyObject>, image: NSData, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.multiPartRequest(urlString, method: .POST, parameters: parameters, image: image, success: success, failure: failure)
    }

    func multiPartRequest(url: String, method: OAuthSwiftHTTPRequest.Method, parameters: Dictionary<String, AnyObject>, image: NSData, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {

        if let request = makeRequest(url, method: method, parameters: parameters) {
            
            var parmaImage = [String: AnyObject]()
            parmaImage["media"] = image
            let boundary = "AS-boundary-\(arc4random())-\(arc4random())"
            let type = "multipart/form-data; boundary=\(boundary)"
            let body = self.multiPartBodyFromParams(parmaImage, boundary: boundary)
            
            request.HTTPBody = body
            request.headers += ["Content-Type": type] // "Content-Length": body.length.description
            
            request.successHandler = success
            request.failureHandler = failure
            request.start()
        }
    }

    public func multiPartBodyFromParams(parameters: [String: AnyObject], boundary: String) -> NSData {
        let data = NSMutableData()
        
        let prefixData = "--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)
        let seperData = "\r\n".dataUsingEncoding(NSUTF8StringEncoding)
        
        for (key, value) in parameters {
            var sectionData: NSData?
            var sectionType: String?
            var sectionFilename = ""
            
            if key == "media" {
                let multiData = value as! NSData
                sectionData = multiData
                sectionType = "image/jpeg"
                sectionFilename = " filename=\"file\""
            } else {
                sectionData = "\(value)".dataUsingEncoding(NSUTF8StringEncoding)
            }
            
            data.appendData(prefixData!)
            
            let sectionDisposition = "Content-Disposition: form-data; name=\"media\";\(sectionFilename)\r\n".dataUsingEncoding(NSUTF8StringEncoding)
            data.appendData(sectionDisposition!)
            
            if let type = sectionType {
                let contentType = "Content-Type: \(type)\r\n".dataUsingEncoding(NSUTF8StringEncoding)
                data.appendData(contentType!)
            }
            
            // append data
            data.appendData(seperData!)
            data.appendData(sectionData!)
            data.appendData(seperData!)
        }
        
        data.appendData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        return data
    }

    public func postMultiPartRequest(url: String, method: OAuthSwiftHTTPRequest.Method, parameters: Dictionary<String, AnyObject>, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        
        if let request = makeRequest(url, method: method, parameters: parameters) {

            let boundary = "POST-boundary-\(arc4random())-\(arc4random())"
            let type = "multipart/form-data; boundary=\(boundary)"
            let body = self.multiDataFromObject(parameters, boundary: boundary)

            request.HTTPBody = body
            request.headers += ["Content-Type": type] // "Content-Length": body.length.description
            
            request.successHandler = success
            request.failureHandler = failure
            request.start()
        }
    }

    func multiDataFromObject(object: [String:AnyObject], boundary: String) -> NSData? {
        let data = NSMutableData()

        let prefixString = "--\(boundary)\r\n"
        let prefixData = prefixString.dataUsingEncoding(NSUTF8StringEncoding)!

        let seperatorString = "\r\n"
        let seperatorData = seperatorString.dataUsingEncoding(NSUTF8StringEncoding)!

        for (key, value) in object {

            var valueData: NSData?
            let valueType: String = ""
            let filenameClause = ""

            let stringValue = "\(value)"
            valueData = stringValue.dataUsingEncoding(NSUTF8StringEncoding)!

            if valueData == nil {
                continue
            }
            data.appendData(prefixData)
            let contentDispositionString = "Content-Disposition: form-data; name=\"\(key)\";\(filenameClause)\r\n"
            let contentDispositionData = contentDispositionString.dataUsingEncoding(NSUTF8StringEncoding)
            data.appendData(contentDispositionData!)
            if let type: String = valueType {
                let contentTypeString = "Content-Type: \(type)\r\n"
                let contentTypeData = contentTypeString.dataUsingEncoding(NSUTF8StringEncoding)
                data.appendData(contentTypeData!)
            }
            data.appendData(seperatorData)
            data.appendData(valueData!)
            data.appendData(seperatorData)
        }

        let endingString = "--\(boundary)--\r\n"
        let endingData = endingString.dataUsingEncoding(NSUTF8StringEncoding)!
        data.appendData(endingData)

        return data
    }

    @available(*, deprecated=0.4.6, message="Because method moved to OAuthSwiftCredential!")
    public class func authorizationHeaderForMethod(method: String, url: NSURL, parameters: Dictionary<String, AnyObject>, credential: OAuthSwiftCredential) -> String {
        return credential.authorizationHeaderForMethod(OAuthSwiftHTTPRequest.Method(rawValue: method)!, url: url, parameters: parameters)
    }
    
    @available(*, deprecated=0.4.6, message="Because method moved to OAuthSwiftCredential!")
    public class func signatureForMethod(method: String, url: NSURL, parameters: Dictionary<String, AnyObject>, credential: OAuthSwiftCredential) -> String {
        return credential.signatureForMethod(OAuthSwiftHTTPRequest.Method(rawValue: method)!, url: url, parameters: parameters)
    }
}
