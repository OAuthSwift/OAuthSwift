//
//  OAuth1Swift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/22/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

open class OAuth1Swift: OAuthSwift {

    /// If your oauth provider doesn't provide `oauth_verifier`
    // set this value to true (default: false)
    open var allowMissingOAuthVerifier: Bool = false

    /// Optionally add callback URL to authorize Url (default: false)
    open var addCallbackURLToAuthorizeURL: Bool = false

    var consumerKey: String
    var consumerSecret: String
    var requestTokenUrl: String
    var authorizeUrl: String
    var accessTokenUrl: String

    // MARK: init
    public init(consumerKey: String, consumerSecret: String, requestTokenUrl: String, authorizeUrl: String, accessTokenUrl: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.requestTokenUrl = requestTokenUrl
        self.authorizeUrl = authorizeUrl
        self.accessTokenUrl = accessTokenUrl
        super.init(consumerKey: consumerKey, consumerSecret: consumerSecret)
        self.client.credential.version = .oauth1
    }

    public convenience override init(consumerKey: String, consumerSecret: String) {
        self.init(consumerKey: consumerKey, consumerSecret: consumerSecret, requestTokenUrl: "", authorizeUrl: "", accessTokenUrl: "")
    }

    public convenience init?(parameters: ConfigParameters) {
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
            "consumerKey": consumerKey,
            "consumerSecret": consumerSecret,
            "requestTokenUrl": requestTokenUrl,
            "authorizeUrl": authorizeUrl,
            "accessTokenUrl": accessTokenUrl
        ]
    }

    // MARK: functions
    // 0. Start
    @discardableResult
    open func authorize(withCallbackURL callbackURL: URL, success: @escaping TokenSuccessHandler, failure: FailureHandler?) -> OAuthSwiftRequestHandle? {

        self.postOAuthRequestToken(callbackURL: callbackURL, success: { [unowned self] credential, _, _ in

            self.observeCallback { [weak self] url in
                guard let this = self else { OAuthSwift.retainError(failure); return }
                var responseParameters = [String: String]()
                if let query = url.query {
                    responseParameters += query.parametersFromQueryString
                }
                if let fragment = url.fragment, !fragment.isEmpty {
                    responseParameters += fragment.parametersFromQueryString
                }
                if let token = responseParameters["token"] {
                    responseParameters["oauth_token"] = token
                }

                if let token = responseParameters["oauth_token"] {
                    this.client.credential.oauthToken = token.safeStringByRemovingPercentEncoding
                    if let oauth_verifier = responseParameters["oauth_verifier"] {
                        this.client.credential.oauthVerifier = oauth_verifier.safeStringByRemovingPercentEncoding
                    } else {
                        if !this.allowMissingOAuthVerifier {
                            failure?(OAuthSwiftError.configurationError(message: "Missing oauth_verifier. Maybe use allowMissingOAuthVerifier=true"))
                            return
                        }
                    }
                    this.postOAuthAccessTokenWithRequestToken(success: success, failure: failure)
                } else {
                    failure?(OAuthSwiftError.missingToken)
                    return
                }
            }
            // 2. Authorize
            if let token = credential.oauthToken.urlQueryEncoded {
                var urlString = self.authorizeUrl + (self.authorizeUrl.contains("?") ? "&" : "?")
                urlString += "oauth_token=\(token)"
                if self.addCallbackURLToAuthorizeURL {
                    urlString += "&oauth_callback=\(callbackURL.absoluteString)"
                }
                if let queryURL = URL(string: urlString) {
                    self.authorizeURLHandler.handle(queryURL)
                } else {
                    failure?(OAuthSwiftError.encodingError(urlString: urlString))
                }
            } else {
                failure?(OAuthSwiftError.encodingError(urlString: credential.oauthToken)) //TODO specific error
            }

        }, failure: failure)

        return self
    }

    @discardableResult
    open func authorize(withCallbackURL urlString: String, success: @escaping TokenSuccessHandler, failure: FailureHandler?) -> OAuthSwiftRequestHandle? {
        guard let url = URL(string: urlString) else {
              failure?(OAuthSwiftError.encodingError(urlString: urlString))
            return nil
        }
        return authorize(withCallbackURL: url, success: success, failure: failure)
    }

    // 1. Request token
    func postOAuthRequestToken(callbackURL: URL, success: @escaping TokenSuccessHandler, failure: FailureHandler?) {
        var parameters = [String: Any]()
        parameters["oauth_callback"] = callbackURL.absoluteString

        if let handle = self.client.post(
            self.requestTokenUrl, parameters: parameters,
            success: { [weak self] response in
                guard let this = self else { OAuthSwift.retainError(failure); return }
                let parameters = response.string?.parametersFromQueryString ?? [:]
                if let oauthToken = parameters["oauth_token"] {
                    this.client.credential.oauthToken = oauthToken.safeStringByRemovingPercentEncoding
                }
                if let oauthTokenSecret=parameters["oauth_token_secret"] {
                    this.client.credential.oauthTokenSecret = oauthTokenSecret.safeStringByRemovingPercentEncoding
                }
                success(this.client.credential, response, parameters)
            }, failure: failure
            ) {
            self.putHandle(handle, withKey: UUID().uuidString)
        }
    }

    // 3. Get Access token
    func postOAuthAccessTokenWithRequestToken(success: @escaping TokenSuccessHandler, failure: FailureHandler?) {
        var parameters = [String: Any]()
        parameters["oauth_token"] = self.client.credential.oauthToken
        if !self.allowMissingOAuthVerifier {
            parameters["oauth_verifier"] = self.client.credential.oauthVerifier
        }

        if let handle = self.client.post(
            self.accessTokenUrl, parameters: parameters,
            success: { [weak self] response in
                guard let this = self else { OAuthSwift.retainError(failure); return }
                let parameters = response.string?.parametersFromQueryString ?? [:]
                if let oauthToken = parameters["oauth_token"] {
                    this.client.credential.oauthToken = oauthToken.safeStringByRemovingPercentEncoding
                }
                if let oauthTokenSecret = parameters["oauth_token_secret"] {
                    this.client.credential.oauthTokenSecret = oauthTokenSecret.safeStringByRemovingPercentEncoding
                }
                success(this.client.credential, response, parameters)
            }, failure: failure
            ) {
            self.putHandle(handle, withKey: UUID().uuidString)
        }
    }

}
