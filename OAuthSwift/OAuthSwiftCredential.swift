//
//  OAuthSwiftCredential.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/22/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//
import Foundation

public protocol OAuthSwiftCredentialHeadersFactory {
    func make(_ url:URL, method: OAuthSwiftHTTPRequest.Method, parameters: Dictionary<String, AnyObject>, body: Data?) -> Dictionary<String, String>
}

public class OAuthSwiftCredential: NSObject, NSCoding {

    public enum Version {
        case oAuth1, oAuth2
        
        public var shortVersion : String {
            switch self {
            case .oAuth1:
                return "1.0"
            case .oAuth2:
                return "2.0"
            }
        }
        
        public var signatureMethod: SignatureMethod {
            return SignatureMethod.HMAC_SHA1
        }
    }
    
    public enum SignatureMethod: String {
        case HMAC_SHA1 = "HMAC-SHA1"//, RSA_SHA1 = "RSA-SHA1", PLAINTEXT = "PLAINTEXT"
  
        func sign(_ key: Data, message: Data) -> Data? {
            switch (self) {
            case .HMAC_SHA1:
                return HMAC.sha1(key: key, message: message)
            }
        }
        
        func sign(_ data: Data) -> Data? {
            switch (self) {
            case .HMAC_SHA1:
                let mac = SHA1(data).calculate().bytes()
                return Data(bytes: UnsafePointer<UInt8>(mac), count: mac.count)
            }
        }
    }
    
    // MARK: attributes
    var consumer_key: String = String()
    var consumer_secret: String = String()
    public var oauth_token: String = String()
    public var oauth_refresh_token: String = String()
    public var oauth_token_secret: String = String()
    public var oauth_token_expires_at: Date? = nil
    public internal(set) var oauth_verifier: String = String()
    public var version: Version = .oAuth1
    
    // hook to replace headers creation
    public var headersFactory: OAuthSwiftCredentialHeadersFactory? = nil

    // MARK: init
    override init(){
        
    }
    public init(consumer_key: String, consumer_secret: String){
        self.consumer_key = consumer_key
        self.consumer_secret = consumer_secret
    }
    public init(oauth_token: String, oauth_token_secret: String){
        self.oauth_token = oauth_token
        self.oauth_token_secret = oauth_token_secret
    }
    
    
    // MARK: NSCoding protocol
    private struct CodingKeys {
        static let base = Bundle.main.bundleIdentifier! + "."
        static let consumerKey = base + "comsumer_key"
        static let consumerSecret = base + "consumer_secret"
        static let oauthToken = base + "oauth_token"
        static let oauthRefreshToken = base + "oauth_refresh_token"
        static let oauthTokenExpiresAt = base + "oauth_token_expires_at"
        static let oauthTokenSecret = base + "oauth_token_secret"
        static let oauthVerifier = base + "oauth_verifier"
    }
    
    // Cannot declare a required initializer within an extension.
    // extension OAuthSwiftCredential: NSCoding {
    public required convenience init?(coder decoder: NSCoder) {
        self.init()
        self.consumer_key = (decoder.decodeObject(forKey: CodingKeys.consumerKey) as? String) ?? String()
        self.consumer_secret = (decoder.decodeObject(forKey: CodingKeys.consumerSecret) as? String) ?? String()
        self.oauth_token = (decoder.decodeObject(forKey: CodingKeys.oauthToken) as? String) ?? String()
        self.oauth_refresh_token = (decoder.decodeObject(forKey: CodingKeys.oauthRefreshToken) as? String) ?? String()
        self.oauth_token_secret = (decoder.decodeObject(forKey: CodingKeys.oauthTokenSecret) as? String) ?? String()
        self.oauth_verifier = (decoder.decodeObject(forKey: CodingKeys.oauthVerifier) as? String) ?? String()
        self.oauth_token_expires_at = (decoder.decodeObject(forKey: CodingKeys.oauthTokenExpiresAt) as? Date)
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(self.consumer_key, forKey: CodingKeys.consumerKey)
        coder.encode(self.consumer_secret, forKey: CodingKeys.consumerSecret)
        coder.encode(self.oauth_token, forKey: CodingKeys.oauthToken)
        coder.encode(self.oauth_refresh_token, forKey: CodingKeys.oauthRefreshToken)
        coder.encode(self.oauth_token_secret, forKey: CodingKeys.oauthTokenSecret)
        coder.encode(self.oauth_verifier, forKey: CodingKeys.oauthVerifier)
        coder.encode(self.oauth_token_expires_at, forKey: CodingKeys.oauthTokenExpiresAt)
    }
    // } // End NSCoding extension

    
    // MARK: functions
    public func makeHeaders(_ url:URL, method: OAuthSwiftHTTPRequest.Method, parameters: Dictionary<String, AnyObject>, body: Data? = nil) -> Dictionary<String, String> {
        if let factory = headersFactory {
            return factory.make(url, method: method, parameters: parameters, body: body)
        }
        switch self.version {
        case .oAuth1:
            return ["Authorization": self.authorizationHeaderForMethod(method, url: url, parameters: parameters, body: body)]
        case .oAuth2:
            return self.oauth_token.isEmpty ? [:] : ["Authorization": "Bearer \(self.oauth_token)"]
        }
    }

    public func authorizationHeaderForMethod(_ method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: Dictionary<String, AnyObject>, body: Data? = nil) -> String {
        let timestamp = String(Int64(Date().timeIntervalSince1970))
        let nonce = OAuthSwiftCredential.generateNonce()
        return self.authorizationHeaderForMethod(method, url: url, parameters: parameters, body: body, timestamp: timestamp, nonce: nonce)
    }
    
    public class func generateNonce() -> String {
        return  (UUID().uuidString as NSString).substring(to: 8)
    }
  
    public func authorizationHeaderForMethod(_ method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: Dictionary<String, AnyObject>, body: Data? = nil, timestamp: String, nonce: String) -> String {
        assert(self.version == .oAuth1)
        let authorizationParameters = self.authorizationParametersWithSignatureForMethod(method, url: url, parameters: parameters, body: body, timestamp: timestamp, nonce: nonce)
        
        var parameterComponents = authorizationParameters.urlEncodedQueryStringWithEncoding(OAuthSwiftDataEncoding).components(separatedBy: "&") as [String]
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
    
    public func authorizationParametersWithSignatureForMethod(_ method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: Dictionary<String, AnyObject>, body: Data? = nil) -> Dictionary<String, AnyObject> {
        let timestamp = String(Int64(Date().timeIntervalSince1970))
        let nonce = OAuthSwiftCredential.generateNonce()
        return self.authorizationParametersWithSignatureForMethod(method, url: url, parameters: parameters, body: body, timestamp: timestamp, nonce: nonce)
    }

    public func authorizationParametersWithSignatureForMethod(_ method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: Dictionary<String, AnyObject>, body: Data? = nil, timestamp: String, nonce: String) -> Dictionary<String, AnyObject> {
        var authorizationParameters = self.authorizationParameters(body, timestamp: timestamp, nonce: nonce)
        
        for (key, value) in parameters {
            if key.hasPrefix("oauth_") {
                authorizationParameters.updateValue(value, forKey: key)
            }
        }
        
        let combinedParameters = authorizationParameters.join(parameters)
        
        authorizationParameters["oauth_signature"] = self.signatureForMethod(method, url: url, parameters: combinedParameters)
        
        return authorizationParameters;
    }
    
    public func authorizationParameters(_ body: Data?, timestamp: String, nonce: String) -> Dictionary<String, AnyObject> {
        var authorizationParameters = Dictionary<String, AnyObject>()
        authorizationParameters["oauth_version"] = self.version.shortVersion
        authorizationParameters["oauth_signature_method"] =  self.version.signatureMethod.rawValue
        authorizationParameters["oauth_consumer_key"] = self.consumer_key
        authorizationParameters["oauth_timestamp"] = timestamp
        authorizationParameters["oauth_nonce"] = nonce
        if let b = body, hash = self.version.signatureMethod.sign(b) {
            authorizationParameters["oauth_body_hash"] = hash.base64EncodedString(options: [])
        }
        
        if (self.oauth_token != ""){
            authorizationParameters["oauth_token"] = self.oauth_token
        }
        return authorizationParameters
    }

    public func signatureForMethod(_ method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: Dictionary<String, AnyObject>) -> String {
        var tokenSecret: NSString = ""
        tokenSecret = self.oauth_token_secret.urlEncodedStringWithEncoding(OAuthSwiftDataEncoding)
        
        let encodedConsumerSecret = self.consumer_secret.urlEncodedStringWithEncoding(OAuthSwiftDataEncoding)
        
        let signingKey = "\(encodedConsumerSecret)&\(tokenSecret)"
        
        var parameterComponents = parameters.urlEncodedQueryStringWithEncoding(OAuthSwiftDataEncoding).components(separatedBy: "&") as [String]
        parameterComponents.sort { $0 < $1 }
        
        let parameterString = parameterComponents.joined(separator: "&")
        let encodedParameterString = parameterString.urlEncodedStringWithEncoding(OAuthSwiftDataEncoding)
        
        let encodedURL = url.unsafeAbsoluteString.urlEncodedStringWithEncoding(OAuthSwiftDataEncoding)
        
        let signatureBaseString = "\(method)&\(encodedURL)&\(encodedParameterString)"
        
        let key = signingKey.data(using: String.Encoding.utf8)!
        let msg = signatureBaseString.data(using: String.Encoding.utf8)!

        let sha1 = self.version.signatureMethod.sign(key, message: msg)!
        return sha1.base64EncodedString(options: [])
    }
    
    public func isTokenExpired() -> Bool {
        if let expiresDate = oauth_token_expires_at {
            return expiresDate <= Date()
        }
        
        // If no expires date is available we assume the token is still valid since it doesn't have an expiration date to check with.
        return false;
    }
}
