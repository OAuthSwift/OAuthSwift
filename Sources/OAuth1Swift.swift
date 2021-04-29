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
    /// set this value to true (default: false)
    open var allowMissingOAuthVerifier: Bool = false

    /// Optionally add callback URL to authorize Url (default: false)
    open var addCallbackURLToAuthorizeURL: Bool = false

    /// Optionally add consumer key to authorize Url (default: false)
    open var addConsumerKeyToAuthorizeURL: Bool = false

    /// Encode token using RFC3986
    open var useRFC3986ToEncodeToken: Bool = false

    var consumerKey: String
    var consumerSecret: String
    var requestTokenUrl: String
    var authorizeUrl: String
    var accessTokenUrl: String

    // MARK: init
    public init(consumerKey: String, consumerSecret: String, requestTokenUrl: URLConvertible, authorizeUrl: URLConvertible, accessTokenUrl: URLConvertible) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.requestTokenUrl = requestTokenUrl.string
        self.authorizeUrl = authorizeUrl.string
        self.accessTokenUrl = accessTokenUrl.string
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
        self.init(consumerKey: consumerKey, consumerSecret: consumerSecret,
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
    open func authorize(withCallbackURL url: URLConvertible, headers: OAuthSwift.Headers? = nil, completionHandler completion: @escaping TokenCompletionHandler) -> OAuthSwiftRequestHandle? {
        guard let callbackURL = url.url else {
            completion(.failure(.encodingError(urlString: url.string)))
            return nil
        }
        let completionHandler: TokenCompletionHandler = { [unowned self] result in
            switch result {
            case .success(let (credential, _, _)):
                self.observeCallback { [weak self] url in
                    guard let this = self else { OAuthSwift.retainError(completion); return }
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

                    if let token = responseParameters["oauth_token"], !token.isEmpty {
                        this.client.credential.oauthToken = token.safeStringByRemovingPercentEncoding
                        if let oauth_verifier = responseParameters["oauth_verifier"] {
                            this.client.credential.oauthVerifier = oauth_verifier.safeStringByRemovingPercentEncoding
                        } else {
                            if !this.allowMissingOAuthVerifier {
                                completion(.failure(.configurationError(message: "Missing oauth_verifier. Maybe use allowMissingOAuthVerifier=true")))
                                return
                            }
                        }
                        this.postOAuthAccessTokenWithRequestToken(headers: headers, completionHandler: completion)
                    } else {
                        completion(.failure(.missingToken))
                        return
                    }
                }
                // 2. Authorize
                if let token = self.encode(token: credential.oauthToken) {
                    var urlString = self.authorizeUrl + (self.authorizeUrl.contains("?") ? "&" : "?")
                    urlString += "oauth_token=\(token)"
                    if self.addConsumerKeyToAuthorizeURL {
                        urlString += "&oauth_consumer_key=\(self.consumerKey)"
                    }
                    if self.addCallbackURLToAuthorizeURL {
                        urlString += "&oauth_callback=\(callbackURL.absoluteString)"
                    }
                    if let queryURL = URL(string: urlString) {
                        self.authorizeURLHandler.handle(queryURL)
                    } else {
                        completion(.failure(.encodingError(urlString: urlString)))
                    }
                } else {
                    completion(.failure(.encodingError(urlString: credential.oauthToken))) // TODO specific error
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }

        self.postOAuthRequestToken(callbackURL: callbackURL, headers: headers, completionHandler: completionHandler)
        return self
    }

    private func encode(token: String) -> String? {
        if useRFC3986ToEncodeToken {
            return token.urlEncoded
        }
        return token.urlQueryEncoded
    }

    // 1. Request token
    func postOAuthRequestToken(callbackURL: URL, headers: OAuthSwift.Headers? = nil, completionHandler completion: @escaping TokenCompletionHandler) {
        var parameters = [String: Any]()
        parameters["oauth_callback"] = callbackURL.absoluteString

        let completionHandler: OAuthSwiftHTTPRequest.CompletionHandler = { [weak self] result in
            guard let this = self else { OAuthSwift.retainError(completion); return }

            switch result {
            case .success(let response):
                let parameters = response.string?.parametersFromQueryString ?? [:]
                if let oauthToken = parameters["oauth_token"] {
                    this.client.credential.oauthToken = oauthToken.safeStringByRemovingPercentEncoding
                }
                if let oauthTokenSecret=parameters["oauth_token_secret"] {
                    this.client.credential.oauthTokenSecret = oauthTokenSecret.safeStringByRemovingPercentEncoding
                }
                completion(.success((this.client.credential, response, parameters)))
            case .failure(let error):
                completion(.failure(error))
            }
        }

        if let handle = self.client.post(
            self.requestTokenUrl, parameters: parameters, headers: headers,
            completionHandler: completionHandler) {
            self.putHandle(handle, withKey: UUID().uuidString)
        }
    }

    // 3. Get Access token
    func postOAuthAccessTokenWithRequestToken(headers: OAuthSwift.Headers? = nil, completionHandler completion: @escaping TokenCompletionHandler) {
        var parameters = [String: Any]()
        parameters["oauth_token"] = self.client.credential.oauthToken
        if !self.allowMissingOAuthVerifier {
            parameters["oauth_verifier"] = self.client.credential.oauthVerifier
        }

        let completionHandler: OAuthSwiftHTTPRequest.CompletionHandler = { [weak self] result in
            guard let this = self else { OAuthSwift.retainError(completion); return }

            switch result {
            case .success(let response):
                let parameters = response.string?.parametersFromQueryString ?? [:]
                if let oauthToken = parameters["oauth_token"] {
                    this.client.credential.oauthToken = oauthToken.safeStringByRemovingPercentEncoding
                }
                if let oauthTokenSecret = parameters["oauth_token_secret"] {
                    this.client.credential.oauthTokenSecret = oauthTokenSecret.safeStringByRemovingPercentEncoding
                }
                completion(.success((this.client.credential, response, parameters)))

            case .failure(let error):
                completion(.failure(error))
            }
        }
        if let handle = self.client.post(
            self.accessTokenUrl, parameters: parameters, headers: headers,
            completionHandler: completionHandler) {
            self.putHandle(handle, withKey: UUID().uuidString)
        }
    }

}
