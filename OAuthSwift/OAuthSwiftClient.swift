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

    /// This handler gets called when the access token is successfully renewed via the tokenExpirationHandler.
    public var tokenRenewedHandler: OAuthSwift.TokenRenewedHandler?

    /// This handler gets called when the OAuth2 access token has expired and gives a chance to 
    /// refresh it. The request will be tried again if the completion is called without an error.
    /// Using OAuth2Swift will configure its client with a tokenExpirationHandler by default.
    public var tokenExpirationHandler: OAuthSwift.TokenExpirationHandler? {
        didSet {
            assert(
                (credential.version == .OAuth1 && tokenExpirationHandler == nil) || credential.version == .OAuth2,
                "OAuth1 does NOT have a token expiration process. Therefore you should NOT provide a tokenExpirationHandler for OAuth1."
            )
        }
    }

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
    public func get(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return request(urlString, method: .GET, parameters: parameters, headers: headers, success: success, failure: failure)
    }
    
    public func post(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return request(urlString, method: .POST, parameters: parameters, headers: headers, success: success, failure: failure)
    }

    public func put(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return request(urlString, method: .PUT, parameters: parameters, headers: headers,success: success, failure: failure)
    }

    public func delete(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return request(urlString, method: .DELETE, parameters: parameters, headers: headers,success: success, failure: failure)
    }

    public func patch(urlString: String, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return request(urlString, method: .PATCH, parameters: parameters, headers: headers,success: success, failure: failure)
    }
    
    public func request(urlString: String, method: OAuthSwiftHTTPRequest.Method, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil, checkTokenExpiration: Bool = true, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {

        guard let url = NSURL(string: urlString) else {
            failure?(error: NSError(domain: OAuthSwiftErrorDomain, code: OAuthSwiftErrorCode.RequestCreationError.rawValue, userInfo: nil))
            return nil
        }

        let reqConfig = OAuthSwiftHTTPRequestConfig(url: url, method: method, parameters: parameters, headers: headers ?? [:] )
        return request(reqConfig, checkTokenExpiration: checkTokenExpiration, success: success, failure: failure)
    }

    public func request(urlRequest: NSURLRequest, checkTokenExpiration: Bool = true, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        let reqConfig = OAuthSwiftHTTPRequestConfig(request: urlRequest, additionalParameters: [:])
        return request(reqConfig, checkTokenExpiration: checkTokenExpiration, success: success, failure: failure)
    }

    // This is the "base method" which all other request, get, post, put, delete and patch methods should call finally.
    public func request(reqConfig: OAuthSwiftHTTPRequestConfig, checkTokenExpiration: Bool = true, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        let req = OAuthSwiftTokenRefreshingRequest(credentials: credential, tokenExpirationHandler: tokenExpirationHandler, tokenRenewedHandler: tokenRenewedHandler,requestConfig: reqConfig)
        req.startRequest(checkTokenExpiration, success: success, failure: failure)
        return req
    }

    // MARK: multipart requests

    public func postImage(urlString: String, parameters: Dictionary<String, AnyObject>, image: NSData, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {

        guard let url = NSURL(string: urlString) else {
            failure?(error: NSError(domain: OAuthSwiftErrorDomain, code: OAuthSwiftErrorCode.RequestCreationError.rawValue, userInfo: nil))
            return nil
        }

        let requestConfig = OAuthSwiftHTTPRequestConfig(imageRequestWithURL: url, method: .POST, parameters: parameters, image: image)
        return request(requestConfig, success: success, failure: failure)
    }
    
    public func postMultiPartRequest(urlString: String, method: OAuthSwiftHTTPRequest.Method, parameters: Dictionary<String, AnyObject>, multiparts: Array<OAuthSwiftMultipartData> = [], checkTokenExpiration: Bool = true, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {

        guard let url = NSURL(string: urlString) else {
            failure?(error: NSError(domain: OAuthSwiftErrorDomain, code: OAuthSwiftErrorCode.RequestCreationError.rawValue, userInfo: nil))
            return nil
        }

        let requestConfig = OAuthSwiftHTTPRequestConfig(multipartRequestWithURL: url, method: method, parameters: parameters, multiparts: multiparts)
        return request(requestConfig, checkTokenExpiration: checkTokenExpiration, success: success, failure: failure)
    }

}

// MARK: deprecated

extension OAuthSwiftClient {

    @available(*, deprecated=0.6.0, message="Please create an OAuthSwiftHTTPRequestConfig object and pass it to the client or use the convenience methods on the client instead.")
    public func makeRequest(request: NSURLRequest) -> OAuthSwiftHTTPRequest {
        let reqConfig = OAuthSwiftHTTPRequestConfig(request: request, paramsLocation: self.paramsLocation)
        return OAuthSwiftHTTPRequest(requestConfig: reqConfig)
    }

    @available(*, deprecated=0.6.0, message="Please create an OAuthSwiftHTTPRequestConfig object and pass it to the client or use the convenience methods on the client instead.")
    public func makeRequest(urlString: String, method: OAuthSwiftHTTPRequest.Method, parameters: [String: AnyObject] = [:], headers: [String:String]? = nil) -> OAuthSwiftHTTPRequest? {
        guard let url = NSURL(string: urlString) else {
            return nil
        }

        let reqConfig = OAuthSwiftHTTPRequestConfig(url: url, method: method, parameters: parameters, headers: headers ?? [:], body: nil, paramsLocation: self.paramsLocation)
        return OAuthSwiftHTTPRequest(requestConfig: reqConfig)
    }
}
