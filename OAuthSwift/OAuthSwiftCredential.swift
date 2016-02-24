//
//  OAuthSwiftCredential.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/22/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//
import Foundation

public class OAuthSwiftCredential: NSObject, NSCoding {

    public enum Version {
        case OAuth1, OAuth2
        
        public var shortVersion : String {
            switch self {
            case .OAuth1:
                return "1.0"
            case .OAuth2:
                return "2.0"
            }
        }
        
        public var signatureMethod: SignatureMethod {
            return SignatureMethod.HMAC_SHA1
        }
    }
    
    public enum SignatureMethod: String {
        case HMAC_SHA1 = "HMAC-SHA1"//, RSA_SHA1 = "RSA-SHA1", PLAINTEXT = "PLAINTEXT"
  
        func sign(key: NSData, message: NSData) -> NSData? {
            switch (self) {
            case .HMAC_SHA1:
                return HMAC.sha1(key: key, message: message)
            }
        }
        
        func sign(data: NSData) -> NSData? {
            switch (self) {
            case .HMAC_SHA1:
                let mac = SHA1(data).calculate().bytes()
                return NSData(bytes: mac, length: mac.count)
            }
        }
    }
    
    var consumer_key: String = String()
    var consumer_secret: String = String()
    public var oauth_token: String = String()
    public var oauth_token_secret: String = String()
    public internal(set) var oauth_verifier: String = String()
    public var version: Version = .OAuth1
    
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
    
    private struct CodingKeys {
        static let base = NSBundle.mainBundle().bundleIdentifier! + "."
        static let consumerKey = base + "comsumer_key"
        static let consumerSecret = base + "consumer_secret"
        static let oauthToken = base + "oauth_token"
        static let oauthTokenSecret = base + "oauth_token_secret"
        static let oauthVerifier = base + "oauth_verifier"
    }
    
    // Cannot declare a required initializer within an extension.
    // extension OAuthSwiftCredential: NSCoding {
    public required convenience init?(coder decoder: NSCoder) {
        self.init()
        self.consumer_key = (decoder.decodeObjectForKey(CodingKeys.consumerKey) as? String) ?? String()
        self.consumer_secret = (decoder.decodeObjectForKey(CodingKeys.consumerSecret) as? String) ?? String()
        self.oauth_token = (decoder.decodeObjectForKey(CodingKeys.oauthToken) as? String) ?? String()
        self.oauth_token_secret = (decoder.decodeObjectForKey(CodingKeys.oauthTokenSecret) as? String) ?? String()
        self.oauth_verifier = (decoder.decodeObjectForKey(CodingKeys.oauthVerifier) as? String) ?? String()
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.consumer_key, forKey: CodingKeys.consumerKey)
        coder.encodeObject(self.consumer_secret, forKey: CodingKeys.consumerSecret)
        coder.encodeObject(self.oauth_token, forKey: CodingKeys.oauthToken)
        coder.encodeObject(self.oauth_token_secret, forKey: CodingKeys.oauthTokenSecret)
        coder.encodeObject(self.oauth_verifier, forKey: CodingKeys.oauthVerifier)
    }
    // } // End NSCoding extension

    public func makeHeaders(url:NSURL, method: OAuthSwiftHTTPRequest.Method, parameters: Dictionary<String, AnyObject>, body: NSData? = nil) -> Dictionary<String, String> {
        switch self.version {
        case .OAuth1:
            return ["Authorization": self.authorizationHeaderForMethod(method, url: url, parameters: parameters, body: body)]
        case .OAuth2:
            return self.oauth_token.isEmpty ? [:] : ["Authorization": "Bearer \(self.oauth_token)"]
        }
    }

    public func authorizationHeaderForMethod(method: OAuthSwiftHTTPRequest.Method, url: NSURL, parameters: Dictionary<String, AnyObject>, body: NSData? = nil) -> String {
        let timestamp = String(Int64(NSDate().timeIntervalSince1970))
        let nonce = OAuthSwiftCredential.generateNonce()
        return self.authorizationHeaderForMethod(method, url: url, parameters: parameters, body: body, timestamp: timestamp, nonce: nonce)
    }
    
    public class func generateNonce() -> String {
        return  (NSUUID().UUIDString as NSString).substringToIndex(8)
    }
  
    public func authorizationHeaderForMethod(method: OAuthSwiftHTTPRequest.Method, url: NSURL, parameters: Dictionary<String, AnyObject>, body: NSData? = nil, timestamp: String, nonce: String) -> String {
        assert(self.version == .OAuth1)
        let authorizationParameters = self.authorizationParametersWithSignatureForMethod(method, url: url, parameters: parameters, body: body, timestamp: timestamp, nonce: nonce)
        
        var parameterComponents = authorizationParameters.urlEncodedQueryStringWithEncoding(OAuthSwiftDataEncoding).componentsSeparatedByString("&") as [String]
        parameterComponents.sortInPlace { $0 < $1 }
        
        var headerComponents = [String]()
        for component in parameterComponents {
            let subcomponent = component.componentsSeparatedByString("=") as [String]
            if subcomponent.count == 2 {
                headerComponents.append("\(subcomponent[0])=\"\(subcomponent[1])\"")
            }
        }
        
        return "OAuth " + headerComponents.joinWithSeparator(", ")
    }
    
    public func authorizationParametersWithSignatureForMethod(method: OAuthSwiftHTTPRequest.Method, url: NSURL, parameters: Dictionary<String, AnyObject>, body: NSData? = nil) -> Dictionary<String, AnyObject> {
        let timestamp = String(Int64(NSDate().timeIntervalSince1970))
        let nonce = OAuthSwiftCredential.generateNonce()
        return self.authorizationParametersWithSignatureForMethod(method, url: url, parameters: parameters, body: body, timestamp: timestamp, nonce: nonce)
    }

    public func authorizationParametersWithSignatureForMethod(method: OAuthSwiftHTTPRequest.Method, url: NSURL, parameters: Dictionary<String, AnyObject>, body: NSData? = nil, timestamp: String, nonce: String) -> Dictionary<String, AnyObject> {
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
    
    public func authorizationParameters(body: NSData?, timestamp: String, nonce: String) -> Dictionary<String, AnyObject> {
        var authorizationParameters = Dictionary<String, AnyObject>()
        authorizationParameters["oauth_version"] = self.version.shortVersion
        authorizationParameters["oauth_signature_method"] =  self.version.signatureMethod.rawValue
        authorizationParameters["oauth_consumer_key"] = self.consumer_key
        authorizationParameters["oauth_timestamp"] = timestamp
        authorizationParameters["oauth_nonce"] = nonce
        if let b = body, hash = self.version.signatureMethod.sign(b) {
            authorizationParameters["oauth_body_hash"] = hash.base64EncodedStringWithOptions([])
        }
        
        if (self.oauth_token != ""){
            authorizationParameters["oauth_token"] = self.oauth_token
        }
        return authorizationParameters
    }

    public func signatureForMethod(method: OAuthSwiftHTTPRequest.Method, url: NSURL, parameters: Dictionary<String, AnyObject>) -> String {
        var tokenSecret: NSString = ""
        tokenSecret = self.oauth_token_secret.urlEncodedStringWithEncoding(OAuthSwiftDataEncoding)
        
        let encodedConsumerSecret = self.consumer_secret.urlEncodedStringWithEncoding(OAuthSwiftDataEncoding)
        
        let signingKey = "\(encodedConsumerSecret)&\(tokenSecret)"
        
        var parameterComponents = parameters.urlEncodedQueryStringWithEncoding(OAuthSwiftDataEncoding).componentsSeparatedByString("&") as [String]
        parameterComponents.sortInPlace { $0 < $1 }
        
        let parameterString = parameterComponents.joinWithSeparator("&")
        let encodedParameterString = parameterString.urlEncodedStringWithEncoding(OAuthSwiftDataEncoding)
        
        let encodedURL = url.absoluteString.urlEncodedStringWithEncoding(OAuthSwiftDataEncoding)
        
        let signatureBaseString = "\(method)&\(encodedURL)&\(encodedParameterString)"
        
        let key = signingKey.dataUsingEncoding(NSUTF8StringEncoding)!
        let msg = signatureBaseString.dataUsingEncoding(NSUTF8StringEncoding)!

        let sha1 = self.version.signatureMethod.sign(key, message: msg)!
        return sha1.base64EncodedStringWithOptions([])
    }
}
