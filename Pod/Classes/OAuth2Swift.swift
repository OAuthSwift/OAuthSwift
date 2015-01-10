//
//  OAuth2Swift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/22/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation
import UIKit

class OAuth2Swift {
    
    var client: OAuthSwiftClient
    
    var consumer_key: String
    var consumer_secret: String
    var authorize_url: String
    var access_token_url: String?
    var response_type: String
    var observer: AnyObject?
    
    convenience init(consumerKey: String, consumerSecret: String, authorizeUrl: String, accessTokenUrl: String, responseType: String){
        self.init(consumerKey: consumerKey, consumerSecret: consumerSecret, authorizeUrl: authorizeUrl, responseType: responseType)
        self.access_token_url = accessTokenUrl
    }

    init(consumerKey: String, consumerSecret: String, authorizeUrl: String, responseType: String){
        self.consumer_key = consumerKey
        self.consumer_secret = consumerSecret
        self.authorize_url = authorizeUrl
        self.response_type = responseType
        self.client = OAuthSwiftClient(consumerKey: consumerKey, consumerSecret: consumerSecret)
        self.client.credential = OAuthSwiftCredential()
    }
    
    struct CallbackNotification {
        static let notificationName = "OAuthSwiftCallbackNotificationName"
        static let optionsURLKey = "OAuthSwiftCallbackNotificationOptionsURLKey"
    }
    
    struct OAuthSwiftError {
        static let domain = "OAuthSwiftErrorDomain"
        static let appOnlyAuthenticationErrorCode = 1
    }
    
    typealias TokenSuccessHandler = (credential: OAuthSwiftCredential, response: NSURLResponse?) -> Void
    typealias FailureHandler = (error: NSError) -> Void
    

    func authorizeWithCallbackURL(callbackURL: NSURL, scope: String, state: String, params: Dictionary<String, String> = Dictionary<String, String>(), success: TokenSuccessHandler, failure: ((error: NSError) -> Void)) {
        self.observer = NSNotificationCenter.defaultCenter().addObserverForName(CallbackNotification.notificationName, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock:{
            notification in
            NSNotificationCenter.defaultCenter().removeObserver(self.observer!)
            let url = notification.userInfo![CallbackNotification.optionsURLKey] as NSURL
            var parameters: Dictionary<String, String> = Dictionary()
            if ((url.query) != nil){
                parameters = url.query!.parametersFromQueryString()
            }
            if ((url.fragment) != nil){
                parameters = url.fragment!.parametersFromQueryString()
            }
            if (parameters["access_token"] != nil){
                self.client.credential.oauth_token = parameters["access_token"]!
                success(credential: self.client.credential, response: nil)
            }
            if (parameters["code"] != nil){
                self.postOAuthAccessTokenWithRequestTokenByCode(parameters["code"]!, success: {
                    credential, response in
                    success(credential: credential, response: response)
                }, failure: failure)
                    
            }
        })
        //let authorizeURL = NSURL(string: )
        var urlString = String()
        urlString += self.authorize_url
        urlString += "?client_id=\(self.consumer_key)"
        urlString += "&redirect_uri=\(callbackURL.absoluteString!)"
        urlString += "&response_type=\(self.response_type)"
        if (scope != "") {
          urlString += "&scope=\(scope)"
        }
        if (state != "") {
            urlString += "&state=\(state)"
        }

        for param in params {
            urlString += "&\(param.0)=\(param.1)"
        }

        let queryURL = NSURL(string: urlString)
        UIApplication.sharedApplication().openURL(queryURL!)
    }
    
    func postOAuthAccessTokenWithRequestTokenByCode(code: String, success: TokenSuccessHandler, failure: FailureHandler?) {
        var parameters = Dictionary<String, AnyObject>()
        parameters["client_id"] = self.consumer_key
        parameters["client_secret"] = self.consumer_secret
        parameters["code"] = code
        parameters["grant_type"] = "authorization_code"
        
        self.client.post(self.access_token_url!, parameters: parameters, success: {
            data, response in
            let responseString = NSString(data: data, encoding: NSUTF8StringEncoding) as String
            let parameters = responseString.parametersFromQueryString()
            self.client.credential.oauth_token = parameters["access_token"]!
            success(credential: self.client.credential, response: response)
        }, failure: failure)
    }
    
    class func handleOpenURL(url: NSURL) {
        let notification = NSNotification(name: CallbackNotification.notificationName, object: nil,
            userInfo: [CallbackNotification.optionsURLKey: url])
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
}
