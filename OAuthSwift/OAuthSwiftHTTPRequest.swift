//
//  OAuthSwiftHTTPRequest.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

public class OAuthSwiftHTTPRequest: NSObject, NSURLConnectionDataDelegate {
    
    public typealias SuccessHandler = (data: NSData, response: NSHTTPURLResponse) -> Void
    public typealias FailureHandler = (error: NSError) -> Void
    
    var URL: NSURL
    var HTTPMethod: String
    var HTTPBodyMultipart: NSData?
    var contentTypeMultipart: String?
    
    var request: NSMutableURLRequest?
    var connection: NSURLConnection!
    
    var headers: Dictionary<String, String>
    var parameters: Dictionary<String, AnyObject>
    var encodeParameters: Bool
    
    var dataEncoding: NSStringEncoding
    
    var timeoutInterval: NSTimeInterval
    
    var HTTPShouldHandleCookies: Bool
    
    var response: NSHTTPURLResponse!
    var responseData: NSMutableData
    
    var successHandler: SuccessHandler?
    var failureHandler: FailureHandler?
    
    convenience init(URL: NSURL) {
        self.init(URL: URL, method: "GET", parameters: [:])
    }
    
    init(URL: NSURL, method: String, parameters: Dictionary<String, AnyObject>) {
        self.URL = URL
        self.HTTPMethod = method
        self.headers = [:]
        self.parameters = parameters
        self.encodeParameters = false
        self.dataEncoding = NSUTF8StringEncoding
        self.timeoutInterval = 60
        self.HTTPShouldHandleCookies = false
        self.responseData = NSMutableData()
    }
    
    init(request: NSURLRequest) {
        self.request = request as? NSMutableURLRequest
        self.URL = request.URL!
        self.HTTPMethod = request.HTTPMethod!
        self.headers = [:]
        self.parameters = [:]
        self.encodeParameters = false
        self.dataEncoding = NSUTF8StringEncoding
        self.timeoutInterval = 60
        self.HTTPShouldHandleCookies = false
        self.responseData = NSMutableData()
    }
    
    func start() {
        if (request == nil) {
            var error: NSError?
            
            self.request = OAuthSwiftHTTPRequest.makeRequest(self.URL, method: self.HTTPMethod, headers: self.headers, parameters: self.parameters, dataEncoding: self.dataEncoding, encodeParameters: self.encodeParameters, error: &error, body: self.HTTPBodyMultipart, contentType: self.contentTypeMultipart)
                
            if ((error) != nil) {
                println(error!.localizedDescription)
            }
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.connection = NSURLConnection(request: self.request!, delegate: self)
            self.connection.start()
            
            #if os(iOS)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            #endif
        }
    }
    
    public class func makeRequest(        URL: NSURL,
        method: String,
        headers: [String : String],
        parameters: Dictionary<String, AnyObject>,
        dataEncoding: NSStringEncoding,
        encodeParameters: Bool,
        error: NSErrorPointer,
        body: NSData? = nil,
        contentType: String? = nil) -> NSMutableURLRequest? {
            var request = NSMutableURLRequest(URL: URL)
            request.HTTPMethod = method
            
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            let charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(dataEncoding))
            
            var nonOAuthParameters = parameters.filter { key, _ in !key.hasPrefix("oauth_") }
            
            if (body != nil && contentType != nil) {
                request.setValue(contentType!, forHTTPHeaderField: "Content-Type")
                //request!.setValue(self.HTTPBodyMultipart!.length.description, forHTTPHeaderField: "Content-Length")
                request.HTTPBody = body!
            } else {
                if nonOAuthParameters.count > 0 {
                    if request.HTTPMethod == "GET" || request.HTTPMethod == "HEAD" || request.HTTPMethod == "DELETE" {
                        let queryString = nonOAuthParameters.urlEncodedQueryStringWithEncoding(dataEncoding)
                        request.URL = URL.URLByAppendingQueryString(queryString)
                        request.setValue("application/x-www-form-urlencoded; charset=\(charset)", forHTTPHeaderField: "Content-Type")
                    }
                    else {
                        if (encodeParameters) {
                            let queryString = nonOAuthParameters.urlEncodedQueryStringWithEncoding(dataEncoding)
                            //self.request!.URL = self.URL.URLByAppendingQueryString(queryString)
                            request.setValue("application/x-www-form-urlencoded; charset=\(charset)", forHTTPHeaderField: "Content-Type")
                            request.HTTPBody = queryString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
                        }
                        else {
                            var jsonError: NSError?
                            if let jsonData: NSData = NSJSONSerialization.dataWithJSONObject(nonOAuthParameters, options: nil, error: &jsonError)  {
                                request.setValue("application/json; charset=\(charset)", forHTTPHeaderField: "Content-Type")
                                request.HTTPBody = jsonData
                            }
                            else {
                                if (error != nil) {
                                    //println(jsonError!.localizedDescription)
                                    error.memory = jsonError
                                }
                                return nil
                            }
                        }
                    }
                }
            }
            return request
    }
    

    public func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        self.response = response as? NSHTTPURLResponse
        
        self.responseData.length = 0
    }
    
    public func connection(connection: NSURLConnection, didSendBodyData bytesWritten: Int, totalBytesWritten: Int, totalBytesExpectedToWrite: Int) {
    }
    
    public func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.responseData.appendData(data)
    }
    
    public func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        #if os(iOS)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        #endif
        
        self.failureHandler?(error: error)
    }
    
    public func connectionDidFinishLoading(connection: NSURLConnection) {
        #if os(iOS)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        #endif
        
        if self.response.statusCode >= 400 {
            let responseString = NSString(data: self.responseData, encoding: self.dataEncoding)
            let localizedDescription = OAuthSwiftHTTPRequest.descriptionForHTTPStatus(self.response.statusCode, responseString: responseString! as! String)
            let userInfo : [NSObject : AnyObject] = [NSLocalizedDescriptionKey: localizedDescription, "Response-Headers": self.response.allHeaderFields]
            let error = NSError(domain: NSURLErrorDomain, code: self.response.statusCode, userInfo: userInfo)
            self.failureHandler?(error: error)
            return
        }
        
        self.successHandler?(data: self.responseData, response: self.response)
    }
    
    class func stringWithData(data: NSData, encodingName: String?) -> String {
        var encoding: UInt = NSUTF8StringEncoding
        
        if (encodingName != nil) {
            let encodingNameString = encodingName! as NSString
            encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(encodingNameString))
            
            if encoding == UInt(kCFStringEncodingInvalidId) {
                encoding = NSUTF8StringEncoding // by default
            }
        }
        
        return NSString(data: data, encoding: encoding)! as! String
    }
    
    class func descriptionForHTTPStatus(status: Int, responseString: String) -> String {
        var s = "HTTP Status \(status)"
        
        var description: String?
        // http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml
        if status == 400 { description = "Bad Request" }
        if status == 401 { description = "Unauthorized" }
        if status == 402 { description = "Payment Required" }
        if status == 403 { description = "Forbidden" }
        if status == 404 { description = "Not Found" }
        if status == 405 { description = "Method Not Allowed" }
        if status == 406 { description = "Not Acceptable" }
        if status == 407 { description = "Proxy Authentication Required" }
        if status == 408 { description = "Request Timeout" }
        if status == 409 { description = "Conflict" }
        if status == 410 { description = "Gone" }
        if status == 411 { description = "Length Required" }
        if status == 412 { description = "Precondition Failed" }
        if status == 413 { description = "Payload Too Large" }
        if status == 414 { description = "URI Too Long" }
        if status == 415 { description = "Unsupported Media Type" }
        if status == 416 { description = "Requested Range Not Satisfiable" }
        if status == 417 { description = "Expectation Failed" }
        if status == 422 { description = "Unprocessable Entity" }
        if status == 423 { description = "Locked" }
        if status == 424 { description = "Failed Dependency" }
        if status == 425 { description = "Unassigned" }
        if status == 426 { description = "Upgrade Required" }
        if status == 427 { description = "Unassigned" }
        if status == 428 { description = "Precondition Required" }
        if status == 429 { description = "Too Many Requests" }
        if status == 430 { description = "Unassigned" }
        if status == 431 { description = "Request Header Fields Too Large" }
        if status == 432 { description = "Unassigned" }
        if status == 500 { description = "Internal Server Error" }
        if status == 501 { description = "Not Implemented" }
        if status == 502 { description = "Bad Gateway" }
        if status == 503 { description = "Service Unavailable" }
        if status == 504 { description = "Gateway Timeout" }
        if status == 505 { description = "HTTP Version Not Supported" }
        if status == 506 { description = "Variant Also Negotiates" }
        if status == 507 { description = "Insufficient Storage" }
        if status == 508 { description = "Loop Detected" }
        if status == 509 { description = "Unassigned" }
        if status == 510 { description = "Not Extended" }
        if status == 511 { description = "Network Authentication Required" }
        
        if (description != nil) {
            s = s + ": " + description! + ", Response: " + responseString
        }
        
        return s
    }
    
}
