//
//  OAuthSwift.swift
//  OAuthSwift
//
//  Created by phimage on 12/05/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//
import Foundation

// OAuthSwift errors
public let OAuthSwiftErrorDomain = "oauthswift.error"

public class OAuthSwift: NSObject {

    public var client: OAuthSwiftClient
    
    public var authorize_url_handler: OAuthSwiftURLHandlerType = OAuthSwiftOpenURLExternally.sharedInstance
    
    public var allowMissingOauthVerifier: Bool = false
    
    var consumer_key: String
    var consumer_secret: String
    
    var observer: AnyObject?
    
    init(consumerKey: String, consumerSecret: String) {
        self.consumer_key = consumerKey
        self.consumer_secret = consumerSecret
        self.client = OAuthSwiftClient(consumerKey: consumerKey, consumerSecret: consumerSecret)
    }
    
    struct CallbackNotification {
        static let notificationName = "OAuthSwiftCallbackNotificationName"
        static let optionsURLKey = "OAuthSwiftCallbackNotificationOptionsURLKey"
    }
    
    struct OAuthSwiftError {
        static let domain = "OAuthSwiftErrorDomain"
        static let appOnlyAuthenticationErrorCode = 1
    }

    public typealias TokenSuccessHandler = (credential: OAuthSwiftCredential, response: NSURLResponse?, parameters: NSDictionary) -> Void
    public typealias FailureHandler = (error: NSError) -> Void
    
    public class func handleOpenURL(url: NSURL) {
        let notification = NSNotification(name: CallbackNotification.notificationName, object: nil,
            userInfo: [CallbackNotification.optionsURLKey: url])
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
}
