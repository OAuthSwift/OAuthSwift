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
    var port: in_port_t = 8765
    
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
        case JSON, Data
    }
    var accessReturnType: AccessReturnType  = .Data
    
    

    let oauth_token = "accesskey"
    let oauth_token_secret = "accesssecret"
    let valid_key = "key"
    let valid_secret = "key"
    
    
    init() {
        server = HttpServer()
        server["1/requestToken"] = { request in
            guard request.method == "POST" else {
                return .BadRequest(.Text("Method must be POST"))
            }
            // TODO check request.headers["authorization"] for consumer key, etc...
            
            let oauth_token = "requestkey"
            let oauth_token_secret = "requestsecret"
            
            return .OK(.Text("oauth_token=\(oauth_token)&oauth_token_secret=\(oauth_token_secret)" as String) )
        }
        server["1/accessToken"] = { request in
            guard request.method == "POST" else {
                return HttpResponse.BadRequest(.Text("Method must be POST"))
            }
            // TODO check request.headers["authorization"] for consumer key, etc...
            
            return .OK(.Text("oauth_token=\(self.oauth_token)&oauth_token_secret=\(self.oauth_token_secret)" as String) )
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
                return .BadRequest(.Text("Method must be POST"))
            }
            /*guard let autho = request.headers["authorization"] where autho == "Beared" else {
                return HttpResponse.BadRequest
            }*/
            // TODO check body for consumer key, etc...
            
            switch self.accessReturnType {
            case .JSON:
                return .OK(.Json(["access_token":self.oauth_token]))
            case .Data:
                return .OK(.Text("access_token=\(self.oauth_token)" as String))
            }
            
        }
        server["2/authorize"] = { request in
            return .OK(HttpResponseBody.Html("You asked for \(request.path)"))
        }
        server["2/expire"] = { request in
            return HttpResponse.RAW(401, "Unauthorized",["WWW-Authenticate": "Bearer realm=\"example\",error=\"invalid_token\",error_description=\"The access token expired\""], nil)
        }
    }
    
    func start() throws {
        try server.start(self.port)
    }
    
    func stop() {
        self.server.stop()
    }
    
}