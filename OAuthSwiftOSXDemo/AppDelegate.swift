//
//  AppDelegate.swift
//  OAuthSwiftOSXDemo
//
//  Created by phimage on 07/05/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import Cocoa
import OAuthSwiftOSX

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Register to url events
        NSAppleEventManager.sharedAppleEventManager().setEventHandler(self, andSelector:"handleGetURLEvent:withReplyEvent:", forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        
        // Code to check configuration project
        if let urlTypes = NSBundle.mainBundle().infoDictionary!["CFBundleURLTypes"] as? Array<AnyObject>,
            urlType = urlTypes.first as? [String:AnyObject],
            urlSchemes = urlType["CFBundleURLSchemes"] as? [String] {
                if !contains(urlSchemes, "oauth-swift") {
                    println("oauth-swift no registered to url schemes")
                }
        }

    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    private func handleGetURLEvent(event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor)
    {
        if let urlString = event.paramDescriptorForKeyword(AEKeyword(keyDirectObject))?.stringValue, url = NSURL(string: urlString) {
            applicationHandleOpenURL(url)
        }
    }
    
    internal func applicationHandleOpenURL(url: NSURL) {
        println(url)
        OAuthSwift.handleOpenURL(url)
    }

    class var sharedInstance: AppDelegate {
        return NSApplication.sharedApplication().delegate as! AppDelegate
    }

}

