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

    public let requestConfig: OAuthSwiftHTTPRequestConfig

    private var request: NSURLRequest?
    private var task: NSURLSessionTask?
    private var session: NSURLSession!

    private var cancelRequested = false

    var successHandler: SuccessHandler?
    var failureHandler: FailureHandler?

    public static var executionContext: (() -> Void) -> Void = { block in
        return dispatch_async(dispatch_get_main_queue(), block)
    }

    init(requestConfig: OAuthSwiftHTTPRequestConfig) {
        self.requestConfig = requestConfig
    }

    func start(credentials: OAuthSwiftCredential) {
        // Don't start the same request twice!
        guard request == nil else { return }

        do {
            request = try OAuthSwiftHTTPRequest.makeRequest(requestConfig, credentials: credentials)
        } catch let error as NSError {
            print(error.localizedDescription)
            failureHandler?(error: NSError(domain: OAuthSwiftErrorDomain, code: OAuthSwiftErrorCode.RequestCreationError.rawValue, userInfo: [
                NSLocalizedDescriptionKey: error.localizedDescription,
                NSUnderlyingErrorKey: error
                ])
            )
            request = nil
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
                    let responseString = String(data: responseData, encoding: self.requestConfig.dataEncoding)
                    let localizedDescription = OAuthSwiftHTTPRequest.descriptionForHTTPStatus(response.statusCode, responseString: responseString ?? "")
                    let userInfo : [NSObject : AnyObject] = [
                        NSLocalizedDescriptionKey: localizedDescription,
                        NSURLErrorFailingURLErrorKey: response.URL?.absoluteString ?? NSNull(),
                        "Response-Headers": response.allHeaderFields,
                        "Response-Body": responseString ?? NSNull(),
                        OAuthSwiftErrorResponseKey: response,
                        OAuthSwiftErrorResponseDataKey: responseData
                    ]
                    let error = NSError(domain: NSURLErrorDomain, code: response.statusCode, userInfo: userInfo)
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

}

// MARK: request preparation

extension OAuthSwiftHTTPRequest {

    private class func makeRequest(requestConfig: OAuthSwiftHTTPRequestConfig, credentials: OAuthSwiftCredential) throws -> NSMutableURLRequest {
        let request = requestConfig.request.mutableCopy() as! NSMutableURLRequest
        return try setupRequestForOAuth(request,
            additionalParameters: requestConfig.additionalParameters,
            dataEncoding: requestConfig.dataEncoding,
            paramsLocation: requestConfig.paramsLocation,
            credentials: credentials
        )
    }

    private class func setupRequestForOAuth(request: NSMutableURLRequest,
        additionalParameters: Dictionary<String, AnyObject>,
        dataEncoding: NSStringEncoding,
        paramsLocation : ParamsLocation = .AuthorizationHeader,
        credentials: OAuthSwiftCredential) throws -> NSMutableURLRequest {

            // TODO: I think there might be a bug in the handling of the additionalParameters!

            var signatureUrl = request.URL!
            var signatureParameters = additionalParameters
            let httpMethod = OAuthSwiftHTTPRequest.Method(rawValue: request.HTTPMethod)!

            // Check if body must be hashed (oauth1)
            let body: NSData? = nil
            if httpMethod.isBody {
                if let contentType = request.valueForHTTPHeaderField("Content-Type")?.lowercaseString {

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
            let urlComponents = NSURLComponents(URL: request.URL!, resolvingAgainstBaseURL: false )
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
                signatureUrl = urlComponents?.URL ?? request.URL!
            }
            signatureParameters = signatureParameters.join(queryStringParameters)

            switch paramsLocation {
            case .AuthorizationHeader:
                //Add oauth parameters in the Authorization header
                let authHeaders = credentials.makeHeaders(signatureUrl, method: httpMethod, parameters: signatureParameters, body: body)
                for (headerField, value) in authHeaders {
                    request.setValue(value, forHTTPHeaderField: headerField)
                }
            case .RequestURIQuery:
                //Add oauth parameters as request parameters
                let authParams = credentials.authorizationParametersWithSignatureForMethod(httpMethod, url: signatureUrl, parameters: signatureParameters, body: body)
                let authParamsString = authParams.urlEncodedQueryStringWithEncoding(dataEncoding)
                request.URL = request.URL!.URLByAppendingQueryString(authParamsString)
            }


            // Encode additionals params in the body or query string

            let charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(dataEncoding))

            // TODO: is this filtering still needed?
            let finalParameters : Dictionary<String, AnyObject>
            switch (paramsLocation) {
            case .AuthorizationHeader:
                finalParameters = additionalParameters.filter { key, _ in !key.hasPrefix("oauth_") }
            case .RequestURIQuery:
                finalParameters = additionalParameters
            }

            if finalParameters.count > 0 {
                if !httpMethod.isBody {
                    let queryString = finalParameters.urlEncodedQueryStringWithEncoding(dataEncoding)
                    request.URL = request.URL!.URLByAppendingQueryString(queryString)
                    if request.valueForHTTPHeaderField("Content-Type") == nil {
                        request.setValue("application/x-www-form-urlencoded; charset=\(charset)", forHTTPHeaderField: "Content-Type")
                    }
                }
                else {
                    if request.valueForHTTPHeaderField("Content-Type")?.rangeOfString("application/json") != nil {
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

            return request
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
