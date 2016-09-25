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
    case accessToken(String), code(String, state:String?), error(String,String), none

    var responseType: String {
        switch self {
        case .accessToken:
            return "token"
        case .code:
            return "code"
        case .error:
            return "code"
        case .none:
            return "code"
        }
    }
}

class TestOAuthSwiftURLHandler: NSObject, OAuthSwiftURLHandlerType {
    
    let callbackURL: String
    let authorizeURL: String
    let version: OAuthSwiftCredential.Version
    
    var accessTokenResponse: AccessTokenResponse?
    
    var authorizeURLComponents: URLComponents? {
        return URLComponents(url: URL(string: self.authorizeURL)!, resolvingAgainstBaseURL: false)
    }
    
    init(callbackURL: String, authorizeURL: String, version: OAuthSwiftCredential.Version) {
        self.callbackURL = callbackURL
        self.authorizeURL = authorizeURL
        self.version = version
    }
    @objc func handle(_ url: URL) {
        
        switch version {
        case .oauth1:
            handleV1(url)
        case .oauth2:
            handleV2(url)
        }
    }
    
   func handleV1(_ url: URL) {
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
    
        if let queryItems = urlComponents?.queryItems {
            for queryItem in queryItems {
                if let value = queryItem.value , queryItem.name == "oauth_token" {
                    let url = "\(self.callbackURL)?oauth_token=\(value)"
                    OAuthSwift.handle(url: URL(string: url)!)
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

    func handleV2(_ url: URL) {
        var url = "\(self.callbackURL)/"
        if let response = accessTokenResponse {
            switch response {
            case .accessToken(let token):
                url += "?access_token=\(token)"
            case .code(let code, let state):
                url += "?code='\(code)'"
                if let state = state {
                    url += "&state=\(state)"
                }
            case .error(let error,let errorDescription):
                let e = error.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                let ed = errorDescription.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                url += "?error='\(e)'&errorDescription='\(ed)'"
            case .none: break
                // nothing
            }
        }
        OAuthSwift.handle(url: URL(string: url)!)
    }
}
