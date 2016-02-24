//
//  TestOAuthSwiftURLHandler.swift
//  OAuthSwift
//
//  Created by phimage on 17/11/15.
//  Copyright © 2015 Dongri Jin. All rights reserved.
//

import Foundation
import OAuthSwift

enum AccessTokenResponse {
    case AccessToken(String), Code(String), Error(String,String), None

    var responseType: String {
        switch self {
        case .AccessToken:
            return "token"
        case .Code:
            return "code"
        case .Error:
            return "code"
        case .None:
            return "code"
        }
    }
}

class TestOAuthSwiftURLHandler: NSObject, OAuthSwiftURLHandlerType {
    
    let callbackURL: String
    let authorizeURL: String
    let version: OAuthSwiftCredential.Version
    
    var accessTokenResponse: AccessTokenResponse?
    
    var authorizeURLComponents: NSURLComponents? {
        return NSURLComponents(URL: NSURL(string: self.authorizeURL)!, resolvingAgainstBaseURL: false)
    }
    
    init(callbackURL: String, authorizeURL: String, version: OAuthSwiftCredential.Version) {
        self.callbackURL = callbackURL
        self.authorizeURL = authorizeURL
        self.version = version
    }
    @objc func handle(url: NSURL) {
        
        switch version {
        case .OAuth1:
            handleV1(url)
        case .OAuth2:
            handleV2(url)
        }
    }
    
   func handleV1(url: NSURL) {
        let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
    
        if let queryItems = urlComponents?.queryItems {
            for queryItem in queryItems {
                if let value = queryItem.value where queryItem.name == "oauth_token" {
                    let url = "\(self.callbackURL)?oauth_token=\(value)"
                    OAuthSwift.handleOpenURL(NSURL(string: url)!)
                }
            }
        }
        
        urlComponents?.query = nil
 
        if urlComponents != authorizeURLComponents  {
            print("bad authorizeURL \(url), must be \(authorizeURL)")
            return
        }
        
        // else do nothing
    }

    func handleV2(url: NSURL) {
        var url = "\(self.callbackURL)/"
        if let response = accessTokenResponse {
            switch response {
            case .AccessToken(let token):
                url += "?access_token=\(token)"
            case .Code(let code):
                url += "?code='\(code)'"
            case .Error(let error,let errorDescription):
                let e = error.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
                let ed = errorDescription.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
                url += "?error='\(e)'&errorDescription='\(ed)'"
            case .None: break
                // nothing
            }
        }
        OAuthSwift.handleOpenURL(NSURL(string: url)!)
    }
}