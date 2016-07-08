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
public class OAuthSwiftOpenURLExternally: OAuthSwiftURLHandlerType {

    static var sharedInstance : OAuthSwiftOpenURLExternally = OAuthSwiftOpenURLExternally()
        
    @objc public func handle(_ url: URL) {
        #if os(iOS) || os(tvOS)
            #if !OAUTH_APP_EXTENSIONS
                UIApplication.shared().openURL(url)
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

        public let viewController: UIViewController
        var observers = [String: AnyObject]()

        // configure
        public var animated: Bool = true
        public var factory: (URL: URL) -> SFSafariViewController = {URL in
            return SFSafariViewController(url: URL)
        }
        
        // delegates
        public var delegate: SFSafariViewControllerDelegate?
        public var presentCompletion: (() -> Void)?
        public var dismissCompletion: (() -> Void)?
        
        // init
        public init(viewController: UIViewController) {
            self.viewController = viewController
        }

        @objc public func handle(_ url: URL) {
            let controller = factory(URL: url)
            controller.delegate = self
            
            let key = UUID().uuidString
            
            observers[key] = NotificationCenter.default().addObserver(
                forName: NSNotification.Name(rawValue: OAuthSwift.CallbackNotification.notificationName),
                object: nil,
                queue: OperationQueue.main(),
                using:{ [unowned self]
                    notification in
                    if let observer = self.observers[key] {
                        NotificationCenter.default().removeObserver(observer)
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
public class ExtensionContextURLHandler: OAuthSwiftURLHandlerType {
    
    private var extensionContext: NSExtensionContext
    
    public init(extensionContext: NSExtensionContext) {
        self.extensionContext = extensionContext
    }
    
    @objc public func handle(_ url: URL) {
        extensionContext.open(url, completionHandler: nil)
    }
}
