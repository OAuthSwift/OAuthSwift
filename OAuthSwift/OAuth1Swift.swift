//
//  OAuth1Swift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/22/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation
import UIKit

// OAuthSwift errors
public let OAuthSwiftErrorDomain = "oauthswift.error"

class OAuth1Swift {

    var client: OAuthSwiftClient

    var consumer_key: String
    var consumer_secret: String
    var request_token_url: String
    var authorize_url: String
    var access_token_url: String

    var observer: AnyObject?

    init(consumerKey: String, consumerSecret: String, requestTokenUrl: String, authorizeUrl: String, accessTokenUrl: String){
        self.consumer_key = consumerKey
        self.consumer_secret = consumerSecret
        self.request_token_url = requestTokenUrl
        self.authorize_url = authorizeUrl
        self.access_token_url = accessTokenUrl
        self.client = OAuthSwiftClient(consumerKey: consumerKey, consumerSecret: consumerSecret)
    }

    struct CallbackNotification {
        static let notificationName = "OAuthSwiftCallbackNotificationName"
        static let optionsURLKey = "OAuthSwiftCallbackNotificationOptionsURLKey"
    }

    struct OAuthSwiftError {
        static let domain = "OAuthSwiftErrorDomain"
        static let appOnlyAuthenticationErrorCode = 1
    }

    typealias TokenSuccessHandler = (credential: OAuthSwiftCredential, response: NSURLResponse) -> Void
    typealias FailureHandler = (error: NSError) -> Void

    // 0. Start
    func authorizeWithCallbackURL(callbackURL: NSURL, success: TokenSuccessHandler, failure: ((error: NSError) -> Void)) {
        self.postOAuthRequestTokenWithCallbackURL(callbackURL, success: {
            credential, response in

            self.observer = NSNotificationCenter.defaultCenter().addObserverForName(CallbackNotification.notificationName, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock:{
                notification in
                //NSNotificationCenter.defaultCenter().removeObserver(self)
                NSNotificationCenter.defaultCenter().removeObserver(self.observer!)
                let url = notification.userInfo![CallbackNotification.optionsURLKey] as NSURL
                let parameters = url.query!.parametersFromQueryString()
                if (parameters["oauth_token"] != nil && parameters["oauth_verifier"] != nil) {
                    var credential: OAuthSwiftCredential = self.client.credential
                    self.client.credential.oauth_token = parameters["oauth_token"]!
                    self.client.credential.oauth_verifier = parameters["oauth_verifier"]!
                    self.postOAuthAccessTokenWithRequestToken({
                        credential, response in
                        success(credential: credential, response: response)
                    }, failure: failure)
                } else {
                    let userInfo = [NSLocalizedFailureReasonErrorKey: NSLocalizedString("Oauth problem.", comment: "")]
                    failure(error: NSError(domain: OAuthSwiftErrorDomain, code: -1, userInfo: userInfo))
                    return
                }
            })
            // 2. Authorize
            let queryURL = NSURL(string: self.authorize_url + "?oauth_token=\(credential.oauth_token)")
            UIApplication.sharedApplication().openURL(queryURL!)
        }, failure: failure)
    }

    // 1. Request token
    func postOAuthRequestTokenWithCallbackURL(callbackURL: NSURL, success: TokenSuccessHandler, failure: FailureHandler?) {
        var parameters =  Dictionary<String, AnyObject>()
        if let callbackURLString = callbackURL.absoluteString {
            parameters["oauth_callback"] = callbackURLString
        }
        self.client.post(self.request_token_url, parameters: parameters, success: {
            data, response in
            let responseString = NSString(data: data, encoding: NSUTF8StringEncoding) as String
            let parameters = responseString.parametersFromQueryString()
            self.client.credential.oauth_token = parameters["oauth_token"]!
            self.client.credential.oauth_token_secret = parameters["oauth_token_secret"]!
            success(credential: self.client.credential, response: response)
        }, failure: failure)
    }

    // 3. Get Access token
    func postOAuthAccessTokenWithRequestToken(success: TokenSuccessHandler, failure: FailureHandler?) {
        var parameters = Dictionary<String, AnyObject>()
        parameters["oauth_token"] = self.client.credential.oauth_token
        parameters["oauth_verifier"] = self.client.credential.oauth_verifier
        self.client.post(self.access_token_url, parameters: parameters, success: {
            data, response in
            let responseString = NSString(data: data, encoding: NSUTF8StringEncoding) as String
            let parameters = responseString.parametersFromQueryString()
            self.client.credential.oauth_token = parameters["oauth_token"]!
            self.client.credential.oauth_token_secret = parameters["oauth_token_secret"]!
            success(credential: self.client.credential, response: response)
        }, failure: failure)
    }

    class func handleOpenURL(url: NSURL) {
        let notification = NSNotification(name: CallbackNotification.notificationName, object: nil,
            userInfo: [CallbackNotification.optionsURLKey: url])
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }

}
