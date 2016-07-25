//
//  OAuthSwiftHTTPRequest.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

public class OAuthSwiftHTTPRequest: NSObject, NSURLSessionDelegate, OAuthSwiftRequestHandle {

    public typealias SuccessHandler = (data: NSData, response: NSHTTPURLResponse) -> Void
    public typealias FailureHandler = (error: NSError) -> Void

    public enum Method: String {
        case GET, POST, PUT, DELETE, PATCH, HEAD //, OPTIONS, TRACE, CONNECT
        
        var isBody: Bool {
            return self == .POST || self == .PUT || self == .PATCH
        }
    }
    
    @objc public enum ParamsLocation : Int {
        case AuthorizationHeader, /*FormEncodedBody,*/ RequestURIQuery
    }

    // TODO keep a NSMutableURLRequest instead of NSURLRequest instead of all this parameters
    struct OAuthSwiftHTTPRequestConfig {
        // TODO instead keep an NSURLRequest
        var URL: NSURL
        var HTTPMethod: Method
        var HTTPBody: NSData?
        var headers: [String: String]
        var timeoutInterval: NSTimeInterval
        var HTTPShouldHandleCookies: Bool
        
        init(URL: NSURL, HTTPMethod: Method, HTTPBody: NSData?, headers: [String: String], timeoutInterval: NSTimeInterval
        , HTTPShouldHandleCookies: Bool) {
            self.URL = URL
            self.HTTPMethod = HTTPMethod
            self.HTTPBody = HTTPBody
            self.headers = headers
            self.timeoutInterval = timeoutInterval
            self.HTTPShouldHandleCookies = HTTPShouldHandleCookies
        }
        
        init(request: NSURLRequest) {
            self.URL = request.URL!
            self.headers = request.allHTTPHeaderFields ?? [:]
            self.HTTPBody = request.HTTPBody
            self.timeoutInterval = request.timeoutInterval
            self.HTTPShouldHandleCookies = request.HTTPShouldHandleCookies
            self.HTTPMethod = Method(rawValue: request.HTTPMethod ?? "") ?? .GET
        }
    }
    var config: OAuthSwiftHTTPRequestConfig
    var parameters: [String: AnyObject]
    var paramsLocation: ParamsLocation
    var dataEncoding: NSStringEncoding

    private var request: NSMutableURLRequest?
    private var task: NSURLSessionTask?
    private var session: NSURLSession!
    
    private var cancelRequested = false


    var charset: CFString {
        return CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.dataEncoding))
    }


   // var response: NSHTTPURLResponse!
   // var responseData: NSMutableData

    var successHandler: SuccessHandler?
    var failureHandler: FailureHandler?
    

    public static var executionContext: (() -> Void) -> Void = { block in
        return dispatch_async(dispatch_get_main_queue(), block)
    }

    init(URL: NSURL, method: Method = .GET, parameters: Dictionary<String, AnyObject> = [:], paramsLocation : ParamsLocation = .AuthorizationHeader) {
        self.config = OAuthSwiftHTTPRequestConfig(URL: URL, HTTPMethod: method, HTTPBody: nil, headers: [:], timeoutInterval: 60, HTTPShouldHandleCookies: false)
        
        self.parameters = parameters
        self.paramsLocation = paramsLocation
        self.dataEncoding = NSUTF8StringEncoding
    }

    init(request: NSURLRequest, paramsLocation : ParamsLocation = .AuthorizationHeader) {
        
        self.config = OAuthSwiftHTTPRequestConfig(request: request)
        

        self.parameters = [:]
        self.paramsLocation = paramsLocation
        self.dataEncoding = NSUTF8StringEncoding
    }
    
    func start() {
        guard request == nil else { return } // Don't start the same request twice!
        
        do {
            self.request = try self.makeRequest()
        } catch let error as NSError {
            failureHandler?(error: NSError(domain: OAuthSwiftErrorDomain, code: OAuthSwiftErrorCode.RequestCreationError.rawValue, userInfo: [
                NSLocalizedDescriptionKey: error.localizedDescription,
                NSUnderlyingErrorKey: error
                ])
            )
            self.request = nil
            return
        }

        OAuthSwiftHTTPRequest.executionContext {
            // perform lock here to prevent cancel calls on another thread while creating the request
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            if self.cancelRequested {
                return
            }

            self.session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
                delegate: self,
                delegateQueue: NSOperationQueue.mainQueue())
            self.task = self.session.dataTaskWithRequest(self.request!) { [unowned self] data, response, error -> Void in
                #if os(iOS)
                    #if !OAUTH_APP_EXTENSIONS
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    #endif
                #endif
                
                guard error == nil else {
                    self.failureHandler?(error: error!)
                    return
                }

                guard let response = response as? NSHTTPURLResponse, responseData = data else {
                    let localizedDescription = OAuthSwiftHTTPRequest.descriptionForHTTPStatus(400, responseString: "")
                    let userInfo : [NSObject : AnyObject] = [NSLocalizedDescriptionKey: localizedDescription]
                    let error = NSError(domain: NSURLErrorDomain, code: 400, userInfo: userInfo)
                    self.failureHandler?(error: error)
                    return
                }

                guard response.statusCode < 400 else {
                    var errorCode =  OAuthSwiftErrorCode.GeneralError.rawValue
                    var localizedDescription = String()
                    let responseString = String(data: responseData, encoding: self.dataEncoding)
   
                    if let responseJSON = try? NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers) {
                        if let code = responseJSON["error"] as? String, description = responseJSON["error_description"] as? String {
                            localizedDescription = NSLocalizedString("\(code) \(description)", comment: "")
                            if code == "authorization_pending" {
                                errorCode = OAuthSwiftErrorCode.AuthorizationPending.rawValue
                            }
                        }
                    } else {
                        localizedDescription = OAuthSwiftHTTPRequest.descriptionForHTTPStatus(response.statusCode, responseString: String(data: responseData, encoding: self.dataEncoding)!)
                    }
 
                    let userInfo = [
                        NSLocalizedDescriptionKey: localizedDescription,
                        "Response-Headers": response.allHeaderFields,
                        "Response-Body": responseString ?? NSNull(),
                        NSURLErrorFailingURLErrorKey: response.URL?.absoluteString ?? NSNull(),
                        OAuthSwiftErrorResponseKey: response ?? NSNull(),
                        OAuthSwiftErrorResponseDataKey: responseData
                    ]
                    
                    let error = NSError(domain: NSURLErrorDomain, code: errorCode, userInfo: userInfo)
                    self.failureHandler?(error: error)
                    return
                }
                
                self.successHandler?(data: responseData, response: response)
            }
            self.task?.resume()
            self.session.finishTasksAndInvalidate()

            #if os(iOS)
                #if !OAUTH_APP_EXTENSIONS
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                #endif
            #endif
        }
    }

    public func cancel() {
        // perform lock here to prevent cancel calls on another thread while creating the request
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        // either cancel the request if it's already running or set the flag to prohibit creation of the request
        if let task = task {
            task.cancel()
        } else {
            cancelRequested = true
        }
    }

    public func makeRequest() throws -> NSMutableURLRequest {
        return try OAuthSwiftHTTPRequest.makeRequest(self.config.URL, method: self.config.HTTPMethod, headers: self.config.headers, parameters: self.parameters, dataEncoding: self.dataEncoding, body: self.config.HTTPBody, paramsLocation: self.paramsLocation)
    }
    
    public class func makeRequest(
        URL: NSURL,
        method: Method,
        headers: [String : String],
        parameters: Dictionary<String, AnyObject>,
        dataEncoding: NSStringEncoding,
        body: NSData? = nil,
        paramsLocation: ParamsLocation = .AuthorizationHeader) throws -> NSMutableURLRequest {
        let request = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = method.rawValue
        return try setupRequestForOAuth(request,
                                        headers: headers,
                                        parameters: parameters,
                                        dataEncoding: dataEncoding,
                                        body: body,
                                        paramsLocation: paramsLocation
        )
        
    }
    
    public class func setupRequestForOAuth(request: NSMutableURLRequest,
                                           headers: [String : String] = [:],
                                           parameters: [String: AnyObject],
                                           dataEncoding: NSStringEncoding,
                                           body: NSData? = nil,
                                           paramsLocation : ParamsLocation = .AuthorizationHeader) throws -> NSMutableURLRequest {
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(dataEncoding))
        
        let finalParameters : Dictionary<String, AnyObject>
        switch (paramsLocation) {
        case .AuthorizationHeader:
            finalParameters = parameters.filter { key, _ in !key.hasPrefix("oauth_") }
        case .RequestURIQuery:
            finalParameters = parameters
        }
        
        if let b = body {
            request.HTTPBody = b
        } else {
            if finalParameters.count > 0 {
                if request.HTTPMethod == "GET" || request.HTTPMethod == "HEAD" || request.HTTPMethod == "DELETE" {
                    let queryString = finalParameters.urlEncodedQueryStringWithEncoding(dataEncoding)
                    let URL = request.URL!
                    request.URL = URL.URLByAppendingQueryString(queryString)
                    if headers["Content-Type"] == nil {
                        request.setValue("application/x-www-form-urlencoded; charset=\(charset)", forHTTPHeaderField: "Content-Type")
                    }
                }
                else {
                    if let contentType = headers["Content-Type"] where contentType.rangeOfString("application/json") != nil {
                        let jsonData: NSData = try NSJSONSerialization.dataWithJSONObject(finalParameters, options: [])
                        request.setValue("application/json; charset=\(charset)", forHTTPHeaderField: "Content-Type")
                        request.HTTPBody = jsonData
                    }
                    else {
                        request.setValue("application/x-www-form-urlencoded; charset=\(charset)", forHTTPHeaderField: "Content-Type")
                        let queryString = finalParameters.urlEncodedQueryStringWithEncoding(dataEncoding)
                        request.HTTPBody = queryString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
                    }
                }
            }
        }
        return request
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

        return NSString(data: data, encoding: encoding)! as String
    }
    
    // MARK: status code mapping

    private class func descriptionForHTTPStatus(status: Int, responseString: String) -> String {
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
