//
//  OAuth2SwiftCredential.swift
//  OAuthSwift
//
//  Created by Noam Bar-on on 6/22/17.
//  Copyright © 2017 Dongri Jin. All rights reserved.
//

import Foundation

final class OAuth2SwiftCredential: BaseOAuthSwiftCredential {
    
    override func makeHeaders(_ url: URL, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters, body: Data? = nil) -> [String: String] {
        var headers = [String: String]()
        if let factory = headersFactory {
            headers = factory.make(url, method: method, parameters: parameters, body: body)
        } else {
            headers = self.oauthToken.isEmpty ? [:] : ["Authorization": "Bearer \(self.oauthToken)"]
        }
        return headers
    }
    
    override func authorizationHeader(method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: OAuthSwift.Parameters, body: Data? = nil, timestamp: String, nonce: String) -> String {
        // not used in OAuth 2.0
        return ""
    }
}
