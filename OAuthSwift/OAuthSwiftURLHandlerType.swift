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

    static var sharedInstance : OAuthSwiftOpenURLExternally = OAuthSwiftOpenURLExternally()
        
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

        open let viewController: UIViewController
        var observers = [String: Any]()

        // configure
        open var animated: Bool = true
        open var factory: (_ URL: URL) -> SFSafariViewController = {URL in
            return SFSafariViewController(url: URL)
        }
        
        // delegates
        open var delegate: SFSafariViewControllerDelegate?
        open var presentCompletion: (() -> Void)?
        open var dismissCompletion: (() -> Void)?
        
        // init
        public init(viewController: UIViewController) {
            self.viewController = viewController
        }

        @objc open func handle(_ url: URL) {
            let controller = factory(url)
            controller.delegate = self
            
            let key = UUID().uuidString
            
            observers[key] = NotificationCenter.default.addObserver(
                forName: NSNotification.Name(rawValue: OAuthSwift.CallbackNotification.notificationName),
                object: nil,
                queue: OperationQueue.main,
                using:{ [unowned self]
                    notification in
                    if let observer = self.observers[key] {
                        NotificationCenter.default.removeObserver(observer)
                        self.observers.removeValue(forKey: key)
                    }
                    
                    controller.dismiss(animated: self.animated, completion: self.dismissCompletion)
                }
            )

            viewController.present(controller, animated: self.animated, completion: self.presentCompletion)
        }
        
        // SFSafariViewControllerDelegate
        public func safariViewController(_ controller: SFSafariViewController, activityItemsFor URL: Foundation.URL, title: String?) -> [UIActivity] {
            return self.delegate?.safariViewController?(controller, activityItemsFor: URL, title: title) ?? []
        }
        
        public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
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
