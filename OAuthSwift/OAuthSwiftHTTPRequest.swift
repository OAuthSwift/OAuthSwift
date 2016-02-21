//
//  OAuthSwiftHTTPRequest.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

public class OAuthSwiftHTTPRequest: NSObject, NSURLSessionDelegate {

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

    var URL: NSURL
    var HTTPMethod: Method
    var HTTPBody: NSData?

    var request: NSMutableURLRequest?
    var session: NSURLSession!

    var headers: Dictionary<String, String>
    var parameters: Dictionary<String, AnyObject>

    var dataEncoding: NSStringEncoding
    var charset: CFString {
        return CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.dataEncoding))
    }

    var timeoutInterval: NSTimeInterval

    var HTTPShouldHandleCookies: Bool

    var response: NSHTTPURLResponse!
    var responseData: NSMutableData

    var successHandler: SuccessHandler?
    var failureHandler: FailureHandler?
    
    var paramsLocation: ParamsLocation

    public static var executionContext: (() -> Void) -> Void = { block in
        return dispatch_async(dispatch_get_main_queue(), block)
    }

    convenience init(URL: NSURL) {
        self.init(URL: URL, method: .GET, parameters: [:])
    }

    init(URL: NSURL, method: Method, parameters: Dictionary<String, AnyObject>, paramsLocation : ParamsLocation = .AuthorizationHeader) {
        self.URL = URL
        self.HTTPMethod = method
        self.headers = [:]
        self.parameters = parameters
        self.dataEncoding = NSUTF8StringEncoding
        self.timeoutInterval = 60
        self.HTTPShouldHandleCookies = false
        self.responseData = NSMutableData()
        self.paramsLocation = paramsLocation
    }

    init(request: NSURLRequest, paramsLocation : ParamsLocation = .AuthorizationHeader) {
        self.request = request as? NSMutableURLRequest
        self.URL = request.URL!
        self.HTTPMethod = Method(rawValue: request.HTTPMethod ?? "") ?? .GET
        self.headers = [:]
        self.parameters = [:]
        self.dataEncoding = NSUTF8StringEncoding
        self.timeoutInterval = 60
        self.HTTPShouldHandleCookies = false
        self.responseData = NSMutableData()
        self.paramsLocation = paramsLocation
    }

    func start() {
        if (request == nil) {
            var error: NSError?

            do {
                self.request = try self.makeRequest()
            } catch let error1 as NSError {
                error = error1
                self.request = nil
            }

            if ((error) != nil) {
                print(error!.localizedDescription)
            }
        }

        OAuthSwiftHTTPRequest.executionContext {
            self.session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
                delegate: self,
                delegateQueue: NSOperationQueue.mainQueue())
            let task: NSURLSessionDataTask = self.session.dataTaskWithRequest(self.request!) { [unowned self] data, response, error -> Void in
                #if os(iOS)
                    #if !OAUTH_APP_EXTENSIONS
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    #endif
                #endif
                
                guard error == nil else {
                    self.failureHandler?(error: error!)
                    return
                }

                guard response != nil && (response as? NSHTTPURLResponse) != nil && data != nil else {
                    let responseString = NSString(data: self.responseData, encoding: self.dataEncoding)
                    let localizedDescription = OAuthSwiftHTTPRequest.descriptionForHTTPStatus(self.response.statusCode, responseString: responseString! as String)
                    let userInfo : [NSObject : AnyObject] = [NSLocalizedDescriptionKey: localizedDescription, "Response-Headers": self.response.allHeaderFields]
                    let error = NSError(domain: NSURLErrorDomain, code: self.response.statusCode, userInfo: userInfo)
                    self.failureHandler?(error: error)
                    return
                }

                self.response = response as? NSHTTPURLResponse
                self.responseData.length = 0
                self.responseData.appendData(data!)

                if (response as? NSHTTPURLResponse)?.statusCode >= 400 {
                    let responseString = NSString(data: self.responseData, encoding: self.dataEncoding)
                    let localizedDescription = OAuthSwiftHTTPRequest.descriptionForHTTPStatus(self.response.statusCode, responseString: responseString! as String)
                    let userInfo : [NSObject : AnyObject] = [
                        NSLocalizedDescriptionKey: localizedDescription,
                        "Response-Headers": self.response.allHeaderFields,
                        "Response-Body": responseString ?? NSNull()
                    ]
                    let error = NSError(domain: NSURLErrorDomain, code: self.response.statusCode, userInfo: userInfo)
                    self.failureHandler?(error: error)
                    return
                }
                
                self.successHandler?(data: self.responseData, response: self.response)
            }
            task.resume()

            #if os(iOS)
                #if !OAUTH_APP_EXTENSIONS
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                #endif
            #endif
        }
    }

    public func makeRequest() throws -> NSMutableURLRequest {
        return try OAuthSwiftHTTPRequest.makeRequest(self.URL, method: self.HTTPMethod, headers: self.headers, parameters: self.parameters, dataEncoding: self.dataEncoding, body: self.HTTPBody, paramsLocation: self.paramsLocation)
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
        headers: [String : String],
        parameters: Dictionary<String, AnyObject>,
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
