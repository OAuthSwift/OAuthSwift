//
//  OAuthWebViewController.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 2/11/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import Foundation

#if os(iOS)  || os(tvOS)
    import UIKit
    public typealias OAuthViewController = UIViewController
#elseif os(watchOS)
    import WatchKit
    public typealias OAuthViewController = WKInterfaceController
#elseif os(OSX)
    import AppKit
    public typealias OAuthViewController = NSViewController
#endif

public class OAuthWebViewController: OAuthViewController, OAuthSwiftURLHandlerType {

    public func handle(url: NSURL) {
        // do UI in main thread
        if NSThread.isMainThread() {
             doHandle(url)
        }
        else {
            dispatch_async(dispatch_get_main_queue()) {
                self.doHandle(url)
            }
        }
    }

    #if os(watchOS)
    public static var userActivityType: String = "org.github.dongri.oauthswift.connect"
    #endif

    public func doHandle(url: NSURL){
        #if os(iOS) || os(tvOS)
            if let p = self.parentViewController {
                p.presentViewController(self, animated: true, completion: nil)
            } else {
                #if !OAUTH_APP_EXTENSIONS
                    UIApplication.topViewController?.presentViewController(self, animated: true, completion: nil)
                #endif
            }
        #elseif os(watchOS)
            if (url.scheme == "http" || url.scheme == "https") {
                self.updateUserActivity(OAuthWebViewController.userActivityType, userInfo: nil, webpageURL: url)
            }
        #elseif os(OSX)
            if let p = self.parentViewController { // default behaviour if this controller affected as child controller
                p.presentViewControllerAsModalWindow(self)
            } else if let window = self.view.window {
                window.makeKeyAndOrderFront(nil)
            }
            // or create an NSWindow or NSWindowController (/!\ keep a strong reference on it)
        #endif
    }

    public func dismissWebViewController() {
        #if os(iOS) || os(tvOS)
            self.dismissViewControllerAnimated(true, completion: nil)
        #elseif os(watchOS)
            self.dismissController()
        #elseif os(OSX)
            if self.presentingViewController != nil { // if presentViewControllerAsModalWindow
                self.dismissController(nil)
                if self.parentViewController != nil {
                    self.removeFromParentViewController()
                }
            }
            else if let window = self.view.window {
                window.performClose(nil)
            }
        #endif
    }
}