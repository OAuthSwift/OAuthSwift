//
//  OAuthSwiftURLHandlerType.swift
//  OAuthSwift
//
//  Created by phimage on 11/05/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import Foundation

#if os(iOS)
    import UIKit
#elseif os(OSX)
    import AppKit
#endif

@objc public protocol OAuthSwiftURLHandlerType {
    func handle(url: NSURL)
}

// MARK: Open externally
public class OAuthSwiftOpenURLExternally: OAuthSwiftURLHandlerType {
    class var sharedInstance : OAuthSwiftOpenURLExternally {
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
        #if os(iOS)
            #if !OAUTH_APP_EXTENSIONS
                UIApplication.sharedApplication().openURL(url)
            #endif
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

        var viewController: UIViewController
        var observers = [String: AnyObject]()

        // configure
        var animated: Bool = true
        var factory: (URL: NSURL) -> SFSafariViewController = {URL in
            return SFSafariViewController(URL: URL)
        }
        
        // delegates
        var delegate: SFSafariViewControllerDelegate?
        var presentCompletion: (() -> Void)?
        var dismissCompletion: (() -> Void)?
        
        // init
        public init(viewController: UIViewController) {
            self.viewController = viewController
        }

        @objc public func handle(url: NSURL) {
            let controller = factory(URL: url)
            controller.delegate = self
            
            let key = NSUUID().UUIDString
            
            observers[key] = NSNotificationCenter.defaultCenter().addObserverForName(
                OAuth1Swift.CallbackNotification.notificationName,
                object: nil,
                queue: NSOperationQueue.mainQueue(),
                usingBlock:{ [unowned self]
                    notification in
                    if let observer = self.observers[key] {
                        NSNotificationCenter.defaultCenter().removeObserver(observer)
                    }
                    
                    controller.dismissViewControllerAnimated(self.animated, completion: self.dismissCompletion)
                }
            )

            viewController.presentViewController(controller, animated: self.animated, completion: self.presentCompletion)
        }
        
        // SFSafariViewControllerDelegate
        public func safariViewController(controller: SFSafariViewController, activityItemsForURL URL: NSURL, title: String?) -> [UIActivity] {
            return self.delegate?.safariViewController?(controller, activityItemsForURL: URL, title: title) ?? []
        }
        
        public func safariViewControllerDidFinish(controller: SFSafariViewController) {
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