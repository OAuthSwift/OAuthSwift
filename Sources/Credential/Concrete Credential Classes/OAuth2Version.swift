//
//  OAuth2Version.swift
//  OAuthSwift
//
//  Created by Noam Bar-on on 6/22/17.
//  Copyright © 2017 Dongri Jin. All rights reserved.
//

import Foundation

final class OAuth2Version: BaseOAuthSwiftVersion {
    override var description: String {
        return "oauth2"
    }
    override var shortVersion: String {
        return "2.0"
    }
}
