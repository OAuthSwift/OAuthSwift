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
        
        NSAppleEventManager.sharedAppleEventManager().setEventHandler(self, andSelector:"handleGetURLEvent:withReplyEvent:", forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    func handleGetURLEvent(event: NSAppleEventDescriptor!, withReplyEvent: NSAppleEventDescriptor!) {
        if let urlString = event.paramDescriptorForKeyword(AEKeyword(keyDirectObject))?.stringValue, url = NSURL(string: urlString) {
            applicationHandleOpenURL(url)
        }
    }

    internal func applicationHandleOpenURL(url: NSURL) {
        println(url)
        if (url.host == "oauth-callback") {
            if (url.path!.hasPrefix("/twitter") || url.path!.hasPrefix("/flickr") || url.path!.hasPrefix("/fitbit")
                || url.path!.hasPrefix("/withings") || url.path!.hasPrefix("/linkedin") || url.path!.hasPrefix("/bitbucket") || url.path!.hasPrefix("/smugmug") || url.path!.hasPrefix("/intuit") || url.path!.hasPrefix("/trello") ) {
                    OAuth1Swift.handleOpenURL(url)
            }
            if ( url.path!.hasPrefix("/github" ) || url.path!.hasPrefix("/instagram" ) || url.path!.hasPrefix("/foursquare") || url.path!.hasPrefix("/dropbox") || url.path!.hasPrefix("/dribbble") || url.path!.hasPrefix("/salesforce") || url.path!.hasPrefix("/google") || url.path!.hasPrefix("/linkedin2")) {
                OAuth2Swift.handleOpenURL(url)
            }
        } else {
            // Google provider is the only one wuth your.bundle.id url schema.
            OAuth2Swift.handleOpenURL(url)
        }
    }
    
    class var sharedInstance: AppDelegate {
        return NSApplication.sharedApplication().delegate as! AppDelegate
    }

}

