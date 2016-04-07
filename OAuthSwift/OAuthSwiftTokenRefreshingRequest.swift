//
//  OAuthSwiftTokenRefreshingRequest.swift
//  OAuthSwift
//
//  Created by Goessler, Florian on 07/04/16.
//  Copyright © 2016 Dongri Jin. All rights reserved.
//

import Foundation

class OAuthSwiftTokenRefreshingRequest {

    private static let noopTokenExpirationHandler: OAuthSwift.TokenExpirationHandler = { completion in
        completion(error: NSError(domain: OAuthSwiftErrorDomain, code: OAuthSwiftErrorCode.TokenExpiredError.rawValue, userInfo: nil))
    }

    private let credentials: OAuthSwiftCredential
    private let tokenExpirationHandler: OAuthSwift.TokenExpirationHandler
    private let tokenRenewedHandler: OAuthSwift.TokenRenewedHandler?
    private let requestConfig: OAuthSwiftHTTPRequestConfig

    private var cancelRequested: Bool = false
    private var latestRequest: OAuthSwiftHTTPRequest?

    init(credentials: OAuthSwiftCredential, tokenExpirationHandler: OAuthSwift.TokenExpirationHandler?, tokenRenewedHandler: OAuthSwift.TokenRenewedHandler?, requestConfig: OAuthSwiftHTTPRequestConfig) {
        self.credentials = credentials
        self.tokenExpirationHandler = tokenExpirationHandler != nil ? tokenExpirationHandler! : OAuthSwiftTokenRefreshingRequest.noopTokenExpirationHandler
        self.tokenRenewedHandler = tokenRenewedHandler
        self.requestConfig = requestConfig
    }

    func startRequest(checkTokenExpiration: Bool = true, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        if checkTokenExpiration && credentials.isTokenExpired()  {
            handleExpiredToken(success, failure: failure)
        }

        let request = OAuthSwiftHTTPRequest(requestConfig: requestConfig)
        request.successHandler = { data, response in
            self.latestRequest = nil
            success?(data: data, response: response)
        }
        request.failureHandler = { (error) in
            self.latestRequest = nil
            if error.isExpiredTokenError {
                self.handleExpiredToken(success, failure: failure)
            } else {
                failure?(error: error)
            }
        }

        startRequestIfNotCanceled(request)
    }

    func cancel() {
        // perform lock here to prevent cancel calls on another thread while creating the request
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        cancelRequested = true
        latestRequest?.cancel()
    }

    private func handleExpiredToken(success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        tokenExpirationHandler() { error in
            if let error = error {
                failure?(error: error)
            } else {
                self.tokenRenewedHandler?(credential: self.credentials)

                // recreate the OAuthSwiftHTTPRequest to use the most up to date tokens, etc.
                let request = OAuthSwiftHTTPRequest(requestConfig: self.requestConfig)
                request.successHandler = success
                request.failureHandler = failure

                self.startRequestIfNotCanceled(request)
            }
        }
    }

    private func startRequestIfNotCanceled(request: OAuthSwiftHTTPRequest) {
        // perform lock here to prevent cancel calls on another thread while creating the request
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if self.cancelRequested {
            return
        }

        self.latestRequest = request
        request.start(self.credentials)
    }
}
