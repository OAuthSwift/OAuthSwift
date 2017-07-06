//
//  OAuthSwiftCredential.swift
//  OAuthSwift
//
//  Created by Noam Bar-on on 6/21/17.
//  Copyright © 2017 Dongri Jin. All rights reserved.
//

import Foundation

// Allow to customize computed headers
public protocol OAuthSwiftCredentialHeadersFactory {
    func make(_ url: URL, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters, body: Data?) -> [String: String]
}

// Protocol for OAuthSwiftCredential object
// For your convenience, find a concrete BaseOAuthSwiftCredential class you can subclass
public protocol OAuthSwiftCredential: NSCoding, NSObjectProtocol {
    
    // MARK: attributes
    var consumerKey: String {set get}
    var consumerSecret: String {set get}
    var oauthToken: String {set get}
    var oauthRefreshToken: String {set get}
    var oauthTokenSecret: String {set get}
    var oauthTokenExpiresAt: Date? {set get}
    var oauthVerifier: String {set get}
    var version: OAuthSwiftVersion {set get}
    
    var headersFactory: OAuthSwiftCredentialHeadersFactory? {set get}
    
    init(consumerKey: String, consumerSecret: String, version: OAuthSwiftVersion)
    
    // MARK: functions
    // for OAuth1 parameters must contains sorted query parameters and url must not contains query parameters
    func makeHeaders(_ url: URL, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters, body: Data?) -> [String: String]
    
    func authorizationHeader(method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: OAuthSwift.Parameters, body: Data?) -> String
    
    static func generateNonce() -> String
    
    func authorizationHeader(method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: OAuthSwift.Parameters, body: Data?, timestamp: String, nonce: String) -> String
    
    func authorizationParametersWithSignature(method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: OAuthSwift.Parameters, body: Data?) -> OAuthSwift.Parameters
    
    func authorizationParametersWithSignature(method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: OAuthSwift.Parameters, body: Data?, timestamp: String, nonce: String) -> OAuthSwift.Parameters
    
    func authorizationParameters(_ body: Data?, timestamp: String, nonce: String) -> OAuthSwift.Parameters
    
    func signature(method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: OAuthSwift.Parameters) -> String
    
    func isTokenExpired() -> Bool
}
