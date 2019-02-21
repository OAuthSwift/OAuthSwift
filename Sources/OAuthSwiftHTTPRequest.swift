//
//  OAuthSwiftHTTPRequest.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

let kHTTPHeaderContentType = "Content-Type"

open class OAuthSwiftHTTPRequest: NSObject, OAuthSwiftRequestHandle {

    public typealias SuccessHandler = (_ response: OAuthSwiftResponse) -> Void
    public typealias FailureHandler = (_ error: OAuthSwiftError) -> Void

    /// HTTP request method
    /// https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol#Request_methods
    public enum Method: String {
        case GET, POST, PUT, DELETE, PATCH, HEAD //, OPTIONS, TRACE, CONNECT

        var isBody: Bool {
            return self == .POST || self == .PUT || self == .PATCH
        }
    }

    /// Where the additional parameters will be injected
    @objc public enum ParamsLocation: Int {
        case authorizationHeader, /*FormEncodedBody,*/ requestURIQuery
    }

    public var config: Config

    private var request: URLRequest?
    private var task: URLSessionTask?
    private var session: URLSession!

    fileprivate var cancelRequested = false

    public static var executionContext: (@escaping () -> Void) -> Void = { block in
        return DispatchQueue.main.async(execute: block)
    }

    // MARK: INIT

    convenience init(url: URL, method: Method = .GET, parameters: OAuthSwift.Parameters = [:], paramsLocation: ParamsLocation = .authorizationHeader, httpBody: Data? = nil, headers: OAuthSwift.Headers = [:], sessionFactory: URLSessionFactory = .default) {
        self.init(config: Config(url: url, httpMethod: method, httpBody: httpBody, headers: headers, parameters: parameters, paramsLocation: paramsLocation, sessionFactory: sessionFactory))
    }

    convenience init(request: URLRequest, paramsLocation: ParamsLocation = .authorizationHeader, sessionFactory: URLSessionFactory = .default) {
        self.init(config: Config(urlRequest: request, paramsLocation: paramsLocation, sessionFactory: sessionFactory))
    }

    init(config: Config) {
        self.config = config
    }

    /// START request
    func start(success: SuccessHandler?, failure: FailureHandler?) {
        guard request == nil else { return } // Don't start the same request twice!

        let successHandler = success
        let failureHandler = failure

        do {
            self.request = try self.makeRequest()
        } catch let error as NSError {
            failureHandler?(OAuthSwiftError.requestCreation(message: error.localizedDescription))
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

            self.session = self.config.sessionFactory.build()
            let usedRequest = self.request!

            if self.config.sessionFactory.useDataTaskClosure {
                let completionHandler: (Data?, URLResponse?, Error?) -> Void = { data, resp, error in
                    OAuthSwiftHTTPRequest.completionHandler(successHandler: success,
                                                            failureHandler: failure,
                                                            request: usedRequest,
                                                            data: data,
                                                            resp: resp,
                                                            error: error)
                }
                self.task = self.session.dataTask(with: usedRequest, completionHandler: completionHandler)
            } else {
                self.task = self.session.dataTask(with: usedRequest)
            }

            self.task?.resume()
            self.session.finishTasksAndInvalidate()

            #if os(iOS)
                #if !OAUTH_APP_EXTENSIONS
                    UIApplication.shared.isNetworkActivityIndicatorVisible = self.config.sessionFactory.isNetworkActivityIndicatorVisible
                #endif
            #endif
        }
    }

    /// Function called when receiving data from server.
    public static func completionHandler(successHandler: SuccessHandler?, failureHandler: FailureHandler?, request: URLRequest, data: Data?, resp: URLResponse?, error: Error?) {
        #if os(iOS)
        #if !OAUTH_APP_EXTENSIONS
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        #endif
        #endif

        // MARK: failure error returned by server
        if let error = error {
            var oauthError: OAuthSwiftError = .requestError(error: error, request: request)
            let nsError = error as NSError
            if nsError.code == NSURLErrorCancelled {
                oauthError = .cancelled
            } else if nsError.isExpiredToken {
                oauthError = .tokenExpired(error: error)
            }

            failureHandler?(oauthError)
            return
        }

        // MARK: failure no response or data returned by server
        guard let response = resp as? HTTPURLResponse, let responseData = data else {
            let badRequestCode = 400
            let localizedDescription = OAuthSwiftHTTPRequest.descriptionForHTTPStatus(badRequestCode, responseString: "")
            var userInfo: [String: Any] = [
                NSLocalizedDescriptionKey: localizedDescription
            ]
            if let response = resp { // there is only no data
                userInfo[OAuthSwiftError.ResponseKey] = response
            }
            if let response = resp as? HTTPURLResponse {
                userInfo["Response-Headers"] = response.allHeaderFields
            }
            let error = NSError(domain: OAuthSwiftError.Domain, code: badRequestCode, userInfo: userInfo)
            failureHandler?(.requestError(error:error, request: request))
            return
        }

        // MARK: failure code > 400
        guard response.statusCode < 400 else {
            var localizedDescription = ""
            let responseString = String(data: responseData, encoding: OAuthSwiftDataEncoding)

            // Try to get error information from data as json
            let responseJSON = try? JSONSerialization.jsonObject(with: responseData, options: .mutableContainers)
            var errorCode: String?
            if let responseJSON = responseJSON as? OAuthSwift.Parameters {
                if let code = responseJSON["error"] as? String {
                    errorCode = code
                    if  let description = responseJSON["error_description"] as? String {
                        localizedDescription = NSLocalizedString("\(code) \(description)", comment: "")
                    } else {
                        localizedDescription = NSLocalizedString("\(code)", comment: "")
                    }
                }
            } else {
                localizedDescription = OAuthSwiftHTTPRequest.descriptionForHTTPStatus(response.statusCode, responseString: String(data: responseData, encoding: OAuthSwiftDataEncoding)!)
            }

            var userInfo: [String: Any] = [
                NSLocalizedDescriptionKey: localizedDescription,
                "Response-Headers": response.allHeaderFields,
                OAuthSwiftError.ResponseKey: response,
                OAuthSwiftError.ResponseDataKey: responseData
            ]
            if let string = responseString {
                userInfo["Response-Body"] = string
            }
            if let urlString = response.url?.absoluteString {
                userInfo[NSURLErrorFailingURLErrorKey] = urlString
            }

            let error = NSError(domain: NSURLErrorDomain, code: response.statusCode, userInfo: userInfo)
            if error.isExpiredToken {
                failureHandler?(.tokenExpired(error: error))
            } else if errorCode == "authorization_pending" {
                failureHandler?(.authorizationPending(error: error, request: request))
            } else if errorCode == "slow_down" {
                failureHandler?(.slowDown(error: error, request: request))
            } else if errorCode == "access_denied" {
                failureHandler?(.accessDenied(error: error, request: request))
            } else {
                failureHandler?(.requestError(error: error, request: request))
            }
            return
        }

        // MARK: success
        successHandler?(OAuthSwiftResponse(data: responseData, response: response, request: request))
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

    open func makeRequest() throws -> URLRequest {
        return try OAuthSwiftHTTPRequest.makeRequest(config: self.config)
    }

    open class func makeRequest(config: Config) throws -> URLRequest {
        var request = config.urlRequest
        return try setupRequestForOAuth(request: &request,
                                        parameters: config.parameters,
                                        dataEncoding: config.dataEncoding,
                                        paramsLocation: config.paramsLocation
        )
    }

    open class func makeRequest(
        url: Foundation.URL,
        method: Method,
        headers: OAuthSwift.Headers,
        parameters: OAuthSwift.Parameters,
        dataEncoding: String.Encoding,
        body: Data? = nil,
        paramsLocation: ParamsLocation = .authorizationHeader) throws -> URLRequest {

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return try setupRequestForOAuth(
            request: &request,
            parameters: parameters,
            dataEncoding: dataEncoding,
            body: body,
            paramsLocation: paramsLocation
        )
    }

    open class func setupRequestForOAuth(
        request: inout URLRequest,
        parameters: OAuthSwift.Parameters,
        dataEncoding: String.Encoding = OAuthSwiftDataEncoding,
        body: Data? = nil,
        paramsLocation: ParamsLocation = .authorizationHeader) throws -> URLRequest {

        let finalParameters: OAuthSwift.Parameters
        switch paramsLocation {
        case .authorizationHeader:
            finalParameters = parameters.filter { key, _ in !key.hasPrefix("oauth_") }
        case .requestURIQuery:
            finalParameters = parameters
        }

        if let b = body {
            request.httpBody = b
        } else {
            if !finalParameters.isEmpty {
                let charset = dataEncoding.charset
                let headers = request.allHTTPHeaderFields ?? [:]
                if request.httpMethod == "GET" || request.httpMethod == "HEAD" || request.httpMethod == "DELETE" {
                    let queryString = finalParameters.urlEncodedQuery
                    let url = request.url!
                    request.url = url.urlByAppending(queryString: queryString)
                    if headers[kHTTPHeaderContentType] == nil {
                        request.setValue("application/x-www-form-urlencoded; charset=\(charset)", forHTTPHeaderField: kHTTPHeaderContentType)
                    }
                } else {
                    if let contentType = headers[kHTTPHeaderContentType], contentType.contains("application/json") {
                        let jsonData = try JSONSerialization.data(withJSONObject: finalParameters, options: [])
                        request.setValue("application/json; charset=\(charset)", forHTTPHeaderField: kHTTPHeaderContentType)
                        request.httpBody = jsonData
                    } else if let contentType = headers[kHTTPHeaderContentType], contentType.contains("multipart/form-data") {
                    // snip
                    } else {
                        request.setValue("application/x-www-form-urlencoded; charset=\(charset)", forHTTPHeaderField: kHTTPHeaderContentType)
                        let queryString = finalParameters.urlEncodedQuery
                        request.httpBody = queryString.data(using: dataEncoding, allowLossyConversion: true)
                    }
                }
            }
        }
        return request
    }

}

// MARK: - Request configuraiton
extension OAuthSwiftHTTPRequest {

    /// Configuration for request
    public struct Config {

        /// URLRequest (url, method, ...)
        public var urlRequest: URLRequest
        /// These parameters are either added to the query string for GET, HEAD and DELETE requests or
        /// used as the http body in case of POST, PUT or PATCH requests.
        ///
        /// If used in the body they are either encoded as JSON or as encoded plaintext based on the Content-Type header field.
        public var parameters: OAuthSwift.Parameters
        public let paramsLocation: ParamsLocation
        public let dataEncoding: String.Encoding
        public let sessionFactory: URLSessionFactory

        /// Shortcut
        public var httpMethod: Method {
            if let requestMethod = urlRequest.httpMethod {
                return Method(rawValue: requestMethod) ?? .GET
            }
            return .GET
        }

        public var url: Foundation.URL? {
            return urlRequest.url
        }

        // MARK: init
        public init(url: URL, httpMethod: Method = .GET, httpBody: Data? = nil, headers: OAuthSwift.Headers = [:], timeoutInterval: TimeInterval = 60, httpShouldHandleCookies: Bool = false, parameters: OAuthSwift.Parameters, paramsLocation: ParamsLocation = .authorizationHeader, dataEncoding: String.Encoding = OAuthSwiftDataEncoding, sessionFactory: URLSessionFactory = .default) {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = httpMethod.rawValue
            urlRequest.httpBody = httpBody
            urlRequest.allHTTPHeaderFields = headers
            urlRequest.timeoutInterval = timeoutInterval
            urlRequest.httpShouldHandleCookies = httpShouldHandleCookies
            self.init(urlRequest: urlRequest, parameters: parameters, paramsLocation: paramsLocation, dataEncoding: dataEncoding, sessionFactory: sessionFactory)
        }

        public init(urlRequest: URLRequest, parameters: OAuthSwift.Parameters = [:], paramsLocation: ParamsLocation = .authorizationHeader, dataEncoding: String.Encoding = OAuthSwiftDataEncoding, sessionFactory: URLSessionFactory = .default) {
            self.urlRequest = urlRequest
            self.parameters = parameters
            self.paramsLocation = paramsLocation
            self.dataEncoding = dataEncoding
            self.sessionFactory = sessionFactory
        }

        /// Modify request with authentification
        public mutating func updateRequest(credential: OAuthSwiftCredential) {
            let method = self.httpMethod
            let url = self.urlRequest.url!
            let headers: OAuthSwift.Headers = self.urlRequest.allHTTPHeaderFields ?? [:]
            let paramsLocation = self.paramsLocation
            let parameters = self.parameters

            var signatureUrl = url
            var signatureParameters = parameters

            // Check if body must be hashed (oauth1)
            let body: Data? = nil
            if method.isBody {
                if let contentType = headers[kHTTPHeaderContentType]?.lowercased() {

                    if contentType.contains("application/json") {
                        // TODO: oauth_body_hash create body before signing if implementing body hashing
                        /*do {
                         let jsonData: Data = try JSONSerialization.jsonObject(parameters, options: [])
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

            var queryStringParameters = OAuthSwift.Parameters()
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false )
            if let queryItems = urlComponents?.queryItems {
                for queryItem in queryItems {
                    let value = queryItem.value?.safeStringByRemovingPercentEncoding ?? ""
                    queryStringParameters.updateValue(value, forKey: queryItem.name)
                }
            }

            // According to the OAuth1.0a spec, the url used for signing is ONLY scheme, path, and query
            if !queryStringParameters.isEmpty {
                urlComponents?.query = nil
                // This is safe to unwrap because these just came from an NSURL
                signatureUrl = urlComponents?.url ?? url
            }
            signatureParameters = signatureParameters.join(queryStringParameters)

            var requestHeaders = OAuthSwift.Headers()
            switch paramsLocation {
            case .authorizationHeader:
                //Add oauth parameters in the Authorization header
                requestHeaders += credential.makeHeaders(signatureUrl, method: method, parameters: signatureParameters, body: body)
            case .requestURIQuery:
                //Add oauth parameters as request parameters
                self.parameters += credential.authorizationParametersWithSignature(method: method, url: signatureUrl, parameters: signatureParameters, body: body)
            }

            self.urlRequest.allHTTPHeaderFields = requestHeaders + headers
        }

    }
}

// MARK: - session configuration

/// configure how URLSession is initialized
public struct URLSessionFactory {

    public static let `default` = URLSessionFactory()

    public var configuration = URLSessionConfiguration.default
    public var queue = OperationQueue.main
    /// An optional delegate for the URLSession
    public weak var delegate: URLSessionDelegate?

    /// Monitor session: see UIApplication.shared.isNetworkActivityIndicatorVisible
    public var isNetworkActivityIndicatorVisible = true

    /// By default use a closure to receive data from server.
    /// If you set to false, you must in `delegate` take care of server response.
    /// and maybe call in delegate `OAuthSwiftHTTPRequest.completionHandler`
    public var useDataTaskClosure = true

    /// Create a new URLSession
    func build() -> URLSession {
        return URLSession(configuration: self.configuration, delegate: self.delegate, delegateQueue: self.queue)
    }
}

// MARK: - status code mapping

extension OAuthSwiftHTTPRequest {

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

        if description != nil {
            s += ": " + description! + ", Response: " + responseString
        }

        return s
    }

}
