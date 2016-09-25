//
//  TestServer.swift
//  OAuthSwift
//
//  Created by phimage on 17/11/15.
//  Copyright © 2015 Dongri Jin. All rights reserved.
//

import Foundation
import Swifter

class TestServer {
    
    let server: HttpServer
    var port: in_port_t = 8766
    
    var baseurl: String { return "http://localhost:\(self.port)/" }
    

    var v1: String { return "\(baseurl)1/" }
    var authorizeURL: String { return "\(v1)authorize" }
    var accessTokenURL: String { return "\(v1)accessToken" }
    var requestTokenURL: String { return "\(v1)requestToken" }
    
    var v2: String { return "\(baseurl)2/" }
    var authorizeURLV2: String { return "\(v2)authorize" }
    var accessTokenURLV2: String { return "\(v2)accessToken" }
    var expireURLV2: String { return "\(v2)expire" }
    
    enum AccessReturnType {
        case json, data
    }
    var accessReturnType: AccessReturnType  = .data
    
    

    let oauth_token = "accesskey"
    let oauth_token_secret = "accesssecret"
    let valid_key = "key"
    let valid_secret = "key"
    
    
    init() {
        server = HttpServer()
        server["1/requestToken"] = { request in
            guard request.method == "POST" else {
                return .badRequest(.text("Method must be POST"))
            }
            // TODO check request.headers["authorization"] for consumer key, etc...
            
            let oauth_token = "requestkey"
            let oauth_token_secret = "requestsecret"
            
            return .ok(.text("oauth_token=\(oauth_token)&oauth_token_secret=\(oauth_token_secret)" as String) )
        }
        server["1/accessToken"] = { request in
            guard request.method == "POST" else {
                return HttpResponse.badRequest(.text("Method must be POST"))
            }
            // TODO check request.headers["authorization"] for consumer key, etc...
            
            return .ok(.text("oauth_token=\(self.oauth_token)&oauth_token_secret=\(self.oauth_token_secret)" as String) )
        }
        
        /*
        server["1/authorize"] = {
            .OK(.HTML("You asked for " + $0.url))
        }
        server["/callback"] = {
            .OK(.HTML("You asked for " + $0.url))
        }
        */
        
        server["2/accessToken"] = { request in
            guard request.method == "POST" else {
                return .badRequest(.text("Method must be POST"))
            }
            /*guard let autho = request.headers["authorization"] where autho == "Beared" else {
                return HttpResponse.BadRequest
            }*/
            // TODO check body for consumer key, etc...
            
            switch self.accessReturnType {
            case .json:
                return .ok(.json(["access_token":self.oauth_token] as AnyObject))
            case .data:
                return .ok(.text("access_token=\(self.oauth_token)" as String))
            }
            
        }
        server["2/authorize"] = { request in
            return .ok(HttpResponseBody.html("You asked for \(request.path)"))
        }
        server["2/expire"] = { request in
            return HttpResponse.raw(401, "Unauthorized",["WWW-Authenticate": "Bearer realm=\"example\",error=\"invalid_token\",error_description=\"The access token expired\""], nil)
        }
    }
    
    func start() throws {
        try server.start(self.port)
    }
    
    func stop() {
        self.server.stop()
    }
    
}
