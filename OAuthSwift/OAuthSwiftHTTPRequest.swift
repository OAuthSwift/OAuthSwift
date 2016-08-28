//
//  OAuthSwiftHTTPRequest.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

open class OAuthSwiftHTTPRequest: NSObject, URLSessionDelegate, OAuthSwiftRequestHandle {

    public typealias SuccessHandler = (_ data: Data, _ response: HTTPURLResponse) -> Void
    public typealias FailureHandler = (_ error: NSError) -> Void

    public enum Method: String {
        case GET, POST, PUT, DELETE, PATCH, HEAD //, OPTIONS, TRACE, CONNECT
        
        var isBody: Bool {
            return self == .POST || self == .PUT || self == .PATCH
        }
    }
    
    @objc public enum ParamsLocation : Int {
        case authorizationHeader, /*FormEncodedBody,*/ requestURIQuery
    }

    var URL: Foundation.URL
    var HTTPMethod: Method
    var HTTPBody: Data?

    fileprivate var request: NSMutableURLRequest?
    fileprivate var task: URLSessionTask?
    fileprivate var session: URLSession!
    
    fileprivate var cancelRequested = false

    var headers: Dictionary<String, String>
    var parameters: [String: Any]

    var dataEncoding: String.Encoding
    var charset: CFString {
        return CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.dataEncoding.rawValue))
    }

    var timeoutInterval: TimeInterval

    var HTTPShouldHandleCookies: Bool

    var response: HTTPURLResponse!
    var responseData: NSMutableData

    var successHandler: SuccessHandler?
    var failureHandler: FailureHandler?
    
    var paramsLocation: ParamsLocation

    open static var executionContext: (@escaping () -> Void) -> Void = { block in
        return DispatchQueue.main.async(execute: block)
    }

    convenience init(URL: Foundation.URL) {
        self.init(URL: URL, method: .GET, parameters: [:])
    }

    init(URL: Foundation.URL, method: Method, parameters: [String: Any], paramsLocation : ParamsLocation = .authorizationHeader) {
        self.URL = URL
        self.HTTPMethod = method
        self.headers = [:]
        self.parameters = parameters
        self.dataEncoding = String.Encoding.utf8
        self.timeoutInterval = 60
        self.HTTPShouldHandleCookies = false
        self.responseData = NSMutableData()
        self.paramsLocation = paramsLocation
    }

    init(request: URLRequest, paramsLocation : ParamsLocation = .authorizationHeader) {
        self.request = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest

        self.URL = request.url!
        self.HTTPMethod = Method(rawValue: request.httpMethod ?? "") ?? .GET
        self.headers = request.allHTTPHeaderFields ?? [:]
        self.parameters = [:]
        self.HTTPBody = request.httpBody
        self.dataEncoding = String.Encoding.utf8
        self.timeoutInterval = request.timeoutInterval
        self.HTTPShouldHandleCookies = request.httpShouldHandleCookies
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
            // perform lock here to prevent cancel calls on another thread while creating the request
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            
            if self.cancelRequested {
                return
            }
            self.session = URLSession(configuration: URLSessionConfiguration.default,
                delegate: self,
                delegateQueue: OperationQueue.main)
            self.task = self.session.dataTask(with: self.request! as URLRequest) { [unowned self] (data, response, error) in
            
                #if os(iOS)
                    #if !OAUTH_APP_EXTENSIONS
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    #endif
                #endif
                
                guard error == nil else {
                    self.failureHandler?(error! as NSError)
                    return
                }
              
                guard let httpResponse = response as? HTTPURLResponse,
                      let data = data
                else {
                    // We did not get a response. Use previous.
                    let responseString = String(data: self.responseData as Data, encoding: self.dataEncoding)!
                    let localizedDescription = OAuthSwiftHTTPRequest.descriptionForHTTPStatus(self.response.statusCode, responseString: responseString)
                    let userInfo : [String : Any] = [NSLocalizedDescriptionKey: localizedDescription, "Response-Headers": self.response.allHeaderFields]
                    let error = NSError(domain: NSURLErrorDomain, code: self.response.statusCode, userInfo: userInfo)
                    self.failureHandler?(error)
                    return
                }

                self.response = httpResponse
                self.responseData.length = 0
                self.responseData.append(data)

                if httpResponse.statusCode >= 400 {
                    var errorCode =  OAuthSwiftErrorCode.generalError.rawValue
                    var localizedDescription = String()
                    let responseString = String(data: data, encoding: self.dataEncoding)!

                  
                    let responseJSON = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
                    
                    if let responseJSON = responseJSON as? [String: Any] {
                        if let code = responseJSON["error"] as? String, let description = responseJSON["error_description"] as? String {
                            localizedDescription = NSLocalizedString("\(code) \(description)", comment: "")
                            
                            if code == "authorization_pending" {
                                errorCode = OAuthSwiftErrorCode.authorizationPending.rawValue
                            }
                        }
                    } else {
                        errorCode = httpResponse.statusCode
                        localizedDescription = OAuthSwiftHTTPRequest.descriptionForHTTPStatus(httpResponse.statusCode, responseString: responseString)
                    }
                    
                    let userInfo: [String: Any] = [
                        NSLocalizedDescriptionKey: localizedDescription,
                        "Response-Headers": httpResponse.allHeaderFields,
                        "Response-Body": responseString,
                        OAuthSwiftErrorResponseKey: response ?? NSNull(),
                        OAuthSwiftErrorResponseDataKey: data
                    ]
                    
                    let error = NSError(domain: NSURLErrorDomain, code: errorCode, userInfo: userInfo)
                    self.failureHandler?(error)
                    return
                }
                
                self.successHandler?(self.responseData as Data, self.response)
            }
            self.task?.resume()

            #if os(iOS)
                #if !OAUTH_APP_EXTENSIONS
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                #endif
            #endif
        }
    }

    open func cancel() {
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

    open func makeRequest() throws -> NSMutableURLRequest {
        return try OAuthSwiftHTTPRequest.makeRequest(self.URL, method: self.HTTPMethod, headers: self.headers, parameters: self.parameters, dataEncoding: self.dataEncoding, body: self.HTTPBody, paramsLocation: self.paramsLocation)
    }

    open class func makeRequest(
        _ URL: Foundation.URL,
        method: Method,
        headers: [String : String],
        parameters: [String: Any],
        dataEncoding: String.Encoding,
        body: Data? = nil,
        paramsLocation: ParamsLocation = .authorizationHeader) throws -> NSMutableURLRequest {
            let request = NSMutableURLRequest(url: URL)
            request.httpMethod = method.rawValue
            return try setupRequestForOAuth(request,
                headers: headers,
                parameters: parameters,
                dataEncoding: dataEncoding,
                body: body,
                paramsLocation: paramsLocation
            )
            
    }

    open class func setupRequestForOAuth(_ request: NSMutableURLRequest,
        headers: [String : String],
        parameters: [String: Any],
        dataEncoding: String.Encoding,
        body: Data? = nil,
        paramsLocation : ParamsLocation = .authorizationHeader) throws -> NSMutableURLRequest {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }

            let charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(dataEncoding.rawValue))

            let finalParameters : [String: Any]
            switch (paramsLocation) {
            case .authorizationHeader:
                finalParameters = parameters.filter { key, _ in !key.hasPrefix("oauth_") }
            case .requestURIQuery:
                finalParameters = parameters
            }

            if let b = body {
                request.httpBody = b
            } else {
                if finalParameters.count > 0 {
                    if request.httpMethod == "GET" || request.httpMethod == "HEAD" || request.httpMethod == "DELETE" {
                        let queryString = finalParameters.urlEncodedQueryStringWithEncoding(dataEncoding)
                        let URL = request.url!
                        request.url = URL.URLByAppendingQueryString(queryString)
                        if headers["Content-Type"] == nil {
                            request.setValue("application/x-www-form-urlencoded; charset=\(charset)", forHTTPHeaderField: "Content-Type")
                        }
                    }
                    else {
                        if let contentType = headers["Content-Type"] , contentType.range(of: "application/json") != nil {
                            let jsonData: Data = try JSONSerialization.data(withJSONObject: finalParameters, options: [])
                            request.setValue("application/json; charset=\(charset)", forHTTPHeaderField: "Content-Type")
                            request.httpBody = jsonData
                        }
                        else {
                            request.setValue("application/x-www-form-urlencoded; charset=\(charset)", forHTTPHeaderField: "Content-Type")
                            let queryString = finalParameters.urlEncodedQueryStringWithEncoding(dataEncoding)
                            request.httpBody = queryString.data(using: String.Encoding.utf8, allowLossyConversion: true)
                        }
                    }
                }
            }
            return request
    }

    class func stringWithData(_ data: Data, encodingName: String?) -> String {
        var encoding = String.Encoding.utf8

        if (encodingName != nil) {
            let encodingNameString = encodingName! as NSString
            encoding = String.Encoding.init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(encodingNameString)))

            if encoding.rawValue == UInt(kCFStringEncodingInvalidId) {
                encoding = String.Encoding.utf8 // by default
            }
        }

        return String(data: data, encoding: encoding)!
    }

    class func descriptionForHTTPStatus(_ status: Int, responseString: String) -> String {
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
