//
//  OAuth2Swift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/22/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

open class OAuth2Swift: OAuthSwift {

    /// If your oauth provider need to use basic authentification
    /// set value to true (default: false)
    open var accessTokenBasicAuthentification = false

    /// Set to true to deactivate state check. Be careful of CSRF
    open var allowMissingStateCheck: Bool = false

    /// Encode callback url, some services require it to be encoded.
    open var encodeCallbackURL: Bool = false

    /// Encode callback url inside the query, this is second encoding phase when the entire query string gets assembled. In rare 
    /// cases, like with Imgur, the url needs to be encoded only once and this value needs to be set to `false`.
    open var encodeCallbackURLQuery: Bool = true

    var consumerKey: String
    var consumerSecret: String
    var authorizeUrl: String
    var accessTokenUrl: String?
    var responseType: String
    var contentType: String?
    // RFC7636 PKCE
    var codeVerifier: String?

    // MARK: init
    public convenience init(consumerKey: String, consumerSecret: String, authorizeUrl: URLConvertible, accessTokenUrl: URLConvertible, responseType: String) {
        self.init(consumerKey: consumerKey, consumerSecret: consumerSecret, authorizeUrl: authorizeUrl, responseType: responseType)
        self.accessTokenUrl = accessTokenUrl.string
    }

    public convenience init(consumerKey: String, consumerSecret: String, authorizeUrl: URLConvertible, accessTokenUrl: URLConvertible, responseType: String, contentType: String) {
        self.init(consumerKey: consumerKey, consumerSecret: consumerSecret, authorizeUrl: authorizeUrl, responseType: responseType)
        self.accessTokenUrl = accessTokenUrl.string
        self.contentType = contentType
    }

    public init(consumerKey: String, consumerSecret: String, authorizeUrl: URLConvertible, responseType: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.authorizeUrl = authorizeUrl.string
        self.responseType = responseType
        super.init(consumerKey: consumerKey, consumerSecret: consumerSecret)
        self.client.credential.version = .oauth2
    }

    public convenience init?(parameters: ConfigParameters) {
        guard let consumerKey = parameters["consumerKey"], let consumerSecret = parameters["consumerSecret"],
            let responseType = parameters["responseType"], let authorizeUrl = parameters["authorizeUrl"] else {
                return nil
        }
        if let accessTokenUrl = parameters["accessTokenUrl"] {
            self.init(consumerKey: consumerKey, consumerSecret: consumerSecret,
                      authorizeUrl: authorizeUrl, accessTokenUrl: accessTokenUrl, responseType: responseType)
        } else {
            self.init(consumerKey: consumerKey, consumerSecret: consumerSecret,
                      authorizeUrl: authorizeUrl, responseType: responseType)
        }
    }

    open var parameters: ConfigParameters {
        return [
            "consumerKey": consumerKey,
            "consumerSecret": consumerSecret,
            "authorizeUrl": authorizeUrl,
            "accessTokenUrl": accessTokenUrl ?? "",
            "responseType": responseType
        ]
    }

    // MARK: functions
    @discardableResult
    open func authorize(withCallbackURL callbackURL: URLConvertible?, scope: String, state: String, parameters: Parameters = [:], headers: OAuthSwift.Headers? = nil, completionHandler completion: @escaping TokenCompletionHandler) -> OAuthSwiftRequestHandle? {
        if let url = callbackURL, url.url == nil {
            completion(.failure(.encodingError(urlString: url.string)))
            return nil
        }
        self.observeCallback { [weak self] url in
            guard let this = self else {
                OAuthSwift.retainError(completion)
                return
            }
            var responseParameters = [String: String]()
            if let query = url.query {
                responseParameters += query.parametersFromQueryString
            }
            if let fragment = url.fragment, !fragment.isEmpty {
                responseParameters += fragment.parametersFromQueryString
            }
            if let accessToken = responseParameters["access_token"] {
                this.client.credential.oauthToken = accessToken.safeStringByRemovingPercentEncoding
                if let expiresIn: String = responseParameters["expires_in"], let offset = Double(expiresIn) {
                    this.client.credential.oauthTokenExpiresAt = Date(timeInterval: offset, since: Date())
                }
                completion(.success((this.client.credential, nil, responseParameters)))
            } else if let code = responseParameters["code"] {
                if !this.allowMissingStateCheck {
                    guard let responseState = responseParameters["state"] else {
                        completion(.failure(.missingState))
                        return
                    }
                    if responseState != state {
                        completion(.failure(.stateNotEqual(state: state, responseState: responseState)))
                        return
                    }
                }
                let callbackURLEncoded: URL?
                if let callbackURL = callbackURL {
                    callbackURLEncoded = callbackURL.encodedURL // XXX do not known why to re-encode, maybe if string only?
                } else {
                    callbackURLEncoded = nil
                }
                if let handle = this.postOAuthAccessTokenWithRequestToken(
                    byCode: code.safeStringByRemovingPercentEncoding,
                    callbackURL: callbackURLEncoded, headers: headers, completionHandler: completion) {
                    this.putHandle(handle, withKey: UUID().uuidString)
                }
            } else if let error = responseParameters["error"] {
                let description = responseParameters["error_description"] ?? ""
                let message = NSLocalizedString(error, comment: description)
                completion(.failure(.serverError(message: message)))
            } else {
                let message = "No access_token, no code and no error provided by server"
                completion(.failure(.serverError(message: message)))
            }
        }

        var queryErrorString = ""
        let encodeError: (String, String) -> Void = { name, value in
            if let newQuery = queryErrorString.urlQueryByAppending(parameter: name, value: value, encode: false) {
                queryErrorString = newQuery
            }
        }

        var queryString: String? = ""
        queryString = queryString?.urlQueryByAppending(parameter: "client_id", value: self.consumerKey, encodeError)
        if let callbackURL = callbackURL {
            let value = self.encodeCallbackURL ? callbackURL.string.urlEncoded : callbackURL.string
            queryString = queryString?.urlQueryByAppending(parameter: "redirect_uri", value: value, encode: self.encodeCallbackURLQuery, encodeError)
        }
        queryString = queryString?.urlQueryByAppending(parameter: "response_type", value: self.responseType, encodeError)
        queryString = queryString?.urlQueryByAppending(parameter: "scope", value: scope, encodeError)
        queryString = queryString?.urlQueryByAppending(parameter: "state", value: state, encodeError)

        for (name, value) in parameters {
            queryString = queryString?.urlQueryByAppending(parameter: name, value: "\(value)", encodeError)
        }

        if let queryString = queryString {
            let urlString = self.authorizeUrl.urlByAppending(query: queryString)
            if let url: URL = URL(string: urlString) {
                self.authorizeURLHandler.handle(url)
                return self
            } else {
                completion(.failure(.encodingError(urlString: urlString)))
            }
        } else {
            let urlString = self.authorizeUrl.urlByAppending(query: queryErrorString)
            completion(.failure(.encodingError(urlString: urlString)))
        }
        self.cancel() // ie. remove the observer.
        return nil
    }

    open func postOAuthAccessTokenWithRequestToken(byCode code: String, callbackURL: URL?, headers: OAuthSwift.Headers? = nil, completionHandler completion: @escaping TokenCompletionHandler) -> OAuthSwiftRequestHandle? {
        var parameters = OAuthSwift.Parameters()
        parameters["client_id"] = self.consumerKey
        parameters["client_secret"] = self.consumerSecret
        parameters["code"] = code
        parameters["grant_type"] = "authorization_code"

        // PKCE - extra parameter
        if let codeVerifier = self.codeVerifier {
            parameters["code_verifier"] = codeVerifier
        }

        if let callbackURL = callbackURL {
            parameters["redirect_uri"] = callbackURL.absoluteString.safeStringByRemovingPercentEncoding
        }

        return requestOAuthAccessToken(withParameters: parameters, headers: headers, completionHandler: completion)
    }

    @discardableResult
    open func renewAccessToken(withRefreshToken refreshToken: String, parameters: OAuthSwift.Parameters? = nil, headers: OAuthSwift.Headers? = nil, completionHandler completion: @escaping TokenCompletionHandler) -> OAuthSwiftRequestHandle? {
        var parameters = parameters ?? OAuthSwift.Parameters()
        parameters["client_id"] = self.consumerKey
        parameters["client_secret"] = self.consumerSecret
        parameters["refresh_token"] = refreshToken
        parameters["grant_type"] = "refresh_token"

        return requestOAuthAccessToken(withParameters: parameters, headers: headers, completionHandler: completion)
    }

    fileprivate func requestOAuthAccessToken(withParameters parameters: OAuthSwift.Parameters, headers: OAuthSwift.Headers? = nil, completionHandler completion: @escaping TokenCompletionHandler) -> OAuthSwiftRequestHandle? {

        let completionHandler: OAuthSwiftHTTPRequest.CompletionHandler = { [weak self] result in
            guard let this = self else {
                OAuthSwift.retainError(completion)
                return
            }
            switch result {
            case .success(let response):
                let responseJSON: Any? = try? response.jsonObject(options: .mutableContainers)

                let responseParameters: OAuthSwift.Parameters

                if let jsonDico = responseJSON as? [String: Any] {
                    responseParameters = jsonDico
                } else {
                    responseParameters = response.string?.parametersFromQueryString ?? [:]
                }

                guard let accessToken = responseParameters["access_token"] as? String else {
                    let message = NSLocalizedString("Could not get Access Token", comment: "Due to an error in the OAuth2 process, we couldn't get a valid token.")
                    completion(.failure(.serverError(message: message)))
                    return
                }

                if let refreshToken = responseParameters["refresh_token"] as? String {
                    this.client.credential.oauthRefreshToken = refreshToken.safeStringByRemovingPercentEncoding
                }

                if let expiresIn = responseParameters["expires_in"] as? String, let offset = Double(expiresIn) {
                    this.client.credential.oauthTokenExpiresAt = Date(timeInterval: offset, since: Date())
                } else if let expiresIn = responseParameters["expires_in"] as? Double {
                    this.client.credential.oauthTokenExpiresAt = Date(timeInterval: expiresIn, since: Date())
                }

                this.client.credential.oauthToken = accessToken.safeStringByRemovingPercentEncoding
                completion(.success((this.client.credential, response, responseParameters)))
            case .failure(let error):
                completion(.failure(error))
            }
        }

        guard let accessTokenUrl = accessTokenUrl else {
            let message = NSLocalizedString("access token url not defined", comment: "access token url not defined with code type auth")
            completion(.failure(.configurationError(message: message)))
            return nil
        }

        if self.contentType == "multipart/form-data" {
            // Request new access token by disabling check on current token expiration. This is safe because the implementation wants the user to retrieve a new token.
            return self.client.postMultiPartRequest(accessTokenUrl, method: .POST, parameters: parameters, headers: headers, checkTokenExpiration: false, completionHandler: completionHandler)
        } else {
            // special headers
            var finalHeaders: OAuthSwift.Headers? = headers
            if accessTokenBasicAuthentification {
                let authentification = "\(self.consumerKey):\(self.consumerSecret)".data(using: String.Encoding.utf8)
                if let base64Encoded = authentification?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
                    finalHeaders += ["Authorization": "Basic \(base64Encoded)"] as OAuthSwift.Headers
                }
            }
            // Request new access token by disabling check on current token expiration. This is safe because the implementation wants the user to retrieve a new token.
            return self.client.request(accessTokenUrl, method: .POST, parameters: parameters, headers: finalHeaders, checkTokenExpiration: false, completionHandler: completionHandler)
        }
    }

    /**
     Convenience method to start a request that must be authorized with the previously retrieved access token.
     Since OAuth 2 requires support for the access token refresh mechanism, this method will take care to automatically
     refresh the token if needed such that the developer only has to be concerned about the outcome of the request.
     
     - parameter url:            The url for the request.
     - parameter method:         The HTTP method to use.
     - parameter parameters:     The request's parameters.
     - parameter headers:        The request's headers.
     - parameter renewHeaders:   The request's headers if renewing. If nil, the `headers`` are used when renewing.
     - parameter body:           The request's HTTP body.
     - parameter onTokenRenewal: Optional callback triggered in case the access token renewal was required in order to properly authorize the request.
     - parameter success:        The success block. Takes the successfull response and data as parameter.
     - parameter failure:        The failure block. Takes the error as parameter.
     */
    @discardableResult
    open func startAuthorizedRequest(_ url: URLConvertible, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters, headers: OAuthSwift.Headers? = nil, renewHeaders: OAuthSwift.Headers? = nil, body: Data? = nil, onTokenRenewal: TokenRenewedHandler? = nil, completionHandler completion: @escaping OAuthSwiftHTTPRequest.CompletionHandler) -> OAuthSwiftRequestHandle? {

        let completionHandler: OAuthSwiftHTTPRequest.CompletionHandler = { result in
            switch result {
            case .success:
                completion(result)
            case .failure(let error): // map/recovery error
                switch error {
                case OAuthSwiftError.tokenExpired:
                    let renewCompletionHandler: TokenCompletionHandler = { result in
                        switch result {
                        case .success(let credential, _, _):
                            // Ommit response parameters so they don't override the original ones
                            // We have successfully renewed the access token.

                            // If provided, fire the onRenewal closure
                            if let renewalCallBack = onTokenRenewal {
                                renewalCallBack(.success(credential))
                            }

                            // Reauthorize the request again, this time with a brand new access token ready to be used.
                            _ = self.startAuthorizedRequest(url, method: method, parameters: parameters, headers: headers, body: body, onTokenRenewal: onTokenRenewal, completionHandler: completion)
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }

                    _ = self.renewAccessToken(withRefreshToken: self.client.credential.oauthRefreshToken, headers: renewHeaders ?? headers, completionHandler: renewCompletionHandler)
                default:
                    completion(.failure(error))
                }
            }
        }

        // build request
        return self.client.request(url, method: method, parameters: parameters, headers: headers, body: body, completionHandler: completionHandler)
    }

    // OAuth 2.0 Specification: https://tools.ietf.org/html/draft-ietf-oauth-v2-13#section-4.3
    @discardableResult
    open func authorize(username: String, password: String, scope: String?, headers: OAuthSwift.Headers? = nil, completionHandler completion: @escaping TokenCompletionHandler) -> OAuthSwiftRequestHandle? {

        var parameters = OAuthSwift.Parameters()
        parameters["client_id"] = self.consumerKey
        parameters["client_secret"] = self.consumerSecret
        parameters["username"] = username
        parameters["password"] = password
        parameters["grant_type"] = "password"

        if let scope = scope {
            parameters["scope"] = scope
        }

        return requestOAuthAccessToken(
            withParameters: parameters,
            headers: headers,
            completionHandler: completion
        )
    }

    @discardableResult
    open func authorize(deviceToken deviceCode: String, grantType: String = "http://oauth.net/grant_type/device/1.0", completionHandler completion: @escaping TokenCompletionHandler) -> OAuthSwiftRequestHandle? {
        var parameters = OAuthSwift.Parameters()
        parameters["client_id"] = self.consumerKey
        parameters["client_secret"] = self.consumerSecret
        parameters["code"] = deviceCode
        parameters["grant_type"] = grantType

        return requestOAuthAccessToken(
            withParameters: parameters,
            completionHandler: completion
        )
    }

    /// use RFC7636 PKCE credentials - convenience method
    @discardableResult
    open func authorize(withCallbackURL url: URLConvertible, scope: String, state: String, codeChallenge: String, codeChallengeMethod: String = "S256", codeVerifier: String, parameters: Parameters = [:], headers: OAuthSwift.Headers? = nil, completionHandler completion: @escaping TokenCompletionHandler) -> OAuthSwiftRequestHandle? {
        guard let callbackURL = url.url else {
            completion(.failure(.encodingError(urlString: url.string)))
            return nil
        }

        // remember code_verifier
        self.codeVerifier = codeVerifier
        // PKCE - extra parameter
        var pkceParameters = Parameters()
        pkceParameters["code_challenge"] = codeChallenge
        pkceParameters["code_challenge_method"] = codeChallengeMethod

        return authorize(withCallbackURL: callbackURL, scope: scope, state: state, parameters: parameters + pkceParameters, headers: headers, completionHandler: completion)
    }
}
