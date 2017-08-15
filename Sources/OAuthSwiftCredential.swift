//
//  OAuthSwiftCredential.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/22/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//
import Foundation

/// Allow to customize computed headers
public protocol OAuthSwiftCredentialHeadersFactory {
    func make(_ url: URL, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters, body: Data?) -> [String: String]
}

/// The credential for authentification
open class OAuthSwiftCredential: NSObject, NSCoding {

    public enum Version {
        case oauth1, oauth2

        public var shortVersion: String {
            switch self {
            case .oauth1:
                return "1.0"
            case .oauth2:
                return "2.0"
            }
        }

        public var signatureMethod: SignatureMethod {
            return .HMAC_SHA1
        }

        var toInt32: Int32 {
            switch self {
            case .oauth1:
                return 1
            case .oauth2:
                return 2
            }
        }
        init(_ value: Int32) {
            switch value {
            case 1:
                self = .oauth1
            case 2:
                self = .oauth2
            default:
                self = .oauth1
            }
        }
    }

    public enum SignatureMethod: String {
        case HMAC_SHA1 = "HMAC-SHA1"//, RSA_SHA1 = "RSA-SHA1", PLAINTEXT = "PLAINTEXT"

        func sign(key: Data, message: Data) -> Data? {
            switch self {
            case .HMAC_SHA1:
                return HMAC.sha1(key: key, message: message)
            }
        }

        func sign(data: Data) -> Data? {
            switch self {
            case .HMAC_SHA1:
                let mac = SHA1(data).calculate()
                return Data(bytes: UnsafePointer<UInt8>(mac), count: mac.count)
            }
        }
    }

    // MARK: attributes
    open internal(set) var consumerKey = ""
    open internal(set) var consumerSecret = ""
    open var oauthToken = ""
    open var oauthRefreshToken = ""
    open var oauthTokenSecret = ""
    open var oauthTokenExpiresAt: Date?
    open internal(set) var oauthVerifier = ""
    open var version: Version = .oauth1

    /// hook to replace headers creation
    open var headersFactory: OAuthSwiftCredentialHeadersFactory?

    // MARK: init
    override init() {
    }

    public init(consumerKey: String, consumerSecret: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
    }

    // MARK: NSCoding protocol
    fileprivate struct CodingKeys {
        static let bundleId = Bundle.main.bundleIdentifier
            ?? Bundle(for: OAuthSwiftCredential.self).bundleIdentifier
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

    /// Cannot declare a required initializer within an extension.
    /// extension OAuthSwiftCredential: NSCoding {
    public required convenience init?(coder decoder: NSCoder) {
        self.init()
        self.consumerKey = (decoder.decodeObject(forKey: CodingKeys.consumerKey) as? String) ?? String()
        self.consumerSecret = (decoder.decodeObject(forKey: CodingKeys.consumerSecret) as? String) ?? String()
        self.oauthToken = (decoder.decodeObject(forKey: CodingKeys.oauthToken) as? String) ?? String()
        self.oauthRefreshToken = (decoder.decodeObject(forKey: CodingKeys.oauthRefreshToken) as? String) ?? String()
        self.oauthTokenSecret = (decoder.decodeObject(forKey: CodingKeys.oauthTokenSecret) as? String) ?? String()
        self.oauthVerifier = (decoder.decodeObject(forKey: CodingKeys.oauthVerifier) as? String) ?? String()
        self.oauthTokenExpiresAt = (decoder.decodeObject(forKey: CodingKeys.oauthTokenExpiresAt) as? Date)
        self.version = Version(decoder.decodeInt32(forKey: CodingKeys.version))
    }

    open func encode(with coder: NSCoder) {
        coder.encode(self.consumerKey, forKey: CodingKeys.consumerKey)
        coder.encode(self.consumerSecret, forKey: CodingKeys.consumerSecret)
        coder.encode(self.oauthToken, forKey: CodingKeys.oauthToken)
        coder.encode(self.oauthRefreshToken, forKey: CodingKeys.oauthRefreshToken)
        coder.encode(self.oauthTokenSecret, forKey: CodingKeys.oauthTokenSecret)
        coder.encode(self.oauthVerifier, forKey: CodingKeys.oauthVerifier)
        coder.encode(self.oauthTokenExpiresAt, forKey: CodingKeys.oauthTokenExpiresAt)
        coder.encode(self.version.toInt32, forKey: CodingKeys.version)
    }
    // } // End NSCoding extension

    // MARK: functions
    /// for OAuth1 parameters must contains sorted query parameters and url must not contains query parameters
    open func makeHeaders(_ url: URL, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters, body: Data? = nil) -> [String: String] {
        if let factory = headersFactory {
            return factory.make(url, method: method, parameters: parameters, body: body)
        }
        switch self.version {
        case .oauth1:
            return ["Authorization": self.authorizationHeader(method: method, url: url, parameters: parameters, body: body)]
        case .oauth2:
            return self.oauthToken.isEmpty ? [:] : ["Authorization": "Bearer \(self.oauthToken)"]
        }
    }

    open func authorizationHeader(method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: OAuthSwift.Parameters, body: Data? = nil) -> String {
        let timestamp = String(Int64(Date().timeIntervalSince1970))
        let nonce = OAuthSwiftCredential.generateNonce()
        return self.authorizationHeader(method: method, url: url, parameters: parameters, body: body, timestamp: timestamp, nonce: nonce)
    }

    open class func generateNonce() -> String {
        let uuidString = UUID().uuidString
        return uuidString.substring(to: 8)
    }

    open func authorizationHeader(method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: OAuthSwift.Parameters, body: Data? = nil, timestamp: String, nonce: String) -> String {
        assert(self.version == .oauth1)
        let authorizationParameters = self.authorizationParametersWithSignature(method: method, url: url, parameters: parameters, body: body, timestamp: timestamp, nonce: nonce)

        var parameterComponents = authorizationParameters.urlEncodedQuery.components(separatedBy: "&") as [String]
        parameterComponents.sort { $0 < $1 }

        var headerComponents = [String]()
        for component in parameterComponents {
            let subcomponent = component.components(separatedBy: "=") as [String]
            if subcomponent.count == 2 {
                headerComponents.append("\(subcomponent[0])=\"\(subcomponent[1])\"")
            }
        }

        return "OAuth " + headerComponents.joined(separator: ", ")
    }

    open func authorizationParametersWithSignature(method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: OAuthSwift.Parameters, body: Data? = nil) -> OAuthSwift.Parameters {
        let timestamp = String(Int64(Date().timeIntervalSince1970))
        let nonce = OAuthSwiftCredential.generateNonce()
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
        authorizationParameters["oauth_signature_method"] =  self.version.signatureMethod.rawValue
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
        let encodedTokenSecret = self.oauthTokenSecret.urlEncoded
        let encodedConsumerSecret = self.consumerSecret.urlEncoded

        let signingKey = "\(encodedConsumerSecret)&\(encodedTokenSecret)"

        var parameterComponents = parameters.urlEncodedQuery.components(separatedBy: "&")
        parameterComponents.sort {
            let p0 = $0.components(separatedBy: "=")
            let p1 = $1.components(separatedBy: "=")
            if p0.first == p1.first { return p0.last ?? "" < p1.last ?? "" }
            return p0.first ?? "" < p1.first ?? ""
        }

        let parameterString = parameterComponents.joined(separator: "&")
        let encodedParameterString = parameterString.urlEncoded

        let encodedURL = url.absoluteString.urlEncoded

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
