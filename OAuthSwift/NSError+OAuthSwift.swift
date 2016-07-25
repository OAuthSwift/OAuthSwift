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
	public var isExpiredTokenError: Bool {
		if self.domain == NSURLErrorDomain && self.code == 401 {
			if let reponseHeaders = self.userInfo["Response-Headers"] as? [String:String],
				authenticateHeader = reponseHeaders["WWW-Authenticate"] ?? reponseHeaders["Www-Authenticate"] {
				let headerDictionary = authenticateHeader.headerDictionary
				if let error = headerDictionary["error"] where error == "invalid_token" || error == "\"invalid_token\"" {
					return true
				}
			}
		}

        // Detect access token expiration errors from facebook
        // Docu: https://developers.facebook.com/docs/graph-api/using-graph-api#errors
        if self.domain == NSURLErrorDomain && self.code == 400 {
            if let urlString = self.userInfo[NSURLErrorFailingURLErrorKey] as? String
                where urlString.containsString("graph.facebook.com")
            {
                if let body = self.userInfo["Response-Body"] as? String,
                    let bodyData = body.dataUsingEncoding(OAuthSwiftDataEncoding),
                    let json = try? NSJSONSerialization.JSONObjectWithData(bodyData, options: NSJSONReadingOptions()),
                    let jsonDic = json as? [String: AnyObject]
                {
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
