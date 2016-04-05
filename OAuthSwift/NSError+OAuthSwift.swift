//
//  NSError+OAuthSwift.swift
//  OAuthSwift
//
//  Created by Goessler, Florian on 04/04/16.
//  Copyright © 2016 Dongri Jin. All rights reserved.
//

import Foundation

extension NSError {

	var isExpiredTokenError: Bool {
		if self.code == 401 {
			if let reponseHeaders = self.userInfo["Response-Headers"] as? [String:String],
				authenticateHeader = reponseHeaders["WWW-Authenticate"] ?? reponseHeaders["Www-Authenticate"] {
				let headerDictionary = authenticateHeader.headerDictionary
				if let error = headerDictionary["error"] where error == "invalid_token" || error == "\"invalid_token\"" {
					return true
				}
			}
		}

		// TODO: add handling for facebook errors - see wiki

		return false
	}

}
