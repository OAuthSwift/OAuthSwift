//
//  OAuthSwiftHTTPRequest.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

let kHTTPHeaderContentType = "Content-Type"

public class OAuthSwiftHTTPRequest: NSObject, NSURLSessionDelegate, OAuthSwiftRequestHandle {

    public typealias SuccessHandler = (data: NSData, response: NSHTTPURLResponse) -> Void
    public typealias FailureHandler = (error: NSError) -> Void

    // HTTP request method
    // https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods
    public enum Method: String {
        case GET, POST, PUT, DELETE, PATCH, HEAD //, OPTIONS, TRACE, CONNECT
        
        var isBody: Bool {
            return self == .POST || self == .PUT || self == .PATCH
        }
    }

    // Where the additional parameters will be injected
    @objc public enum ParamsLocation : Int {
        case AuthorizationHeader, /*FormEncodedBody,*/ RequestURIQuery
    }

    // Configuration for request
    public struct Config {

        // NSURLRequest (url, method, ...)
        public let urlRequest: NSMutableURLRequest   // TODO make this not mutable (ie. do not allow to modify header after...
        /// These parameters are either added to the query string for GET, HEAD and DELETE requests or
        /// used as the http body in case of POST, PUT or PATCH requests.
        ///
        /// If used in the body they are either encoded as JSON or as encoded plaintext based on the Content-Type header field.
        public var parameters: [String: AnyObject]
        public let paramsLocation: ParamsLocation
        public let dataEncoding: NSStringEncoding
        
        public var HTTPMethod: Method {
            let requestMethod = urlRequest.HTTPMethod
            return Method(rawValue: requestMethod) ?? .GET
        }
        
        public var URL: NSURL? {
            return urlRequest.URL
        }

        public var charset: CFString {
            return CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.dataEncoding))
        }

        public init(url: NSURL, HTTPMethod: Method = .GET, HTTPBody: NSData? = nil, headers: [String: String] = [:], timeoutInterval: NSTimeInterval = 60
            , HTTPShouldHandleCookies: Bool = false, parameters: [String: AnyObject], paramsLocation: ParamsLocation = .AuthorizationHeader, dataEncoding: NSStringEncoding = OAuthSwiftDataEncoding) {
            let urlRequest = NSMutableURLRequest(URL: url)
            urlRequest.HTTPMethod = HTTPMethod.rawValue
            urlRequest.HTTPBody = HTTPBody
            urlRequest.allHTTPHeaderFields = headers
            urlRequest.timeoutInterval = timeoutInterval
            urlRequest.HTTPShouldHandleCookies = HTTPShouldHandleCookies
            self.init(urlRequest: urlRequest, parameters: parameters, paramsLocation: paramsLocation, dataEncoding: dataEncoding)
        }
        
        public init(urlRequest: NSURLRequest, parameters: [String: AnyObject] = [:], paramsLocation: ParamsLocation = .AuthorizationHeader, dataEncoding: NSStringEncoding = OAuthSwiftDataEncoding) {
            self.urlRequest = urlRequest.mutableCopy() as! NSMutableURLRequest
            self.parameters = parameters
            self.paramsLocation = paramsLocation
            self.dataEncoding = dataEncoding
        }
    }
    public private(set) var config: Config
    
    
    private var request: NSMutableURLRequest?
    private var task: NSURLSessionTask?
    private var session: NSURLSession!
    
    private var cancelRequested = false

    var successHandler: SuccessHandler?
    var failureHandler: FailureHandler?
    

    public static var executionContext: (() -> Void) -> Void = { block in
        return dispatch_async(dispatch_get_main_queue(), block)
    }
    
    // MARK: INIT

    convenience init(URL: NSURL, method: Method = .GET, parameters: [String: AnyObject] = [:], paramsLocation : ParamsLocation = .AuthorizationHeader, HTTPBody: NSData? = nil, headers: [String: String] = [:]) {
        self.init(config: Config(url: URL, HTTPMethod: method, HTTPBody: HTTPBody, headers: headers, parameters: parameters, paramsLocation: paramsLocation))
    }

    convenience init(request: NSURLRequest, paramsLocation : ParamsLocation = .AuthorizationHeader) {
        self.init(config: Config(urlRequest: request, paramsLocation: paramsLocation))
    }
    
    init(config: Config) {
        self.config = config
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
                    let badRequestCode = 400
                    let localizedDescription = OAuthSwiftHTTPRequest.descriptionForHTTPStatus(badRequestCode, responseString: "")
                    let userInfo : [NSObject : AnyObject] = [NSLocalizedDescriptionKey: localizedDescription]
                    let error = NSError(domain: NSURLErrorDomain, code: badRequestCode, userInfo: userInfo)
                    self.failureHandler?(error: error)
                    return
                }

                guard response.statusCode < 400 else {
                    var errorCode = response.statusCode
                    var localizedDescription = String()
                    let responseString = String(data: responseData, encoding: self.config.dataEncoding)
   
                    if let responseJSON = try? NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers) {
                        if let code = responseJSON["error"] as? String, description = responseJSON["error_description"] as? String {
                            localizedDescription = NSLocalizedString("\(code) \(description)", comment: "")
                            if code == "authorization_pending" {
                                errorCode = OAuthSwiftErrorCode.AuthorizationPending.rawValue
                            }
                        }
                    } else {
                        localizedDescription = OAuthSwiftHTTPRequest.descriptionForHTTPStatus(response.statusCode, responseString: String(data: responseData, encoding: self.config.dataEncoding)!)
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
        return try OAuthSwiftHTTPRequest.makeRequest(self.config)
    }
    
    public class func makeRequest(config: Config)  throws -> NSMutableURLRequest  {
        let request = config.urlRequest.mutableCopy() as! NSMutableURLRequest
        return try setupRequestForOAuth(request,
                                        headers: [:], // request.allHTTPHeaderFields (useless already in request, keep compatibility)
                                        parameters: config.parameters,
                                        dataEncoding: config.dataEncoding,
                                        body: nil, // config.body (useless already in request, keep compatibility)
                                        paramsLocation: config.paramsLocation
        )
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
        let finalHeaders = request.allHTTPHeaderFields ?? [:]
        
        let charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(dataEncoding))
        
        let finalParameters : [String: AnyObject]
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
                    if finalHeaders[kHTTPHeaderContentType] == nil {
                        request.setValue("application/x-www-form-urlencoded; charset=\(charset)", forHTTPHeaderField: kHTTPHeaderContentType)
                    }
                }
                else {
                    if let contentType = finalHeaders[kHTTPHeaderContentType] where contentType.rangeOfString("application/json") != nil {
                        let jsonData: NSData = try NSJSONSerialization.dataWithJSONObject(finalParameters, options: [])
                        request.setValue("application/json; charset=\(charset)", forHTTPHeaderField: kHTTPHeaderContentType)
                        request.HTTPBody = jsonData
                    }
                    else {
                        request.setValue("application/x-www-form-urlencoded; charset=\(charset)", forHTTPHeaderField: kHTTPHeaderContentType)
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

    func makeOAuthSwiftHTTPRequest(credential: OAuthSwiftCredential) {
        let method = self.config.HTTPMethod
        let url = self.config.urlRequest.URL!
        let headers = self.config.urlRequest.allHTTPHeaderFields ?? [:]
        let paramsLocation = self.config.paramsLocation
        let parameters = self.config.parameters
        
        
        var signatureUrl = url
        var signatureParameters = parameters
        
        // Check if body must be hashed (oauth1)
        let body: NSData? = nil
        if method.isBody {
            if let contentType = headers[kHTTPHeaderContentType]?.lowercaseString {
                
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
        
        var queryStringParameters = [String: AnyObject]()
        let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: false )
        if let queryItems = urlComponents?.queryItems {
            for queryItem in queryItems {
                let value = queryItem.value?.safeStringByRemovingPercentEncoding ?? ""
                queryStringParameters.updateValue(value, forKey: queryItem.name)
            }
        }
        
        // According to the OAuth1.0a spec, the url used for signing is ONLY scheme, path, and query
        if queryStringParameters.count>0 {
            urlComponents?.query = nil
            // This is safe to unwrap because these just came from an NSURL
            signatureUrl = urlComponents?.URL ?? url
        }
        signatureParameters = signatureParameters.join(queryStringParameters)
        
        var requestHeaders = [String:String]()
        switch paramsLocation {
        case .AuthorizationHeader:
            //Add oauth parameters in the Authorization header
            requestHeaders += credential.makeHeaders(signatureUrl, method: method, parameters: signatureParameters, body: body)
        case .RequestURIQuery:
            //Add oauth parameters as request parameters
            self.config.parameters += credential.authorizationParametersWithSignatureForMethod(method, url: signatureUrl, parameters: signatureParameters, body: body)
        }

        self.config.urlRequest.allHTTPHeaderFields = requestHeaders + headers
    }

}

// MARK: status code mapping

extension OAuthSwiftHTTPRequest {

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
