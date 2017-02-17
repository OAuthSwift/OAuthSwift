//
//  Objc.swift
//  OAuthSwift
//
//  Created by phimage on 05/11/16.
//  Copyright © 2016 Dongri Jin. All rights reserved.
//

import Foundation

extension OAuthSwift {
    // swiftlint:disable type_name
    public typealias Obj_FailureHandler = (_ error: Error) -> Void
}

extension OAuth1Swift {

    open func objc_authorize(withCallbackURL urlString: String, success: @escaping TokenSuccessHandler, failure: Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
        guard let url = URL(string: urlString) else {
            failure?(OAuthSwiftError.encodingError(urlString: urlString))
            return nil
        }
        return authorize(withCallbackURL: url, success: success, failure: failure)
    }

}

extension OAuth2Swift {

    open func objc_authorize(withCallbackURL urlString: String, scope: String, state: String, parameters: Parameters = [:], headers: OAuthSwift.Headers? = nil, success: @escaping TokenSuccessHandler, failure: Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
        guard let url = URL(string: urlString) else {
            failure?(OAuthSwiftError.encodingError(urlString: urlString))
            return nil
        }
        return authorize(withCallbackURL: url, scope: scope, state: state, parameters: parameters, headers: headers, success: success, failure: failure)
    }

	open func objc_renewAccessToken(withRefreshToken refreshToken: String, headers: OAuthSwift.Headers? = nil, success: @escaping TokenSuccessHandler, failure: Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
		return renewAccessToken(withRefreshToken: refreshToken, headers: headers, success: success, failure: failure)
	}

}

extension OAuthSwiftHTTPRequest {
    // swiftlint:disable type_name
    public typealias Obj_FailureHandler = (_ error: Error) -> Void
}

extension OAuthSwiftClient {

    open func objc_request(_ urlString: String, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, body: Data? = nil, checkTokenExpiration: Bool = true, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
        return request(urlString, method: method, parameters: parameters, headers: headers, body: body, checkTokenExpiration: checkTokenExpiration, success: success, failure: failure)
    }

    open func get(_ urlString: String, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .GET, parameters: parameters, headers: headers, success: success, failure: failure)
    }

    open func post(_ urlString: String, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, body: Data? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .POST, parameters: parameters, headers: headers, body: body, success: success, failure: failure)
    }

    open func put(_ urlString: String, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, body: Data? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .PUT, parameters: parameters, headers: headers, body: body, success: success, failure: failure)
    }

    open func delete(_ urlString: String, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .DELETE, parameters: parameters, headers: headers, success: success, failure: failure)
    }

    open func patch(_ urlString: String, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .PATCH, parameters: parameters, headers: headers, success: success, failure: failure)
    }

}
