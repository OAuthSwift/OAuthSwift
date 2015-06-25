//
//  OAuth1Swift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/22/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

public class OAuth1Swift: OAuthSwift {

    var request_token_url: String
    var authorize_url: String
    var access_token_url: String

    public init(consumerKey: String, consumerSecret: String, requestTokenUrl: String, authorizeUrl: String, accessTokenUrl: String){
        self.request_token_url = requestTokenUrl
        self.authorize_url = authorizeUrl
        self.access_token_url = accessTokenUrl
        super.init(consumerKey: consumerKey, consumerSecret: consumerSecret)
    }

    // 0. Start
    public func authorizeWithCallbackURL(callbackURL: NSURL, success: TokenSuccessHandler, failure: ((error: NSError) -> Void)) {
        self.postOAuthRequestTokenWithCallbackURL(callbackURL, success: {
            credential, response, responseParameters in

            self.observer = NSNotificationCenter.defaultCenter().addObserverForName(CallbackNotification.notificationName, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock:{
                notification in
                //NSNotificationCenter.defaultCenter().removeObserver(self)
                NSNotificationCenter.defaultCenter().removeObserver(self.observer!)
                let url = notification.userInfo![CallbackNotification.optionsURLKey] as! NSURL
                var parameters: Dictionary<String, String> = Dictionary()
                if ((url.query) != nil){
                    parameters = url.query!.parametersFromQueryString()
                } else if ((url.fragment) != nil && url.fragment!.isEmpty == false) {
                    parameters = url.fragment!.parametersFromQueryString()
                }
                if let token = parameters["token"] {
                    parameters["oauth_token"] = token
                }
                if (parameters["oauth_token"] != nil && (self.allowMissingOauthVerifier || parameters["oauth_verifier"] != nil)) {
                    var credential: OAuthSwiftCredential = self.client.credential
                    self.client.credential.oauth_token = parameters["oauth_token"]!
                    if (parameters["oauth_verifier"] != nil) {
                        self.client.credential.oauth_verifier = parameters["oauth_verifier"]!
                    }
                    self.postOAuthAccessTokenWithRequestToken({
                        credential, response, parameters in
                        success(credential: credential, response: response, parameters: parameters)
                    }, failure: failure)
                } else {
                    let userInfo = [NSLocalizedFailureReasonErrorKey: NSLocalizedString("Oauth problem.", comment: "")]
                    failure(error: NSError(domain: OAuthSwiftErrorDomain, code: -1, userInfo: userInfo))
                    return
                }
            })
            // 2. Authorize
            if let queryURL = NSURL(string: self.authorize_url + (self.authorize_url.has("?") ? "&" : "?") + "oauth_token=\(credential.oauth_token)") {
                self.authorize_url_handler.handle(queryURL)
            }
        }, failure: failure)
    }

    // 1. Request token
    public func postOAuthRequestTokenWithCallbackURL(callbackURL: NSURL, success: TokenSuccessHandler, failure: FailureHandler?) {
        var parameters =  Dictionary<String, AnyObject>()
        if let callbackURLString = callbackURL.absoluteString {
            parameters["oauth_callback"] = callbackURLString
        }
        self.client.post(self.request_token_url, parameters: parameters, success: {
            data, response in
            let responseString = NSString(data: data, encoding: NSUTF8StringEncoding) as String!
            let parameters = responseString.parametersFromQueryString()
            self.client.credential.oauth_token = parameters["oauth_token"]!
            self.client.credential.oauth_token_secret = parameters["oauth_token_secret"]!
            success(credential: self.client.credential, response: response, parameters: parameters)
        }, failure: failure)
    }

    // 3. Get Access token
    public func postOAuthAccessTokenWithRequestToken(success: TokenSuccessHandler, failure: FailureHandler?) {
        var parameters = Dictionary<String, AnyObject>()
        parameters["oauth_token"] = self.client.credential.oauth_token
        parameters["oauth_verifier"] = self.client.credential.oauth_verifier
        self.client.post(self.access_token_url, parameters: parameters, success: {
            data, response in
            let responseString = NSString(data: data, encoding: NSUTF8StringEncoding) as String!
            let parameters = responseString.parametersFromQueryString()
            self.client.credential.oauth_token = parameters["oauth_token"]!
            self.client.credential.oauth_token_secret = parameters["oauth_token_secret"]!
            success(credential: self.client.credential, response: response, parameters: parameters)
        }, failure: failure)
    }

}
