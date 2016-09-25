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
    // set this value to true (default: false)
    open var allowMissingOAuthVerifier: Bool = false

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
        self.client.credential.version = .oauth1
    }

    public convenience init?(parameters: ConfigParameters){
        guard let consumerKey = parameters["consumerKey"], let consumerSecret = parameters["consumerSecret"],
            let requestTokenUrl = parameters["requestTokenUrl"], let authorizeUrl = parameters["authorizeUrl"], let accessTokenUrl = parameters["accessTokenUrl"] else {
            return nil
        }
        self.init(consumerKey:consumerKey, consumerSecret: consumerSecret,
          requestTokenUrl: requestTokenUrl,
          authorizeUrl: authorizeUrl,
          accessTokenUrl: accessTokenUrl)
    }

    open var parameters: ConfigParameters {
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
    open func authorize(withCallbackURL callbackURL: URL, success: @escaping TokenSuccessHandler, failure: FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.postOAuthRequestToken(callbackURL: callbackURL, success: { [unowned self]
            credential, response, _ in

            self.observeCallback { [weak self] url in
                guard let this = self else { OAuthSwift.retainError(failure); return }
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
 
                if let token = responseParameters["oauth_token"] {
                    this.client.credential.oauth_token = token.safeStringByRemovingPercentEncoding
                    if let oauth_verifier = responseParameters["oauth_verifier"] {
                        this.client.credential.oauth_verifier = oauth_verifier.safeStringByRemovingPercentEncoding
                    } else {
                        if !this.allowMissingOAuthVerifier {
                            failure?(OAuthSwiftError.configurationError(message: "Missing oauth_verifier. Maybe use allowMissingOAuthVerifier=true"))
                            return
                        }
                    }
                    let _ = this.postOAuthAccessTokenWithRequestToken(success: success, failure: failure)
                    // TODO CANCEL REQUEST keep the returned handle into a list for cancel
                } else {
                    failure?(OAuthSwiftError.missingToken)
                    return
                }
            }
            // 2. Authorize
            let urlString = self.authorize_url + (self.authorize_url.has("?") ? "&" : "?")
            if let token = credential.oauth_token.urlQueryEncoded, let queryURL = URL(string: urlString + "oauth_token=\(token)") {
                self.authorizeURLHandler.handle(queryURL)
            }
            else {
                failure?(OAuthSwiftError.encodingError(urlString: urlString))
            }
        }, failure: failure)
    }

    open func authorize(withCallbackURL urlString: String, success: @escaping TokenSuccessHandler, failure: FailureHandler?) -> OAuthSwiftRequestHandle? {
        guard let url = URL(string: urlString) else {
              failure?(OAuthSwiftError.encodingError(urlString: urlString))
            return nil
        }
        return authorize(withCallbackURL: url, success: success, failure: failure)
    }

    // 1. Request token
    func postOAuthRequestToken(callbackURL: URL, success: @escaping TokenSuccessHandler, failure: FailureHandler?) -> OAuthSwiftRequestHandle? {
        var parameters =  Dictionary<String, Any>()
        parameters["oauth_callback"] = callbackURL.absoluteString
        return self.client.post(
            self.request_token_url, parameters: parameters,
            success: { [weak self] data, response in
                guard let this = self else { OAuthSwift.retainError(failure); return }
                let responseString = String(data: data, encoding: String.Encoding.utf8)!
                let parameters = responseString.parametersFromQueryString()
                if let oauthToken=parameters["oauth_token"] {
                    this.client.credential.oauth_token = oauthToken.safeStringByRemovingPercentEncoding
                }
                if let oauthTokenSecret=parameters["oauth_token_secret"] {
                    this.client.credential.oauth_token_secret = oauthTokenSecret.safeStringByRemovingPercentEncoding
                }
                success(this.client.credential, response, parameters)
            }, failure: failure
        )
    }

    // 3. Get Access token
    func postOAuthAccessTokenWithRequestToken(success: @escaping TokenSuccessHandler, failure: FailureHandler?) -> OAuthSwiftRequestHandle? {
        var parameters = Dictionary<String, Any>()
        parameters["oauth_token"] = self.client.credential.oauth_token
        parameters["oauth_verifier"] = self.client.credential.oauth_verifier
        return self.client.post(
            self.access_token_url, parameters: parameters,
            success: { [weak self] data, response in
                guard let this = self else { OAuthSwift.retainError(failure); return }
                let responseString = String(data: data, encoding: String.Encoding.utf8)!
                let parameters = responseString.parametersFromQueryString()
                if let oauthToken=parameters["oauth_token"] {
                    this.client.credential.oauth_token = oauthToken.safeStringByRemovingPercentEncoding
                }
                if let oauthTokenSecret=parameters["oauth_token_secret"] {
                    this.client.credential.oauth_token_secret = oauthTokenSecret.safeStringByRemovingPercentEncoding
                }
                success(this.client.credential, response, parameters)
            }, failure: failure
        )
    }
    
}
