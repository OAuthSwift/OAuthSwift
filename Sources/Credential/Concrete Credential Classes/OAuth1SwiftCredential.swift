//
//  OAuth1SwiftCredential.swift
//  OAuthSwift
//
//  Created by Noam Bar-on on 6/22/17.
//  Copyright © 2017 Dongri Jin. All rights reserved.
//

import Foundation

final class OAuth1SwiftCredential: BaseOAuthSwiftCredential {
    
    override func makeHeaders(_ url: URL, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters, body: Data? = nil) -> [String: String] {
        var headers = [String: String]()
        if let factory = headersFactory {
            headers = factory.make(url, method: method, parameters: parameters, body: body)
        }else {
            headers = ["Authorization": self.authorizationHeader(method: method, url: url, parameters: parameters, body: body)];
        }
        return headers
    }
    
    override func authorizationHeader(method: OAuthSwiftHTTPRequest.Method, url: URL, parameters: OAuthSwift.Parameters, body: Data? = nil, timestamp: String, nonce: String) -> String {
        let authorizationParameters = self.authorizationParametersWithSignature(method: method, url: url, parameters: parameters, body: body, timestamp: timestamp, nonce: nonce)
        var parameterComponents = authorizationParameters.urlEncodedQuery.components(separatedBy: "&") as [String]
        parameterComponents.sort { $0 < $1 }
        var headerComponents = [String]()
        for component in parameterComponents {
            let subcomponent = component.components(separatedBy: "=") as [String]
            if subcomponent.count == 2 {
                headerComponents.append("\(subcomponent[0])=\"\(subcomponent[1])\"")
            }
        }
        return "OAuth " + headerComponents.joined(separator: ", ")
    }
}
