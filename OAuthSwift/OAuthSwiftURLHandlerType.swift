//
//  OAuthSwiftURLHandlerType.swift
//  OAuthSwift
//
//  Created by phimage on 11/05/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
    import UIKit
#elseif os(watchOS)
    import WatchKit
#elseif os(OSX)
    import AppKit
#endif

@objc public protocol OAuthSwiftURLHandlerType {
    func handle(url: NSURL)
}

// MARK: Open externally
public class OAuthSwiftOpenURLExternally: OAuthSwiftURLHandlerType {
    public class var sharedInstance : OAuthSwiftOpenURLExternally {
        struct Static {
            static var onceToken : dispatch_once_t = 0
            static var instance : OAuthSwiftOpenURLExternally? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = OAuthSwiftOpenURLExternally()
        }
        return Static.instance!
    }
    
    @objc public func handle(url: NSURL) {
        #if os(iOS) || os(tvOS)
            #if !OAUTH_APP_EXTENSIONS
                UIApplication.sharedApplication().openURL(url)
            #endif
        #elseif os(watchOS)
        // WATCHOS: not implemented
        #elseif os(OSX)
            NSWorkspace.sharedWorkspace().openURL(url)
        #endif
    }
}

// MARK: Open SFSafariViewController
#if os(iOS)
import SafariServices
    
    @available(iOS 9.0, *)
    public class SafariURLHandler: NSObject, OAuthSwiftURLHandlerType, SFSafariViewControllerDelegate {
        
        public typealias UITransion = (controller: SFSafariViewController, handler: SafariURLHandler) -> Void

        public let oauthSwift: OAuthSwift
        public var present: UITransion
        public var dismiss: UITransion
        // retains observers
        var observers = [String: AnyObject]()

        public var factory: (URL: NSURL) -> SFSafariViewController = {URL in
            return SFSafariViewController(URL: URL)
        }
        
        // delegates
        public var delegate: SFSafariViewControllerDelegate?

        // configure default presentation and dismissal code

        public var animated: Bool = true
        public var presentCompletion: (() -> Void)?
        public var dismissCompletion: (() -> Void)?
        public var delay: UInt32? = 1
        
        // init
        public init(viewController: UIViewController, oauthSwift: OAuthSwift) {
            self.oauthSwift = oauthSwift
            self.present = { controller, handler in
                viewController.presentViewController(controller, animated: handler.animated, completion: handler.presentCompletion)
            }
            self.dismiss = { controller, handler in
                viewController.dismissViewControllerAnimated(handler.animated, completion: handler.dismissCompletion)
            }
        }

        public init(present: UITransion, dismiss: UITransion, oauthSwift: OAuthSwift) {
            self.oauthSwift = oauthSwift
            self.present = present
            self.dismiss = dismiss
        }

        @objc public func handle(url: NSURL) {
            let controller = factory(URL: url)
            controller.delegate = self
            
            // present controller in main thread
            OAuthSwift.main { [unowned self] in
                if let delay = self.delay { // sometimes safari show a blank view..
                    sleep(delay)
                }
                self.present(controller: controller, handler: self)
            }
 
            let key = NSUUID().UUIDString

            observers[key] = OAuthSwift.notificationCenter.addObserverForName(
                OAuthSwift.CallbackNotification.notificationName,
                object: nil,
                queue: NSOperationQueue.mainQueue(),
                usingBlock:{ [weak self]
                    notification in
                    guard let this = self else {
                        return
                    }
                    if let observer = this.observers[key] {
                        OAuthSwift.notificationCenter.removeObserver(observer)
                        this.observers.removeValueForKey(key)
                    }
                    OAuthSwift.main {
                        this.dismiss(controller: controller, handler: this)
                    }
                }
            )
        }

        // Clear internal observers on authentification flow
        public func clearObservers() {
            clearLocalObservers()
            self.oauthSwift.removeCallbackNotificationObserver()
        }

        public func clearLocalObservers() {
            for (_, observer) in observers {
                OAuthSwift.notificationCenter.removeObserver(observer)
            }
            observers.removeAll()
        }
        
        // SFSafariViewControllerDelegate
        public func safariViewController(controller: SFSafariViewController, activityItemsForURL URL: NSURL, title: String?) -> [UIActivity] {
            return self.delegate?.safariViewController?(controller, activityItemsForURL: URL, title: title) ?? []
        }

        public func safariViewControllerDidFinish(controller: SFSafariViewController) {
            // "Done" pressed
            self.clearObservers()
            self.delegate?.safariViewControllerDidFinish?(controller)
        }
 
        public func safariViewController(controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
            self.delegate?.safariViewController?(controller, didCompleteInitialLoad: didLoadSuccessfully)
        }
        
    }

#endif


// MARK: Open url using NSExtensionContext
public class ExtensionContextURLHandler: OAuthSwiftURLHandlerType {
    
    private var extensionContext: NSExtensionContext
    
    public init(extensionContext: NSExtensionContext) {
        self.extensionContext = extensionContext
    }
    
    @objc public func handle(url: NSURL) {
        extensionContext.openURL(url, completionHandler: nil)
    }
}
