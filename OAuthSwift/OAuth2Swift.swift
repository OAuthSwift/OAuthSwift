//
//  OAuth2Swift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/22/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation
import UIKit

public class OAuth2Swift: NSObject {

    public var client: OAuthSwiftClient

    public var webViewController: UIViewController?


    var consumer_key: String
    var consumer_secret: String
    var authorize_url: String
    var access_token_url: String?
    var response_type: String
    var observer: AnyObject?
    
    public convenience init(consumerKey: String, consumerSecret: String, authorizeUrl: String, accessTokenUrl: String, responseType: String){
        self.init(consumerKey: consumerKey, consumerSecret: consumerSecret, authorizeUrl: authorizeUrl, responseType: responseType)
        self.access_token_url = accessTokenUrl
    }

    public init(consumerKey: String, consumerSecret: String, authorizeUrl: String, responseType: String){
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
    
    public typealias TokenSuccessHandler = (credential: OAuthSwiftCredential, response: NSURLResponse?) -> Void
    public typealias FailureHandler = (error: NSError) -> Void
    

    public func authorizeWithCallbackURL(callbackURL: NSURL, scope: String, state: String, params: Dictionary<String, String> = Dictionary<String, String>(), success: TokenSuccessHandler, failure: ((error: NSError) -> Void)) {
        self.observer = NSNotificationCenter.defaultCenter().addObserverForName(CallbackNotification.notificationName, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock:{
            notification in
            NSNotificationCenter.defaultCenter().removeObserver(self.observer!)
            let url = notification.userInfo![CallbackNotification.optionsURLKey] as NSURL!
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
                self.postOAuthAccessTokenWithRequestTokenByCode(parameters["code"]!.stringByRemovingPercentEncoding!,
                    callbackURL:callbackURL,
                    success: { credential, response in
                        success(credential: credential, response: response)
                }, failure: failure)
                    
            }
        })
        //let authorizeURL = NSURL(string: )
        var urlString = String()
        urlString += self.authorize_url
        urlString += (self.authorize_url.has("?") ? "&" : "?") + "client_id=\(self.consumer_key)"
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
        if ( self.webViewController != nil ) {
            if let webView = self.webViewController as? WebViewProtocol {
                webView.setUrl(queryURL!)
                UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(
                    self.webViewController!, animated: true, completion: nil)
            }
        } else {
            UIApplication.sharedApplication().openURL(queryURL!)
        }
    }
    
    func postOAuthAccessTokenWithRequestTokenByCode(code: String, callbackURL: NSURL, success: TokenSuccessHandler, failure: FailureHandler?) {
        var parameters = Dictionary<String, AnyObject>()
        parameters["client_id"] = self.consumer_key
        parameters["client_secret"] = self.consumer_secret
        parameters["code"] = code
        parameters["grant_type"] = "authorization_code"
        parameters["redirect_uri"] = callbackURL.absoluteString!
        
        self.client.post(self.access_token_url!, parameters: parameters, success: {
            data, response in
            var responseJSON: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil)
            var accessToken = ""
            if let parameters:NSDictionary = responseJSON as? NSDictionary{
                accessToken = parameters["access_token"] as String!
            } else {
                let responseString = NSString(data: data, encoding: NSUTF8StringEncoding) as String!
                let parameters = responseString.parametersFromQueryString()
                accessToken = parameters["access_token"]!
            }
            self.client.credential.oauth_token = accessToken
            self.client.credential.oauth2 = true
            success(credential: self.client.credential, response: response)
        }, failure: failure)
    }
    
    public class func handleOpenURL(url: NSURL) {
        let notification = NSNotification(name: CallbackNotification.notificationName, object: nil,
            userInfo: [CallbackNotification.optionsURLKey: url])
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
}
