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
    public typealias TokenSuccessHandler = (credential: OAuthSwiftCredential, response: NSURLResponse?, parameters: Dictionary<String, String>) -> Void
    public typealias FailureHandler = (error: NSError) -> Void

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
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
    var observer: AnyObject?

    func observeCallback(block: (url: NSURL) -> Void) {
        self.observer = NSNotificationCenter.defaultCenter().addObserverForName(CallbackNotification.notificationName, object: nil, queue: NSOperationQueue.mainQueue()){
            notification in
            NSNotificationCenter.defaultCenter().removeObserver(self.observer!)

            let urlFromUserInfo = notification.userInfo![CallbackNotification.optionsURLKey] as! NSURL
            block(url: urlFromUserInfo)
        }
    }
	
	// Clean up state from any existing requests
	public func invalidate() {
		NSNotificationCenter.defaultCenter().removeObserver(self.observer)
		authorize_url_handler = OAuthSwiftOpenURLExternally.sharedInstance
	}

}

// MARK: OAuthSwift errors
public let OAuthSwiftErrorDomain = "oauthswift.error"
