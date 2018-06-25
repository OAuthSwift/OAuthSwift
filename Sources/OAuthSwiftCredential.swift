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

/// Allow to sign
// swiftlint:disable:next class_delegate_protocol
public protocol OAuthSwiftSignatureDelegate {
    static func sign(hashMethod: OAuthSwiftHashMethod, key: Data, message: Data) -> Data?
}

// The hash method used.
public enum OAuthSwiftHashMethod: String {
    case sha1
    case none

    func hash(data: Data) -> Data? {
        switch self {
        case .sha1:
            let mac = SHA1(data).calculate()
            return Data(bytes: UnsafePointer<UInt8>(mac), count: mac.count)
        case .none:
            return data
        }
    }
}

/// The credential for authentification
open class OAuthSwiftCredential: NSObject, NSSecureCoding, Codable {

    public static let supportsSecureCoding = true

    public enum Version: Codable {
        case oauth1, oauth2

        public var shortVersion: String {
            switch self {
            case .oauth1:
                return "1.0"
            case .oauth2:
                return "2.0"
            }
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

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.toInt32)
        }

        public init(from decoder: Decoder) throws {
            self.init(try decoder.singleValueContainer().decode(Int32.self))
        }
    }

    public enum SignatureMethod: String {
        case HMAC_SHA1 = "HMAC-SHA1"
        case RSA_SHA1 = "RSA-SHA1"
        case PLAINTEXT = "PLAINTEXT"

        public static var delegates: [SignatureMethod: OAuthSwiftSignatureDelegate.Type] =
            [HMAC_SHA1: HMAC.self]

        var hashMethod: OAuthSwiftHashMethod {
            switch self {
            case .HMAC_SHA1, .RSA_SHA1:
                return .sha1
            case .PLAINTEXT:
                return .none
            }
        }

        func sign(key: Data, message: Data) -> Data? {
            if let delegate = SignatureMethod.delegates[self] {
                return delegate.sign(hashMethod: self.hashMethod, key: key, message: message)
            }
            assert(self == .PLAINTEXT, "No signature method installed for \(self)")
            return message
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
    open var signatureMethod: SignatureMethod = .HMAC_SHA1

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
    fileprivate struct NSCodingKeys {
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
        static let signatureMethod = base + "signatureMethod"
    }

    /// Cannot declare a required initializer within an extension.
    /// extension OAuthSwiftCredential: NSCoding {
    public required convenience init?(coder decoder: NSCoder) {

        guard let consumerKey = decoder
            .decodeObject(of: NSString.self,
                          forKey: NSCodingKeys.consumerKey) as String? else {
            if #available(iOS 9, OSX 10.11, *) {
                let error = CocoaError.error(.coderValueNotFound)
                decoder.failWithError(error)
            }
            return nil
        }

        guard let consumerSecret = decoder
            .decodeObject(of: NSString.self,
                          forKey: NSCodingKeys.consumerSecret) as String? else {
            if #available(iOS 9, OSX 10.11, *) {
                let error = CocoaError.error(.coderValueNotFound)
                decoder.failWithError(error)
            }
            return nil
        }
        self.init(consumerKey: consumerKey, consumerSecret: consumerSecret)

        guard let oauthToken = decoder
            .decodeObject(of: NSString.self,
                          forKey: NSCodingKeys.oauthToken) as String? else {
            if #available(iOS 9, OSX 10.11, *) {
                let error = CocoaError.error(.coderValueNotFound)
                decoder.failWithError(error)
            }
            return nil
        }
        self.oauthToken = oauthToken

        guard let oauthRefreshToken = decoder
            .decodeObject(of: NSString.self,
                          forKey: NSCodingKeys.oauthRefreshToken) as String? else {
            if #available(iOS 9, OSX 10.11, *) {
                let error = CocoaError.error(.coderValueNotFound)
                decoder.failWithError(error)
            }
            return nil
        }
        self.oauthRefreshToken = oauthRefreshToken

        guard let oauthTokenSecret = decoder
            .decodeObject(of: NSString.self,
                          forKey: NSCodingKeys.oauthTokenSecret) as String? else {
            if #available(iOS 9, OSX 10.11, *) {
                let error = CocoaError.error(.coderValueNotFound)
                decoder.failWithError(error)
            }
            return nil
        }
        self.oauthTokenSecret = oauthTokenSecret

        guard let oauthVerifier = decoder
            .decodeObject(of: NSString.self,
                          forKey: NSCodingKeys.oauthVerifier) as String? else {
            if #available(iOS 9, OSX 10.11, *) {
                    let error = CocoaError.error(.coderValueNotFound)
                    decoder.failWithError(error)
            }
            return nil
        }
        self.oauthVerifier = oauthVerifier

        self.oauthTokenExpiresAt = decoder
            .decodeObject(of: NSDate.self, forKey: NSCodingKeys.oauthTokenExpiresAt) as Date?
        self.version = Version(decoder.decodeInt32(forKey: NSCodingKeys.version))
        if case .oauth1 = version {
            self.signatureMethod = SignatureMethod(rawValue: (decoder.decodeObject(of: NSString.self, forKey: NSCodingKeys.signatureMethod) as String?) ?? "HMAC_SHA1") ?? .HMAC_SHA1
        }
    }

    open func encode(with coder: NSCoder) {
        coder.encode(self.consumerKey, forKey: NSCodingKeys.consumerKey)
        coder.encode(self.consumerSecret, forKey: NSCodingKeys.consumerSecret)
        coder.encode(self.oauthToken, forKey: NSCodingKeys.oauthToken)
        coder.encode(self.oauthRefreshToken, forKey: NSCodingKeys.oauthRefreshToken)
        coder.encode(self.oauthTokenSecret, forKey: NSCodingKeys.oauthTokenSecret)
        coder.encode(self.oauthVerifier, forKey: NSCodingKeys.oauthVerifier)
        coder.encode(self.oauthTokenExpiresAt, forKey: NSCodingKeys.oauthTokenExpiresAt)
        coder.encode(self.version.toInt32, forKey: NSCodingKeys.version)
        if case .oauth1 = version {
            coder.encode(self.signatureMethod.rawValue, forKey: NSCodingKeys.signatureMethod)
        }
    }
    // } // End NSCoding extension

    // MARK: Codable protocol
    enum CodingKeys: String, CodingKey {
        case consumerKey
        case consumerSecret
        case oauthToken
        case oauthRefreshToken
        case oauthTokenSecret
        case oauthVerifier
        case oauthTokenExpiresAt
        case version
        case signatureMethodRawValue
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.consumerKey, forKey: .consumerKey)
        try container.encode(self.consumerSecret, forKey: .consumerSecret)
        try container.encode(self.oauthToken, forKey: .oauthToken)
        try container.encode(self.oauthRefreshToken, forKey: .oauthRefreshToken)
        try container.encode(self.oauthTokenSecret, forKey: .oauthTokenSecret)
        try container.encode(self.oauthVerifier, forKey: .oauthVerifier)
        try container.encodeIfPresent(self.oauthTokenExpiresAt, forKey: .oauthTokenExpiresAt)
        try container.encode(self.version, forKey: .version)
        if case .oauth1 = version {
            try container.encode(self.signatureMethod.rawValue, forKey: .signatureMethodRawValue)
        }
    }

    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init()

        self.consumerKey = try container.decode(String.self, forKey: .consumerKey)
        self.consumerSecret = try container.decode(String.self, forKey: .consumerSecret)

        self.oauthToken = try container.decode(type(of: self.oauthToken), forKey: .oauthToken)
        self.oauthRefreshToken = try container.decode(type(of: self.oauthRefreshToken), forKey: .oauthRefreshToken)
        self.oauthTokenSecret = try container.decode(type(of: self.oauthTokenSecret), forKey: .oauthTokenSecret)
        self.oauthVerifier = try container.decode(type(of: self.oauthVerifier), forKey: .oauthVerifier)
        self.oauthTokenExpiresAt = try container.decodeIfPresent(Date.self, forKey: .oauthTokenExpiresAt)
        self.version = try container.decode(type(of: self.version), forKey: .version)

        if case .oauth1 = version {
            self.signatureMethod = SignatureMethod(rawValue: try container.decode(type(of: self.signatureMethod.rawValue), forKey: .signatureMethodRawValue))!
        }
    }

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
        let uuidString: String = UUID().uuidString
        return uuidString[0..<8]
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
        authorizationParameters["oauth_signature_method"] =  self.signatureMethod.rawValue
        authorizationParameters["oauth_consumer_key"] = self.consumerKey
        authorizationParameters["oauth_timestamp"] = timestamp
        authorizationParameters["oauth_nonce"] = nonce
        if let b = body, let hash = self.signatureMethod.hashMethod.hash(data: b) {
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

        let sha1 = self.signatureMethod.sign(key: key, message: msg)!
        return sha1.base64EncodedString(options: [])
    }

    open func isTokenExpired() -> Bool {
        if let expiresDate = oauthTokenExpiresAt {
            return expiresDate <= Date()
        }

        // If no expires date is available we assume the token is still valid since it doesn't have an expiration date to check with.
        return false
    }

    // MARK: Equatable

    override open func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? OAuthSwiftCredential else {
            return false
        }
        let lhs = self
        return lhs.consumerKey == rhs.consumerKey
            && lhs.consumerSecret == rhs.consumerSecret
            && lhs.oauthToken == rhs.oauthToken
            && lhs.oauthRefreshToken == rhs.oauthRefreshToken
            && lhs.oauthTokenSecret == rhs.oauthTokenSecret
            && lhs.oauthTokenExpiresAt == rhs.oauthTokenExpiresAt
            && lhs.oauthVerifier == rhs.oauthVerifier
            && lhs.version == rhs.version
            && lhs.signatureMethod == rhs.signatureMethod
    }

}
