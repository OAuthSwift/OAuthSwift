//
//  OAuthSwift.swift
//  OAuthSwift
//
//  Created by phimage on 04/12/15.
//  Copyright © 2015 Dongri Jin. All rights reserved.
//

import Foundation

open class OAuthSwift: NSObject {
    
    // MARK: Properties
    
    // Client to make signed request
    open var client: OAuthSwiftClient
    // Version of the protocol
    open var version: OAuthSwiftCredential.Version { return self.client.credential.version }
    
    // Handle the authorize url into a web view or browser
    open var authorize_url_handler: OAuthSwiftURLHandlerType = OAuthSwiftOpenURLExternally.sharedInstance

    // MARK: callback alias
    public typealias TokenSuccessHandler = (_ credential: OAuthSwiftCredential, _ response: URLResponse?, _ parameters: [String: Any]) -> Void
    public typealias FailureHandler = (_ error: NSError) -> Void
    public typealias TokenRenewedHandler = (_ credential: OAuthSwiftCredential) -> Void
    
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
    open class func handleOpenURL(_ url: URL) {
        let notification = Notification(name: Notification.Name(rawValue: CallbackNotification.notificationName), object: nil,
            userInfo: [CallbackNotification.optionsURLKey: url])
        notificationCenter.post(notification)
    }

    var observer: AnyObject?
    class var notificationCenter: NotificationCenter {
        return NotificationCenter.default
    }

    func observeCallback(_ block: @escaping (_ url: URL) -> Void) {
        self.observer = OAuthSwift.notificationCenter.addObserver(forName: NSNotification.Name(rawValue: CallbackNotification.notificationName), object: nil, queue: OperationQueue.main){
            notification in
            self.removeCallbackNotificationObserver()

            let urlFromUserInfo = (notification as NSNotification).userInfo![CallbackNotification.optionsURLKey] as! URL
            block(urlFromUserInfo)
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
    case generalError = -1
    case tokenExpiredError = -2
    case missingStateError = -3
    case stateNotEqualError = -4
    case serverError = -5
    case encodingError = -6
    case authorizationPending = -7
}
