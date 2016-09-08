//
//  OAuth1Swift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/22/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation


open class OAuth1Swift: OAuthSwift {

    // If your oauth provider doesn't provide `oauth_verifier`
    // set value to true (default: false)
    open var allowMissingOauthVerifier: Bool = false

    var consumer_key: String
    var consumer_secret: String
    var request_token_url: String
    var authorize_url: String
    var access_token_url: String
    
    // MARK: init
    public init(consumerKey: String, consumerSecret: String, requestTokenUrl: String, authorizeUrl: String, accessTokenUrl: String){
        self.consumer_key = consumerKey
        self.consumer_secret = consumerSecret
        self.request_token_url = requestTokenUrl
        self.authorize_url = authorizeUrl
        self.access_token_url = accessTokenUrl
        super.init(consumerKey: consumerKey, consumerSecret: consumerSecret)
        self.client.credential.version = .OAuth1
    }

    public convenience init?(parameters: [String:String]){
        guard let consumerKey = parameters["consumerKey"], let consumerSecret = parameters["consumerSecret"],
            let requestTokenUrl = parameters["requestTokenUrl"], let authorizeUrl = parameters["authorizeUrl"], let accessTokenUrl = parameters["accessTokenUrl"] else {
            return nil
        }
        self.init(consumerKey:consumerKey, consumerSecret: consumerSecret,
          requestTokenUrl: requestTokenUrl,
          authorizeUrl: authorizeUrl,
          accessTokenUrl: accessTokenUrl)
    }

    open var parameters: [String: String] {
        return [
            "consumerKey": consumer_key,
            "consumerSecret": consumer_secret,
            "requestTokenUrl": request_token_url,
            "authorizeUrl": authorize_url,
            "accessTokenUrl": access_token_url
        ]
    }

    // MARK: functions
    // 0. Start
    open func authorizeWithCallbackURL(_ callbackURL: URL, success: @escaping TokenSuccessHandler, failure: FailureHandler?) {
        self.postOAuthRequestTokenWithCallbackURL(callbackURL, success: { [unowned self]
            credential, response, _ in

            self.observeCallback { [unowned self] url in
                var responseParameters = [String: String]()
                if let query = url.query {
                    responseParameters += query.parametersFromQueryString()
                }
                if let fragment = url.fragment , !fragment.isEmpty {
                    responseParameters += fragment.parametersFromQueryString()
                }
                if let token = responseParameters["token"] {
                    responseParameters["oauth_token"] = token
                }
                if (responseParameters["oauth_token"] != nil && (self.allowMissingOauthVerifier || responseParameters["oauth_verifier"] != nil)) {
                    //var credential: OAuthSwiftCredential = self.client.credential
                    self.client.credential.oauth_token = responseParameters["oauth_token"]!.safeStringByRemovingPercentEncoding
                    if (responseParameters["oauth_verifier"] != nil) {
                        self.client.credential.oauth_verifier = responseParameters["oauth_verifier"]!.safeStringByRemovingPercentEncoding
                    }
                    self.postOAuthAccessTokenWithRequestToken(success, failure: failure)
                } else {
                    let userInfo = [NSLocalizedDescriptionKey: "Oauth problem. oauth_token or oauth_verifier not returned"]
                    failure?(NSError(domain: OAuthSwiftErrorDomain, code: -1, userInfo: userInfo))
                    return
                }
            }
            // 2. Authorize
            let urlString = self.authorize_url + (self.authorize_url.has("?") ? "&" : "?") + "oauth_token=\(credential.oauth_token.urlQueryEncoded!)"
            if let queryURL = URL(string: urlString) {
                self.authorize_url_handler.handle(queryURL)
            }
            else {
                let errorInfo = [NSLocalizedFailureReasonErrorKey: NSLocalizedString("Failed to create URL", comment: "\(urlString) not convertible to URL, please encode.")]
                failure?(NSError(domain: OAuthSwiftErrorDomain, code: -1, userInfo: errorInfo))
            }
        }, failure: failure)
    }

    // 1. Request token
    func postOAuthRequestTokenWithCallbackURL(_ callbackURL: URL, success: @escaping TokenSuccessHandler, failure: FailureHandler?) {
        var parameters =  Dictionary<String, Any>()
        parameters["oauth_callback"] = callbackURL.absoluteString
        let _ = self.client.post(self.request_token_url, parameters: parameters, success: {
            data, response in
            let responseString = String(data: data, encoding: String.Encoding.utf8)!
            let parameters = responseString.parametersFromQueryString()
            if let oauthToken=parameters["oauth_token"] {
                self.client.credential.oauth_token = oauthToken.safeStringByRemovingPercentEncoding
            }
            if let oauthTokenSecret=parameters["oauth_token_secret"] {
                self.client.credential.oauth_token_secret = oauthTokenSecret.safeStringByRemovingPercentEncoding
            }
            success(self.client.credential, response, parameters as [String: Any])
        }, failure: failure)
    }

    // 3. Get Access token
    func postOAuthAccessTokenWithRequestToken(_ success: @escaping TokenSuccessHandler, failure: FailureHandler?) {
        var parameters = Dictionary<String, Any>()
        parameters["oauth_token"] = self.client.credential.oauth_token
        parameters["oauth_verifier"] = self.client.credential.oauth_verifier
        let _ = self.client.post(self.access_token_url, parameters: parameters, success: {
            data, response in
            let responseString = String(data: data, encoding: String.Encoding.utf8)!
            let parameters = responseString.parametersFromQueryString()
            if let oauthToken=parameters["oauth_token"] {
                self.client.credential.oauth_token = oauthToken.safeStringByRemovingPercentEncoding
            }
            if let oauthTokenSecret=parameters["oauth_token_secret"] {
                self.client.credential.oauth_token_secret = oauthTokenSecret.safeStringByRemovingPercentEncoding
            }
            success(self.client.credential, response, parameters as [String: Any])
        }, failure: failure)
    }

    @available(*, deprecated:0.5.0, message:"Use OAuthSwift.handleOpenURL()")
    open override class func handleOpenURL(_ url: URL) {
       super.handleOpenURL(url)
    }

}
