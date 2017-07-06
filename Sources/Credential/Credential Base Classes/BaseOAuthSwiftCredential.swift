//
//  BaseOAuthSwiftCredential.swift
//  OAuthSwift
//
//  Created by Noam Bar-on on 6/21/17.
//  Copyright © 2017 Dongri Jin. All rights reserved.
//

import Foundation

// A base class with default implementation of OAuthSwiftCredential protocol
public class BaseOAuthSwiftCredential: NSObject, OAuthSwiftCredential {
    
    // MARK: attributes
    open var consumerKey = ""
    open var consumerSecret = ""
    open var oauthToken = ""
    open var oauthRefreshToken = ""
    open var oauthTokenSecret = ""
    open var oauthTokenExpiresAt: Date?
    open var oauthVerifier = ""
    open var version: OAuthSwiftVersion
    
    // hook to replace headers creation
    open var headersFactory: OAuthSwiftCredentialHeadersFactory?
    
    override public init() {
        self.version = OAuth1Version() // default
    }
    
    // MARK: init
    public required init(consumerKey: String, consumerSecret: String, version: OAuthSwiftVersion) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.version = version
    }
    
    // MARK: NSCoding protocol
    fileprivate struct CodingKeys {
        static let bundleId = Bundle.main.bundleIdentifier
            ?? Bundle(for: BaseOAuthSwiftCredential.self).bundleIdentifier
            ?? ""
        static let base = bundleId + "."
        static let consumerKey = base + "comsumer_key"
        static let consumerSecret = base + "consumer_secret"
        static let oauthToken = base + "oauth_token"
        static let oauthRefreshToken = base + "oauth_refresh_token"
        static let oauthTokenExpiresAt = base + "oauth_token_expires_at"
        static let oauthTokenSecret = base + "oauth_token_secret"
        static let oauthVerifier = base + "oauth_verifier"
        static let version = base + "version"
    }
    
    // MARK: NSCoding
    public required convenience init?(coder decoder: NSCoder) {
        self.init()
        self.consumerKey = (decoder.decodeObject(forKey: CodingKeys.consumerKey) as? String) ?? String()
        self.consumerSecret = (decoder.decodeObject(forKey: CodingKeys.consumerSecret) as? String) ?? String()
        self.oauthToken = (decoder.decodeObject(forKey: CodingKeys.oauthToken) as? String) ?? String()
        self.oauthRefreshToken = (decoder.decodeObject(forKey: CodingKeys.oauthRefreshToken) as? String) ?? String()
        self.oauthTokenSecret = (decoder.decodeObject(forKey: CodingKeys.oauthTokenSecret) as? String) ?? String()
        self.oauthVerifier = (decoder.decodeObject(forKey: CodingKeys.oauthVerifier) as? String) ?? String()
        self.oauthTokenExpiresAt = (decoder.decodeObject(forKey: CodingKeys.oauthTokenExpiresAt) as? Date)
        self.version = (decoder.decodeObject(forKey: CodingKeys.version) as! OAuthSwiftVersion)
    }
    
    open func encode(with coder: NSCoder) {
        coder.encode(self.consumerKey, forKey: CodingKeys.consumerKey)
        coder.encode(self.consumerSecret, forKey: CodingKeys.consumerSecret)
        coder.encode(self.oauthToken, forKey: CodingKeys.oauthToken)
        coder.encode(self.oauthRefreshToken, forKey: CodingKeys.oauthRefreshToken)
        coder.encode(self.oauthTokenSecret, forKey: CodingKeys.oauthTokenSecret)
        coder.encode(self.oauthVerifier, forKey: CodingKeys.oauthVerifier)
        coder.encode(self.oauthTokenExpiresAt, forKey: CodingKeys.oauthTokenExpiresAt)
        coder.encode(self.version, forKey: CodingKeys.version)
    }
    // End NSCoding
    
    // MARK: functions
    // for OAuth1 parameters must contains sorted query parameters and url must not contains query parameters
    open func makeHeaders(_ url: URL, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters, body: Data? = nil) -> [String: String] {
        preconditionFailure("This abstract method must be overridden")
    }
    
    open func authorizationHeader(method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: OAuthSwift.Parameters, body: Data? = nil) -> String {
        let timestamp = String(Int64(Date().timeIntervalSince1970))
        let nonce = BaseOAuthSwiftCredential.generateNonce()
        return self.authorizationHeader(method: method, url: url, parameters: parameters, body: body, timestamp: timestamp, nonce: nonce)
    }
    
    open class func generateNonce() -> String {
        let uuidString = UUID().uuidString
        return uuidString.substring(to: 8)
    }
    
    open func authorizationHeader(method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: OAuthSwift.Parameters, body: Data? = nil, timestamp: String, nonce: String) -> String {
        preconditionFailure("This abstract method must be overridden")
    }
    
    open func authorizationParametersWithSignature(method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: OAuthSwift.Parameters, body: Data? = nil) -> OAuthSwift.Parameters {
        let timestamp = String(Int64(Date().timeIntervalSince1970))
        let nonce = BaseOAuthSwiftCredential.generateNonce()
        return self.authorizationParametersWithSignature(method: method, url: url, parameters: parameters, body: body, timestamp: timestamp, nonce: nonce)
    }
    
    open func authorizationParametersWithSignature(method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: OAuthSwift.Parameters, body: Data? = nil, timestamp: String, nonce: String) -> OAuthSwift.Parameters {
        var authorizationParameters = self.authorizationParameters(body, timestamp: timestamp, nonce: nonce)
        
        for (key, value) in parameters {
            if key.hasPrefix("oauth_") {
                authorizationParameters.updateValue(value, forKey: key)
            }
        }
        
        let combinedParameters = authorizationParameters.join(parameters)
        
        authorizationParameters["oauth_signature"] = self.signature(method: method, url: url, parameters: combinedParameters)
        
        return authorizationParameters
    }
    
    open func authorizationParameters(_ body: Data?, timestamp: String, nonce: String) -> OAuthSwift.Parameters {
        var authorizationParameters = OAuthSwift.Parameters()
        authorizationParameters["oauth_version"] = self.version.shortVersion
        authorizationParameters["oauth_signature_method"] =  "\(self.version.signatureMethod)"
        authorizationParameters["oauth_consumer_key"] = self.consumerKey
        authorizationParameters["oauth_timestamp"] = timestamp
        authorizationParameters["oauth_nonce"] = nonce
        if let b = body, let hash = self.version.signatureMethod.sign(data: b) {
            authorizationParameters["oauth_body_hash"] = hash.base64EncodedString(options: [])
        }
        
        if !self.oauthToken.isEmpty {
            authorizationParameters["oauth_token"] = self.oauthToken
        }
        return authorizationParameters
    }
    
    open func signature(method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: OAuthSwift.Parameters) -> String {
        let encodedTokenSecret = self.oauthTokenSecret.urlEncodedString
        let encodedConsumerSecret = self.consumerSecret.urlEncodedString
        
        let signingKey = "\(encodedConsumerSecret)&\(encodedTokenSecret)"
        
        var parameterComponents = parameters.urlEncodedQuery.components(separatedBy: "&")
        parameterComponents.sort {
            let p0 = $0.components(separatedBy: "=")
            let p1 = $1.components(separatedBy: "=")
            if p0.first == p1.first { return p0.last ?? "" < p1.last ?? "" }
            return p0.first ?? "" < p1.first ?? ""
        }
        
        let parameterString = parameterComponents.joined(separator: "&")
        let encodedParameterString = parameterString.urlEncodedString
        
        let encodedURL = url.absoluteString.urlEncodedString
        
        let signatureBaseString = "\(method)&\(encodedURL)&\(encodedParameterString)"
        
        let key = signingKey.data(using: .utf8)!
        let msg = signatureBaseString.data(using: .utf8)!
        
        let sha1 = self.version.signatureMethod.sign(key: key, message: msg)!
        return sha1.base64EncodedString(options: [])
    }
    
    open func isTokenExpired() -> Bool {
        if let expiresDate = oauthTokenExpiresAt {
            return expiresDate <= Date()
        }
        
        // If no expires date is available we assume the token is still valid since it doesn't have an expiration date to check with.
        return false
    }
}
