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
    func handle(_ url: URL)
}

// MARK: Open externally
open class OAuthSwiftOpenURLExternally: OAuthSwiftURLHandlerType {

    public static var sharedInstance : OAuthSwiftOpenURLExternally = OAuthSwiftOpenURLExternally()
        
    @objc open func handle(_ url: URL) {
        #if os(iOS) || os(tvOS)
            #if !OAUTH_APP_EXTENSIONS
                UIApplication.shared.openURL(url)
            #endif
        #elseif os(watchOS)
        // WATCHOS: not implemented
        #elseif os(OSX)
            NSWorkspace.shared().open(url)
        #endif
    }
}

// MARK: Open SFSafariViewController
#if os(iOS)
import SafariServices
    
    @available(iOS 9.0, *)
    open class SafariURLHandler: NSObject, OAuthSwiftURLHandlerType, SFSafariViewControllerDelegate {
        
        public typealias UITransion = (_ controller: SFSafariViewController,_ handler: SafariURLHandler) -> Void

        open let oauthSwift: OAuthSwift
        open var present: UITransion
        open var dismiss: UITransion
        // retains observers
        var observers = [String: NSObjectProtocol]()

        open var factory: (_ URL: URL) -> SFSafariViewController = {URL in
            return SFSafariViewController(url: URL)
        }
        
        // delegates
        open var delegate: SFSafariViewControllerDelegate?

        // configure default presentation and dismissal code

        open var animated: Bool = true
        open var presentCompletion: (() -> Void)?
        open var dismissCompletion: (() -> Void)?
        open var delay: UInt32? = 1
        
        // init
        public init(viewController: UIViewController, oauthSwift: OAuthSwift) {
            self.oauthSwift = oauthSwift
            self.present = { controller, handler in
                viewController.present(controller, animated: handler.animated, completion: handler.presentCompletion)
            }
            self.dismiss = { controller, handler in
                viewController.dismiss(animated: handler.animated, completion: handler.dismissCompletion)
            }
        }

        public init(present: @escaping UITransion, dismiss: @escaping UITransion, oauthSwift: OAuthSwift) {
            self.oauthSwift = oauthSwift
            self.present = present
            self.dismiss = dismiss
        }

        @objc open func handle(_ url: URL) {
            let controller = factory(url)
            controller.delegate = self

            // present controller in main thread
            OAuthSwift.main { [weak self] in
                guard let this = self else {
                    return
                }
                if let delay = this.delay { // sometimes safari show a blank view..
                    sleep(delay)
                }
                this.present(controller, this)
            }
 
            let key = UUID().uuidString
   
            observers[key] = OAuthSwift.notificationCenter.addObserver(
                forName: OAuthSwift.CallbackNotification.notificationName,
                object: nil,
                queue: OperationQueue.main,
                using:{ [weak self]
                    notification in
                    guard let this = self else {
                        return
                    }
                    if let observer = this.observers[key] {
                        OAuthSwift.notificationCenter.removeObserver(observer)
                        this.observers.removeValue(forKey: key)
                    }
                    OAuthSwift.main {
                        this.dismiss(controller,this)
                    }
                }
            )
        }

        // Clear internal observers on authentification flow
        open func clearObservers() {
            clearLocalObservers()
            self.oauthSwift.removeCallbackNotificationObserver()
        }

        open func clearLocalObservers() {
            for (_, observer) in observers {
                OAuthSwift.notificationCenter.removeObserver(observer)
            }
            observers.removeAll()
        }
        
        // SFSafariViewControllerDelegate
        public func safariViewController(_ controller: SFSafariViewController, activityItemsFor URL: Foundation.URL, title: String?) -> [UIActivity] {
            return self.delegate?.safariViewController?(controller, activityItemsFor: URL, title: title) ?? []
        }

        public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            // "Done" pressed
            self.clearObservers()
            self.delegate?.safariViewControllerDidFinish?(controller)
        }
 
        public func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
            self.delegate?.safariViewController?(controller, didCompleteInitialLoad: didLoadSuccessfully)
        }
        
    }

#endif


// MARK: Open url using NSExtensionContext
open class ExtensionContextURLHandler: OAuthSwiftURLHandlerType {
    
    fileprivate var extensionContext: NSExtensionContext
    
    public init(extensionContext: NSExtensionContext) {
        self.extensionContext = extensionContext
    }
    
    @objc open func handle(_ url: URL) {
        extensionContext.open(url, completionHandler: nil)
    }
}
