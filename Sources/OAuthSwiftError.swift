//
//  OAuthSwiftError.swift
//  OAuthSwift
//
//  Created by phimage on 02/10/16.
//  Copyright © 2016 Dongri Jin. All rights reserved.
//

import Foundation

// MARK: - OAuthSwift errors
public enum OAuthSwiftError: Error {
    // Configuration problem with oauth provider.
    case configurationError(message: String)
    // The provided token is expired, retrieve new token by using the refresh token
    case tokenExpired(error: Error?)
    // State missing from request (you can set allowMissingStateCheck = true to ignore)
    case missingState
    // Returned state value is wrong
    case stateNotEqual(state: String, responseState: String)
    // Error from server
    case serverError(message: String)
    // Failed to create URL \(urlString) not convertible to URL, please encode
    case encodingError(urlString: String)
    case authorizationPending
    // Failed to create request with \(urlString)
    case requestCreation(message: String)
    // Authentification failed. No token
    case missingToken
    // Please retain OAuthSwift object or handle
    case retain
    // Request error
    case requestError(error: Error)
    // Request cancelled
    case cancelled
    
    public static let Domain = "OAuthSwiftError"
    public static let ResponseDataKey = "OAuthSwiftError.response.data"
    public static let ResponseKey = "OAuthSwiftError.response"
    
    fileprivate enum Code : Int {
        case configurationError = -1
        case tokenExpired = -2
        case missingState = -3
        case stateNotEqual = -4
        case serverError = -5
        case encodingError = -6
        case authorizationPending = -7
        case requestCreation = -8
        case missingToken = -9
        case retain = -10
        case requestError = -11
        case cancelled = -12
    }
    
    fileprivate var code: Code {
        switch self {
        case .configurationError: return Code.configurationError
        case .tokenExpired: return Code.tokenExpired
        case .missingState: return Code.missingState
        case .stateNotEqual: return Code.stateNotEqual
        case .serverError: return Code.serverError
        case .encodingError: return Code.encodingError
        case .authorizationPending: return Code.authorizationPending
        case .requestCreation: return Code.requestCreation
        case .missingToken: return Code.missingToken
        case .retain: return Code.retain
        case .requestError: return Code.requestError
        case .cancelled : return Code.cancelled
        }
    }
    // For NSError
    public var _code: Int {
        return self.code.rawValue
    }
    public var _domain: String {
        return OAuthSwiftError.Domain
    }
}

extension NSError {
    fileprivate convenience init(code: OAuthSwiftError.Code, message: String, errorKey: String = NSLocalizedFailureReasonErrorKey) {
        let userInfo = [errorKey: message]
        self.init(domain: OAuthSwiftError.Domain, code: code.rawValue, userInfo: userInfo)
    }
}

extension OAuthSwiftError {
    
    var nsError: NSError {
        return NSError(code: self.code, message: "")
    }
    
}

extension OAuthSwift {
    
    static func retainError(_ failureHandler: FailureHandler?) {
        #if !OAUTH_NO_RETAIN_ERROR
            failureHandler?(OAuthSwiftError.retain)
        #endif
    }
    
}
