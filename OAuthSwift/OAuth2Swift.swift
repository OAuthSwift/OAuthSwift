//
//  OAuth2Swift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/22/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

public class OAuth2Swift: OAuthSwift {

    // If your oauth provider need to use basic authentification
    // set value to true (default: false)
    public var accessTokenBasicAuthentification = false

    // Set to true to deactivate state check. Be careful of CSRF
    public var allowMissingStateCheck: Bool = false

    var consumer_key: String
    var consumer_secret: String
    var authorize_url: String
    var access_token_url: String?
    var response_type: String
    var content_type: String?
    
    // MARK: init
    public convenience init(consumerKey: String, consumerSecret: String, authorizeUrl: String, accessTokenUrl: String, responseType: String){
        self.init(consumerKey: consumerKey, consumerSecret: consumerSecret, authorizeUrl: authorizeUrl, responseType: responseType)
        self.access_token_url = accessTokenUrl
    }

    public convenience init(consumerKey: String, consumerSecret: String, authorizeUrl: String, accessTokenUrl: String, responseType: String, contentType: String){
        self.init(consumerKey: consumerKey, consumerSecret: consumerSecret, authorizeUrl: authorizeUrl, responseType: responseType)
        self.access_token_url = accessTokenUrl
        self.content_type = contentType
    }

    public init(consumerKey: String, consumerSecret: String, authorizeUrl: String, responseType: String){
        self.consumer_key = consumerKey
        self.consumer_secret = consumerSecret
        self.authorize_url = authorizeUrl
        self.response_type = responseType
        super.init(consumerKey: consumerKey, consumerSecret: consumerSecret)
        self.client.credential.version = .OAuth2
    }
    
    public convenience init?(parameters: [String:String]){
        guard let consumerKey = parameters["consumerKey"], consumerSecret = parameters["consumerSecret"],
            responseType = parameters["responseType"], authorizeUrl = parameters["authorizeUrl"] else {
                return nil
        }
        if let accessTokenUrl = parameters["accessTokenUrl"] {
            self.init(consumerKey:consumerKey, consumerSecret: consumerSecret,
                authorizeUrl: authorizeUrl, accessTokenUrl: accessTokenUrl, responseType: responseType)
        } else {
            self.init(consumerKey:consumerKey, consumerSecret: consumerSecret,
                authorizeUrl: authorizeUrl, responseType: responseType)
        }
    }

    // MARK: functions
    public func authorizeWithCallbackURL(callbackURL: NSURL, scope: String, state: String, params: [String: String] = [String: String](), success: TokenSuccessHandler, failure: ((error: NSError) -> Void)) {
        
         self.observeCallback { [unowned self] url in
            var responseParameters = [String: String]()
            if let query = url.query {
                responseParameters += query.parametersFromQueryString()
            }
            if let fragment = url.fragment where !fragment.isEmpty {
                responseParameters += fragment.parametersFromQueryString()
            }
            if let accessToken = responseParameters["access_token"] {
                self.client.credential.oauth_token = accessToken.safeStringByRemovingPercentEncoding
                success(credential: self.client.credential, response: nil, parameters: responseParameters)
            }
            else if let code = responseParameters["code"] {
                if !self.allowMissingStateCheck {
                    guard let responseState = responseParameters["state"] else {
                        let errorInfo = [NSLocalizedDescriptionKey: "Missing state"]
                        failure(error: NSError(domain: OAuthSwiftErrorDomain, code: -1, userInfo: errorInfo))
                        return
                    }
                    if responseState != state {
                        let errorInfo = [NSLocalizedDescriptionKey: "state not equals"]
                        failure(error: NSError(domain: OAuthSwiftErrorDomain, code: -1, userInfo: errorInfo))
                        return
                    }
                }
                self.postOAuthAccessTokenWithRequestTokenByCode(code.safeStringByRemovingPercentEncoding,
                    callbackURL:callbackURL, success: success, failure: failure)
            }
            else if let error = responseParameters["error"], error_description = responseParameters["error_description"] {
                let errorInfo = [NSLocalizedFailureReasonErrorKey: NSLocalizedString(error, comment: error_description)]
                failure(error: NSError(domain: OAuthSwiftErrorDomain, code: -1, userInfo: errorInfo))
            }
            else {
                let errorInfo = [NSLocalizedDescriptionKey: "No access_token, no code and no error provided by server"]
                failure(error: NSError(domain: OAuthSwiftErrorDomain, code: -1, userInfo: errorInfo))
            }
        }

        
        var queryString = "client_id=\(self.consumer_key)"
        queryString += "&redirect_uri=\(callbackURL.absoluteString)"
        queryString += "&response_type=\(self.response_type)"
        if !scope.isEmpty {
            queryString += "&scope=\(scope)"
        }
        if !state.isEmpty {
            queryString += "&state=\(state)"
        }
        for param in params {
            queryString += "&\(param.0)=\(param.1)"
        }
        
        var urlString = self.authorize_url
        urlString += (self.authorize_url.has("?") ? "&" : "?")
        
        if let encodedQuery = queryString.urlQueryEncoded, queryURL = NSURL(string: urlString + encodedQuery) {
            self.authorize_url_handler.handle(queryURL)
        }
        else {
            let errorInfo = [NSLocalizedFailureReasonErrorKey: NSLocalizedString("Failed to create URL", comment: "\(urlString) or \(queryString) not convertible to URL, please check encoding")]
            failure(error: NSError(domain: OAuthSwiftErrorDomain, code: -1, userInfo: errorInfo))
        }
    }
    
    func postOAuthAccessTokenWithRequestTokenByCode(code: String, callbackURL: NSURL, success: TokenSuccessHandler, failure: FailureHandler?) {
        var parameters = Dictionary<String, AnyObject>()
        parameters["client_id"] = self.consumer_key
        parameters["client_secret"] = self.consumer_secret
        parameters["code"] = code
        parameters["grant_type"] = "authorization_code"
        parameters["redirect_uri"] = callbackURL.absoluteString.safeStringByRemovingPercentEncoding

        let successHandler: OAuthSwiftHTTPRequest.SuccessHandler = { [unowned self]
            data, response in
            let responseJSON: AnyObject? = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)
            
            let responseParameters: [String:String]
            
            if let jsonDico = responseJSON as? [String:AnyObject] {
                responseParameters = jsonDico.map { (key, value) in (key, String(value)) }
            } else {
                let responseString = NSString(data: data, encoding: NSUTF8StringEncoding) as String!
                responseParameters = responseString.parametersFromQueryString()
            }
            
            guard let accessToken = responseParameters["access_token"] else {
                if let failure = failure {
                    let errorInfo = [NSLocalizedFailureReasonErrorKey: NSLocalizedString("Could not get Access Token", comment: "Due to an error in the OAuth2 process, we couldn't get a valid token.")]
                    failure(error: NSError(domain: OAuthSwiftErrorDomain, code: -1, userInfo: errorInfo))
                }
                return
            }
            self.client.credential.oauth_token = accessToken.safeStringByRemovingPercentEncoding
            success(credential: self.client.credential, response: response, parameters: responseParameters)
        }

        if self.content_type == "multipart/form-data" {
            self.client.postMultiPartRequest(self.access_token_url!, method: .POST, parameters: parameters, success: successHandler, failure: failure)
        } else {
            // special headers
            var headers: [String:String]? = nil
            if accessTokenBasicAuthentification {
                let authentification = "\(self.consumer_key):\(self.consumer_secret)".dataUsingEncoding(NSUTF8StringEncoding)
                if let base64Encoded = authentification?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
                {
                    headers = ["Authorization": "Basic \(base64Encoded)"]
                }
            }
            if let access_token_url = access_token_url {
                self.client.request(access_token_url, method: .POST, parameters: parameters, headers: headers, success: successHandler, failure: failure)
            }
            else {
                let errorInfo = [NSLocalizedFailureReasonErrorKey: NSLocalizedString("access token url not defined", comment: "access token url not defined with code type auth")]
                failure?(error: NSError(domain: OAuthSwiftErrorDomain, code: -1, userInfo: errorInfo))
            }
        }
    }
    
    @available(*, deprecated=0.5.0, message="Use OAuthSwift.handleOpenURL()")
    public override class func handleOpenURL(url: NSURL) {
        super.handleOpenURL(url)
    }

}
