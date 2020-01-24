//
//  NSError+OAuthSwift.swift
//  OAuthSwift
//
//  Created by Goessler, Florian on 04/04/16.
//  Copyright © 2016 Dongri Jin. All rights reserved.
//

import Foundation

public extension NSError {

    /// Checks the headers contained in the userInfo whether this error was caused by an 
    /// expired/invalid access token.
    ///
    /// Criteria for invalid token error: WWW-Authenticate header contains a field "error" with
    /// value "invalid_token".
    ///
    /// Also implements a special handling for the Facebook API, which indicates invalid tokens in a 
    /// different manner. See https://developers.facebook.com/docs/graph-api/using-graph-api#errors
    var isExpiredToken: Bool {
        guard self.domain == NSURLErrorDomain || self.domain == OAuthSwiftError.Domain else {
            return false
        }
		if self.code == 401 {
			if let reponseHeaders = self.userInfo["Response-Headers"] as? [String: String],
				let authenticateHeader = reponseHeaders["WWW-Authenticate"] ?? reponseHeaders["Www-Authenticate"] {
				let headerDictionary = authenticateHeader.headerDictionary
				if let error = headerDictionary["error"], error == "invalid_token" || error == "expired_token" || error == "\"invalid_token\"" {
					return true
				}
			}
            if let body = self.userInfo["Response-Body"] as? String,
                let bodyData = body.data(using: OAuthSwiftDataEncoding),
                let json = try? JSONSerialization.jsonObject(with: bodyData, options: []),
                let jsonDic = json as? [String: AnyObject] {
                if let error = jsonDic["error"] as? String, error == "invalid_token" || error == "expired_token" || error == "\"invalid_token\"" {
                    return true
                }
                if let errors = jsonDic["errors"] as? [[String: AnyObject]] {
                    for error in errors {
                        if let errorType = error["errorType"] as? String, errorType == "invalid_token" || errorType == "expired_token" {
                            return true
                        } else if let urlString = self.userInfo[NSURLErrorFailingURLErrorKey] as? String, urlString.contains("api.twitter.com"), let errorCode = error["code"] as? Int, errorCode == 89 {
                            // This is the code for expired or invalid twitter token
                            // see: https://developer.twitter.com/en/docs/basics/response-codes
                            return true
                        }
                    }
                }
            }
		}

        // Detect access token expiration errors from facebook
        // Docu: https://developers.facebook.com/docs/graph-api/using-graph-api#errors
        if self.code == 400 {
            if let urlString = self.userInfo[NSURLErrorFailingURLErrorKey] as? String, urlString.contains("graph.facebook.com") {
                if let body = self.userInfo["Response-Body"] as? String,
                    let bodyData = body.data(using: OAuthSwiftDataEncoding),
                    let json = try? JSONSerialization.jsonObject(with: bodyData, options: []),
                    let jsonDic = json as? [String: AnyObject] {
                    let errorCode = jsonDic["error"]?["code"] as? Int
                    let errorSubCode = jsonDic["error"]?["error_subcode"] as? Int
                    if (errorCode == 102 && errorSubCode == nil) || errorSubCode == 463 || errorSubCode == 467 {
                        return true
                    }
                }
            }
        }

		return false
	}

}
