//
//  AppDelegate.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import OAuthSwift

#if os(iOS)
    import UIKit
    @UIApplicationMain
    class AppDelegate: UIResponder {
        var window: UIWindow?
    }
#elseif os(OSX)
    import AppKit
    @NSApplicationMain
    class AppDelegate: NSObject {}
#endif

// MARK: handle callback url
extension AppDelegate {
    
    func applicationHandleOpenURL(url: NSURL) {
        if (url.host == "oauth-callback") {
            if (url.path!.hasPrefix("/twitter") || url.path!.hasPrefix("/flickr") || url.path!.hasPrefix("/fitbit")
                || url.path!.hasPrefix("/withings") || url.path!.hasPrefix("/linkedin") || url.path!.hasPrefix("/bitbucket") || url.path!.hasPrefix("/smugmug") || url.path!.hasPrefix("/intuit") || url.path!.hasPrefix("/zaim") || url.path!.hasPrefix("/tumblr")) {
                    OAuth1Swift.handleOpenURL(url)
            }
            if ( url.path!.hasPrefix("/github" ) || url.path!.hasPrefix("/instagram" ) || url.path!.hasPrefix("/foursquare") || url.path!.hasPrefix("/dropbox") || url.path!.hasPrefix("/dribbble") || url.path!.hasPrefix("/salesforce") || url.path!.hasPrefix("/google") || url.path!.hasPrefix("/linkedin2") || url.path!.hasPrefix("/slack") || url.path!.hasPrefix("/uber") || url.path!.hasPrefix("/gitter") || url.path!.hasPrefix("/fitbit2") || url.path!.hasPrefix("/facebook")) {
                OAuth2Swift.handleOpenURL(url)
            }
        } else {
            // Google provider is the only one wuth your.bundle.id url schema.
            OAuth2Swift.handleOpenURL(url)
        }
    }
}

// MARK: ApplicationDelegate
#if os(iOS)
extension AppDelegate: UIApplicationDelegate {

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let viewController: ViewController = ViewController()
        let naviController: UINavigationController = UINavigationController(rootViewController: viewController)
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.rootViewController = naviController
        self.window!.makeKeyAndVisible()
        return true
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        applicationHandleOpenURL(url)
        return true
    }
}
    
#elseif os(OSX)
extension AppDelegate: NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // listen to scheme url
        NSAppleEventManager.sharedAppleEventManager().setEventHandler(self, andSelector:"handleGetURLEvent:withReplyEvent:", forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }

    func handleGetURLEvent(event: NSAppleEventDescriptor!, withReplyEvent: NSAppleEventDescriptor!) {
        if let urlString = event.paramDescriptorForKeyword(AEKeyword(keyDirectObject))?.stringValue, url = NSURL(string: urlString) {
            applicationHandleOpenURL(url)
        }
    }

    class var sharedInstance: AppDelegate {
        return NSApplication.sharedApplication().delegate as! AppDelegate
    }
    
}
#endif
