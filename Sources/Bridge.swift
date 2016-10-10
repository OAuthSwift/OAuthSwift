//
//  Bridge.swift
//  OAuthSwift
//
//  Created by phimage on 10/10/16.
//  Copyright © 2016 Dongri Jin. All rights reserved.
//

import Foundation


extension OAuth1Swift {

    open func bridge_authorize(withCallbackURL urlString: String, success: @escaping TokenSuccessHandler, failure: ((_ error: Error) -> Void)?) -> OAuthSwiftRequestHandle? {
        guard let url = URL(string: urlString) else {
            failure?(OAuthSwiftError.encodingError(urlString: urlString))
            return nil
        }
        return authorize(withCallbackURL: url, success: success, failure: failure)
    }

}

extension OAuth2Swift {

    open func  bridge_authorize(withCallbackURL urlString: String, scope: String, state: String, parameters: Parameters = [:], headers: OAuthSwift.Headers? = nil, success: @escaping TokenSuccessHandler, failure: ((_ error: Error) -> Void)?) -> OAuthSwiftRequestHandle? {
        guard let url = URL(string: urlString) else {
            failure?(OAuthSwiftError.encodingError(urlString: urlString))
            return nil
        }
        return authorize(withCallbackURL: url, scope: scope, state: state, parameters: parameters, headers: headers, success: success, failure: failure)
    }

}

extension OAuthSwiftClient {
  
    open func bridge_request(_ urlString: String, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, body: Data? = nil, checkTokenExpiration: Bool = true, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: ((_ error: Error) -> Void)?) -> OAuthSwiftRequestHandle? {
        return request(urlString, method: method, parameters: parameters, headers: headers, body: body, checkTokenExpiration: checkTokenExpiration, success: success, failure: failure)
    }

}

