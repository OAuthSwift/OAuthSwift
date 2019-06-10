//
//  OAuthSwift.swift
//  OAuthSwift
//
//  Created by phimage on 04/12/15.
//  Copyright © 2015 Dongri Jin. All rights reserved.
//

import Foundation

open class OAuthSwift: NSObject, OAuthSwiftRequestHandle {

    // MARK: Properties

    /// Client to make signed request
    open var client: OAuthSwiftClient
    /// Version of the protocol
    open var version: OAuthSwiftCredential.Version { return self.client.credential.version }

    /// Handle the authorize url into a web view or browser
    open var authorizeURLHandler: OAuthSwiftURLHandlerType = OAuthSwiftOpenURLExternally.sharedInstance

    fileprivate var currentRequests: [String: OAuthSwiftRequestHandle] = [:]

    // MARK: init
    init(consumerKey: String, consumerSecret: String) {
        self.client = OAuthSwiftClient(consumerKey: consumerKey, consumerSecret: consumerSecret)
    }

    // MARK: callback notification
    struct CallbackNotification {
        static let optionsURLKey = "OAuthSwiftCallbackNotificationOptionsURLKey"
    }

    /// Handle callback url which contains now token information
    open class func handle(url: URL) {
        let notification = Notification(name: OAuthSwift.didHandleCallbackURL, object: nil,
            userInfo: [CallbackNotification.optionsURLKey: url])
        notificationCenter.post(notification)
    }

    var observer: NSObjectProtocol?
    open class var notificationCenter: NotificationCenter {
        return NotificationCenter.default
    }
    open class var notificationQueue: OperationQueue {
        return OperationQueue.main
    }

    func observeCallback(_ block: @escaping (_ url: URL) -> Void) {
        self.observer = OAuthSwift.notificationCenter.addObserver(
            forName: OAuthSwift.didHandleCallbackURL,
            object: nil,
            queue: OperationQueue.main) { [weak self] notification in
                self?.removeCallbackNotificationObserver()

            if let urlFromUserInfo = notification.userInfo?[CallbackNotification.optionsURLKey] as? URL {
                block(urlFromUserInfo)
            } else {
                // Internal error
                assertionFailure()
            }
        }
    }

    /// Remove internal observer on authentification
    public func removeCallbackNotificationObserver() {
        if let observer = self.observer {
            OAuthSwift.notificationCenter.removeObserver(observer)
        }
    }

    /// Function to call when web view is dismissed without authentification
    public func cancel() {
        self.removeCallbackNotificationObserver()
        for (_, request) in self.currentRequests {
            request.cancel()
        }
        self.currentRequests = [:]
    }

    func putHandle(_ handle: OAuthSwiftRequestHandle, withKey key: String) {
        // self.currentRequests[withKey] = handle
        // TODO before storing handle, find a way to remove it when network request end (ie. all failure and success ie. complete)
    }

    /// Run block in main thread
    static func main(block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }

}

// MARK: - alias
extension OAuthSwift {

    public typealias Parameters = [String: Any]
    public typealias Headers = [String: String]
    public typealias ConfigParameters = [String: String]
    /// MARK: callback alias
    public typealias TokenSuccess = (credential: OAuthSwiftCredential, response: OAuthSwiftResponse?, parameters: Parameters)
    public typealias TokenCompletionHandler = (Result<TokenSuccess, OAuthSwiftError>) -> Void
    public typealias TokenRenewedHandler = (Result<OAuthSwiftCredential, Never>) -> Void
}
