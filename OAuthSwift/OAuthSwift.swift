//
//  OAuthSwift.swift
//  OAuthSwift
//
//  Created by phimage on 04/12/15.
//  Copyright © 2015 Dongri Jin. All rights reserved.
//

import Foundation

public class OAuthSwift: NSObject {
    
    // MARK: Properties
    
    // Client to make signed request
    public var client: OAuthSwiftClient
    // Version of the protocol
    public var version: OAuthSwiftCredential.Version { return self.client.credential.version }
    
    // Handle the authorize url into a web view or browser
    public var authorize_url_handler: OAuthSwiftURLHandlerType = OAuthSwiftOpenURLExternally.sharedInstance

    // MARK: callback alias
    public typealias TokenSuccessHandler = (credential: OAuthSwiftCredential, response: NSURLResponse?, parameters: Dictionary<String, AnyObject>) -> Void
    public typealias FailureHandler = (error: NSError) -> Void
    public typealias TokenRenewedHandler = (credential: OAuthSwiftCredential) -> Void
    
    // MARK: init
    init(consumerKey: String, consumerSecret: String) {
        self.client = OAuthSwiftClient(consumerKey: consumerKey, consumerSecret: consumerSecret)
    }

    // MARK: callback notification
    struct CallbackNotification {
        static let notificationName = "OAuthSwiftCallbackNotificationName"
        static let optionsURLKey = "OAuthSwiftCallbackNotificationOptionsURLKey"
    }

    // Handle callback url which contains now token information
    public class func handleOpenURL(url: NSURL) {
        let notification = NSNotification(name: CallbackNotification.notificationName, object: nil,
            userInfo: [CallbackNotification.optionsURLKey: url])
        notificationCenter.postNotification(notification)
    }

    var observer: AnyObject?
    class var notificationCenter: NSNotificationCenter {
        return NSNotificationCenter.defaultCenter()
    }

    func observeCallback(block: (url: NSURL) -> Void) {
        self.observer = OAuthSwift.notificationCenter.addObserverForName(CallbackNotification.notificationName, object: nil, queue: NSOperationQueue.mainQueue()){
            notification in
            self.removeCallbackNotificationObserver()

            let urlFromUserInfo = notification.userInfo![CallbackNotification.optionsURLKey] as! NSURL
            block(url: urlFromUserInfo)
        }
    }

    public func removeCallbackNotificationObserver() {
      	if let observer = self.observer {
            OAuthSwift.notificationCenter.removeObserver(observer)
        }
    }

}


// MARK: OAuthSwift errors
public let OAuthSwiftErrorDomain = "oauthswift.error"

public let OAuthSwiftErrorResponseDataKey = "oauthswift.error.response.data"
public let OAuthSwiftErrorResponseKey = "oauthswift.error.response"

public enum OAuthSwiftErrorCode: Int {
    case GeneralError = -1
    case TokenExpiredError = -2
    case MissingStateError = -3
    case StateNotEqualError = -4
    case ServerError = -5
    case EncodingError = -6
    case AuthorizationPending = -7
}