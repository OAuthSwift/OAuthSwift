//
//  OAuthSwiftClient.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

public var OAuthSwiftDataEncoding: String.Encoding = .utf8

@objc public protocol OAuthSwiftRequestHandle {
    func cancel()
}

open class OAuthSwiftClient: NSObject {

    fileprivate(set) open var credential: OAuthSwiftCredential
    open var paramsLocation: OAuthSwiftHTTPRequest.ParamsLocation = .authorizationHeader
    /// Contains default URL session configuration
    open var sessionFactory = URLSessionFactory()

    static let separator: String = "\r\n"
    static var separatorData: Data = {
        return OAuthSwiftClient.separator.data(using: OAuthSwiftDataEncoding)!
    }()

    // MARK: init
    public init(credential: OAuthSwiftCredential) {
        self.credential = credential
    }

    public convenience init(consumerKey: String, consumerSecret: String, version: OAuthSwiftCredential.Version = .oauth1) {
        let credential = OAuthSwiftCredential(consumerKey: consumerKey, consumerSecret: consumerSecret)
        credential.version = version
        self.init(credential: credential)
    }

    public convenience init(consumerKey: String, consumerSecret: String, oauthToken: String, oauthTokenSecret: String, version: OAuthSwiftCredential.Version) {
        self.init(consumerKey: consumerKey, consumerSecret: consumerSecret, version: version)
        self.credential.oauthToken = oauthToken
        self.credential.oauthTokenSecret = oauthTokenSecret
    }

    // MARK: client methods
    @discardableResult
    open func get(_ url: URLConvertible, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, completionHandler completion: OAuthSwiftHTTPRequest.CompletionHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(url, method: .GET, parameters: parameters, headers: headers, completionHandler: completion)
    }

    @discardableResult
    open func post(_ url: URLConvertible, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, body: Data? = nil, completionHandler completion: OAuthSwiftHTTPRequest.CompletionHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(url, method: .POST, parameters: parameters, headers: headers, body: body, completionHandler: completion)
    }

    @discardableResult
    open func put(_ url: URLConvertible, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, body: Data? = nil, completionHandler completion: OAuthSwiftHTTPRequest.CompletionHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(url, method: .PUT, parameters: parameters, headers: headers, body: body, completionHandler: completion)
    }

    @discardableResult
    open func delete(_ url: URLConvertible, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, completionHandler completion: OAuthSwiftHTTPRequest.CompletionHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(url, method: .DELETE, parameters: parameters, headers: headers, completionHandler: completion)
    }

    @discardableResult
    open func patch(_ url: URLConvertible, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, completionHandler completion: OAuthSwiftHTTPRequest.CompletionHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(url, method: .PATCH, parameters: parameters, headers: headers, completionHandler: completion)
    }

    @discardableResult
    open func request(_ url: URLConvertible, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, body: Data? = nil, checkTokenExpiration: Bool = true, completionHandler completion: OAuthSwiftHTTPRequest.CompletionHandler?) -> OAuthSwiftRequestHandle? {

        if checkTokenExpiration && self.credential.isTokenExpired() {
            completion?(.failure(.tokenExpired(error: nil)))
            return nil
        }

        guard url.url != nil else {
            completion?(.failure(.encodingError(urlString: url.string)))
            return nil
        }

        if let request = makeRequest(url, method: method, parameters: parameters, headers: headers, body: body) {
            request.start(completionHandler: completion)
            return request
        }
        return nil
    }

    open func makeRequest(_ request: URLRequest) -> OAuthSwiftHTTPRequest {
        let request = OAuthSwiftHTTPRequest(request: request, paramsLocation: self.paramsLocation, sessionFactory: self.sessionFactory)
        request.config.updateRequest(credential: self.credential)
        return request
    }

    open func makeRequest(_ url: URLConvertible, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, body: Data? = nil) -> OAuthSwiftHTTPRequest? {
        guard let url = url.url else {
            return nil // XXX failure not thrown here
        }

        let request = OAuthSwiftHTTPRequest(url: url, method: method, parameters: parameters, paramsLocation: self.paramsLocation, httpBody: body, headers: headers ?? [:], sessionFactory: self.sessionFactory)
        request.config.updateRequest(credential: self.credential)
        return request
    }

    @discardableResult
    public func postImage(_ url: URLConvertible, parameters: OAuthSwift.Parameters, image: Data, completionHandler completion: OAuthSwiftHTTPRequest.CompletionHandler?) -> OAuthSwiftRequestHandle? {
        return self.multiPartRequest(url: url, method: .POST, parameters: parameters, image: image, completionHandler: completion)
    }

    open func makeMultiPartRequest(_ url: URLConvertible, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters = [:], multiparts: [OAuthSwiftMultipartData] = [], headers: OAuthSwift.Headers? = nil) -> OAuthSwiftHTTPRequest? {
        let boundary = "AS-boundary-\(arc4random())-\(arc4random())"
        let type = "multipart/form-data; boundary=\(boundary)"
        let body = self.multiDataFromObject(parameters, multiparts: multiparts, boundary: boundary)

        var finalHeaders = [kHTTPHeaderContentType: type]
        finalHeaders += headers ?? [:]

        return makeRequest(url, method: method, parameters: parameters, headers: finalHeaders, body: body)
    }

    func multiPartRequest(url: URLConvertible, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters, image: Data, completionHandler completion: OAuthSwiftHTTPRequest.CompletionHandler?) -> OAuthSwiftRequestHandle? {
        let multiparts = [ OAuthSwiftMultipartData(name: "media", data: image, fileName: "file", mimeType: "image/jpeg") ]
        guard let request = makeMultiPartRequest(url, method: method, parameters: parameters, multiparts: multiparts) else {
            return nil
        }
        request.start(completionHandler: completion)
        return request
    }

    open func multiPartBody(from inputParameters: OAuthSwift.Parameters, boundary: String) -> Data {
        var parameters = OAuthSwift.Parameters()
        var multiparts = [OAuthSwiftMultipartData]()

        for (key, value) in inputParameters {
            if  let data = value as? Data, key == "media" {
                let sectionType = "image/jpeg"
                let sectionFilename = "file"
                multiparts.append(OAuthSwiftMultipartData(name: key, data: data, fileName: sectionFilename, mimeType: sectionType))
            } else {
                parameters[key] = value
            }
        }

        return multiDataFromObject(parameters, multiparts: multiparts, boundary: boundary)
    }

    @discardableResult
    open func postMultiPartRequest(_ url: URLConvertible, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters, headers: OAuthSwift.Headers? = nil, multiparts: [OAuthSwiftMultipartData] = [], checkTokenExpiration: Bool = true, completionHandler completion: OAuthSwiftHTTPRequest.CompletionHandler?) -> OAuthSwiftRequestHandle? {

        if checkTokenExpiration && self.credential.isTokenExpired() {
            completion?(.failure(.tokenExpired(error: nil)))
            return nil
        }

        if let request = makeMultiPartRequest(url, method: method, parameters: parameters, multiparts: multiparts, headers: headers) {
            request.start(completionHandler: completion)
            return request
        }
        return nil
    }

    func multiDataFromObject(_ object: OAuthSwift.Parameters, multiparts: [OAuthSwiftMultipartData], boundary: String) -> Data {
        var data = Data()

        let prefixString = "--\(boundary)\r\n"
        let prefixData = prefixString.data(using: OAuthSwiftDataEncoding)!

        for (key, value) in object {
            guard let valueData = "\(value)".data(using: OAuthSwiftDataEncoding) else {
                continue
            }
            data.append(prefixData)
            let multipartData = OAuthSwiftMultipartData(name: key, data: valueData, fileName: nil, mimeType: nil)
            data.append(multipartData, encoding: OAuthSwiftDataEncoding, separatorData: OAuthSwiftClient.separatorData)
        }

        for multipart in multiparts {
            data.append(prefixData)
            data.append(multipart, encoding: OAuthSwiftDataEncoding, separatorData: OAuthSwiftClient.separatorData)
        }

        let endingString = "--\(boundary)--\r\n"
        let endingData = endingString.data(using: OAuthSwiftDataEncoding)!
        data.append(endingData)

        return data
    }

    // MARK: Refresh Token
    @discardableResult
    open func renewAccessToken(accessTokenUrl: URLConvertible?, withRefreshToken refreshToken: String, parameters: OAuthSwift.Parameters? = nil, headers: OAuthSwift.Headers? = nil, contentType: String? = nil, accessTokenBasicAuthentification: Bool = false, completionHandler completion: @escaping OAuthSwift.TokenCompletionHandler) -> OAuthSwiftRequestHandle? {
        // The current access token isn't needed anymore.
        self.credential.oauthToken = ""

        var parameters = parameters ?? OAuthSwift.Parameters()
        parameters["client_id"] = self.credential.consumerKey
        parameters["refresh_token"] = refreshToken
        parameters["grant_type"] = "refresh_token"

        // Omit the consumer secret if it's empty; this makes token renewal consistent with PKCE authorization.
        if !self.credential.consumerSecret.isEmpty {
            parameters["client_secret"] = self.credential.consumerSecret
        }

        OAuthSwift.log?.trace("Renew access token, parameters: \(parameters)")
        return requestOAuthAccessToken(accessTokenUrl: accessTokenUrl, withParameters: parameters, headers: headers, contentType: contentType, accessTokenBasicAuthentification: accessTokenBasicAuthentification, completionHandler: completion)
    }

    func requestOAuthAccessToken(accessTokenUrl: URLConvertible?, withParameters parameters: OAuthSwift.Parameters, headers: OAuthSwift.Headers? = nil, contentType: String? = nil, accessTokenBasicAuthentification: Bool = false, completionHandler completion: @escaping OAuthSwift.TokenCompletionHandler) -> OAuthSwiftRequestHandle? {
        OAuthSwift.log?.trace("Request Oauth access token ...")
        let completionHandler: OAuthSwiftHTTPRequest.CompletionHandler = { [weak self] result in
            guard let this = self else {
                OAuthSwift.retainError(completion)
                return
            }
            switch result {
            case .success(let response):
                OAuthSwift.log?.trace("Oauth access token response ...")

                let responseJSON: Any? = try? response.jsonObject(options: .mutableContainers)

                let responseParameters: OAuthSwift.Parameters

                if let jsonDico = responseJSON as? [String: Any] {
                    responseParameters = jsonDico
                } else {
                    responseParameters = response.string?.parametersFromQueryString ?? [:]
                }

                guard let accessToken = responseParameters["access_token"] as? String else {
                    let message = NSLocalizedString("Could not get Access Token", comment: "Due to an error in the OAuth2 process, we couldn't get a valid token.")
                    OAuthSwift.log?.error("Could not get access token")
                    completion(.failure(.serverError(message: message)))
                    return
                }

                if let refreshToken = responseParameters["refresh_token"] as? String {
                    this.credential.oauthRefreshToken = refreshToken.safeStringByRemovingPercentEncoding
                }

                if let expiresIn = responseParameters["expires_in"] as? String, let offset = Double(expiresIn) {
                    this.credential.oauthTokenExpiresAt = Date(timeInterval: offset, since: Date())
                } else if let expiresIn = responseParameters["expires_in"] as? Double {
                    this.credential.oauthTokenExpiresAt = Date(timeInterval: expiresIn, since: Date())
                }

                this.credential.oauthToken = accessToken.safeStringByRemovingPercentEncoding
                completion(.success((this.credential, response, responseParameters)))
            case .failure(let error):
                completion(.failure(error))
            }
        }

        guard let accessTokenUrl = accessTokenUrl else {
            let message = NSLocalizedString("access token url not defined", comment: "access token url not defined with code type auth")
            OAuthSwift.log?.error("Access token url not defined")
            completion(.failure(.configurationError(message: message)))
            return nil
        }

        if contentType == "multipart/form-data" {
            // Request new access token by disabling check on current token expiration. This is safe because the implementation wants the user to retrieve a new token.
            return self.postMultiPartRequest(accessTokenUrl, method: .POST, parameters: parameters, headers: headers, checkTokenExpiration: false, completionHandler: completionHandler)
        } else {
            // special headers
            var finalHeaders: OAuthSwift.Headers? = headers
            if accessTokenBasicAuthentification {
                let authentification = "\(self.credential.consumerKey):\(self.credential.consumerSecret)".data(using: String.Encoding.utf8)
                if let base64Encoded = authentification?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
                    finalHeaders += ["Authorization": "Basic \(base64Encoded)"] as OAuthSwift.Headers
                }
            }
            // Request new access token by disabling check on current token expiration. This is safe because the implementation wants the user to retrieve a new token.
            return self.request(accessTokenUrl, method: .POST, parameters: parameters, headers: finalHeaders, checkTokenExpiration: false, completionHandler: completionHandler)
        }
    }

    open func requestWithAutomaticAccessTokenRenewal(url: URL, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, contentType: String? = nil, accessTokenBasicAuthentification: Bool = false, accessTokenUrl: URLConvertible, onTokenRenewal: OAuthSwift.TokenRenewedHandler?, completionHandler completion: OAuthSwiftHTTPRequest.CompletionHandler?) {
        self.request(url, method: method, parameters: parameters, headers: headers) { [weak self] result in
            guard let this = self else {
                OAuthSwift.retainError(completion)
                return
            }

            switch result {
            case .success(let response):
                if let completion = completion {
                    completion(.success(response))
                }

            case .failure(let error):
                switch error {
                case OAuthSwiftError.tokenExpired:
                    if let onTokenRenewal = onTokenRenewal {
                        let renewCompletionHandler: OAuthSwift.TokenCompletionHandler = { result in
                            switch result {
                            case .success(let (credential, _, _)):
                                onTokenRenewal(.success(credential))
                                this.requestWithAutomaticAccessTokenRenewal(url: url, method: method, parameters: parameters, headers: headers, contentType: contentType, accessTokenBasicAuthentification: accessTokenBasicAuthentification, accessTokenUrl: accessTokenUrl, onTokenRenewal: nil, completionHandler: completion)
                            case .failure(let error):
                                if let completion = completion {
                                    completion(.failure(.tokenExpired(error: error)))
                                }
                            }
                        }

                        _ = this.renewAccessToken(accessTokenUrl: accessTokenUrl, withRefreshToken: this.credential.oauthRefreshToken, headers: headers, contentType: contentType, accessTokenBasicAuthentification: accessTokenBasicAuthentification, completionHandler: renewCompletionHandler)
                    } else {
                        if let completion = completion {
                            completion(.failure(.tokenExpired(error: nil)))
                        }
                    }

                default:
                    if let completion = completion {
                        completion(.failure(.tokenExpired(error: nil)))
                    }
                }
            }
        }
    }
}
