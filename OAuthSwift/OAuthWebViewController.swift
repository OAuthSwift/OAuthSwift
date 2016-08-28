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

open class OAuthWebViewController: OAuthViewController, OAuthSwiftURLHandlerType {

    open func handle(_ url: URL) {
        // do UI in main thread
        if Thread.isMainThread {
             doHandle(url)
        }
        else {
            DispatchQueue.main.async {
                self.doHandle(url)
            }
        }
    }

    #if os(watchOS)
    public static var userActivityType: String = "org.github.dongri.oauthswift.connect"
    #endif

    open func doHandle(_ url: URL){
        #if os(iOS) || os(tvOS)
            if let p = self.parent {
                p.present(self, animated: true, completion: nil)
            } else {
                #if !OAUTH_APP_EXTENSIONS
                    UIApplication.topViewController?.present(self, animated: true, completion: nil)
                #endif
            }
        #elseif os(watchOS)
            if (url.scheme == "http" || url.scheme == "https") {
                self.updateUserActivity(OAuthWebViewController.userActivityType, userInfo: nil, webpageURL: url)
            }
        #elseif os(OSX)
            if let p = self.parent { // default behaviour if this controller affected as child controller
                p.presentViewControllerAsModalWindow(self)
            } else if let window = self.view.window {
                window.makeKeyAndOrderFront(nil)
            }
            // or create an NSWindow or NSWindowController (/!\ keep a strong reference on it)
        #endif
    }

    open func dismissWebViewController() {
        #if os(iOS) || os(tvOS)
            self.dismiss(animated: true, completion: nil)
        #elseif os(watchOS)
            self.dismissController()
        #elseif os(OSX)
            if self.presenting != nil { // if presentViewControllerAsModalWindow
                self.dismiss(nil)
                if self.parent != nil {
                    self.removeFromParentViewController()
                }
            }
            else if let window = self.view.window {
                window.performClose(nil)
            }
        #endif
    }
}
