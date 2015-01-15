//
//  AppDelegate.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import UIKit
import OAuthSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UIWebViewDelegate {
    
    var window: UIWindow?
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        // Override point for customization after application launch.
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        let viewController: ViewController = ViewController()
        let naviController: UINavigationController = UINavigationController(rootViewController: viewController)
        self.window!.rootViewController = naviController
        self.window!.makeKeyAndVisible()
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication!, openURL url: NSURL!, sourceApplication: String!, annotation: AnyObject!) -> Bool {
        println(url)
        if (url.host == "oauth-callback") {
            if (url.path!.hasPrefix("/twitter") || url.path!.hasPrefix("/flickr") || url.path!.hasPrefix("/fitbit")
             || url.path!.hasPrefix("/withings") || url.path!.hasPrefix("/linkedin")) {
                OAuth1Swift.handleOpenURL(url)
            }
            if ( url.path!.hasPrefix("/github" ) || url.path!.hasPrefix("/instagram" ) || url.path!.hasPrefix("/foursquare") || url.path!.hasPrefix("/dropbox") || url.path!.hasPrefix("/dribbble") ) {
                OAuth2Swift.handleOpenURL(url)
            }
        }
        return true
    }
    
}

