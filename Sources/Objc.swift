//
//  Objc.swift
//  OAuthSwift
//
//  Created by phimage on 05/11/16.
//  Copyright © 2016 Dongri Jin. All rights reserved.
//

import Foundation

extension OAuthSwift {
    // swiftlint:disable:next type_name
    public typealias Obj_FailureHandler = (_ error: Error) -> Void
}

extension OAuth1Swift {

    open func objc_authorize(withCallbackURL url: URLConvertible, success: @escaping TokenSuccessHandler, failure: Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
        guard let callbackURL = url.url else {
            failure?(OAuthSwiftError.encodingError(urlString: url.string))
            return nil
        }
        return authorize(withCallbackURL: callbackURL, success: success, failure: failure)
    }

}

extension OAuth2Swift {

    open func objc_authorize(withCallbackURL url: URLConvertible, scope: String, state: String, parameters: Parameters = [:], headers: OAuthSwift.Headers? = nil, success: @escaping TokenSuccessHandler, failure: Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
        guard url.url != nil else {
            failure?(OAuthSwiftError.encodingError(urlString: url.string))
            return nil
        }
        return authorize(withCallbackURL: url, scope: scope, state: state, parameters: parameters, headers: headers, success: success, failure: failure)
    }

	open func objc_renewAccessToken(withRefreshToken refreshToken: String, headers: OAuthSwift.Headers? = nil, success: @escaping TokenSuccessHandler, failure: Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
		return renewAccessToken(withRefreshToken: refreshToken, headers: headers, success: success, failure: failure)
	}

}

extension OAuthSwiftHTTPRequest {
    // swiftlint:disable:next type_name
    public typealias Obj_FailureHandler = (_ error: Error) -> Void
}

extension OAuthSwiftClient {

    open func objc_request(_ url: URLConvertible, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, body: Data? = nil, checkTokenExpiration: Bool = true, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
        return request(url, method: method, parameters: parameters, headers: headers, body: body, checkTokenExpiration: checkTokenExpiration, success: success, failure: failure)
    }

    open func get(_ url: URLConvertible, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(url, method: .GET, parameters: parameters, headers: headers, success: success, failure: failure)
    }

    open func post(_ url: URLConvertible, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, body: Data? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(url, method: .POST, parameters: parameters, headers: headers, body: body, success: success, failure: failure)
    }

    open func put(_ url: URLConvertible, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, body: Data? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(url, method: .PUT, parameters: parameters, headers: headers, body: body, success: success, failure: failure)
    }

    open func delete(_ url: URLConvertible, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(url, method: .DELETE, parameters: parameters, headers: headers, success: success, failure: failure)
    }

    open func patch(_ url: URLConvertible, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.Obj_FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(url, method: .PATCH, parameters: parameters, headers: headers, success: success, failure: failure)
    }

}
