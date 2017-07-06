//
//  HMAC_SHA1SignatureMethod.swift
//  OAuthSwift
//
//  Created by Noam Bar-on on 6/22/17.
//  Copyright © 2017 Dongri Jin. All rights reserved.
//

import Foundation

final class  HMAC_SHA1SignatureMethod: BaseOAuthSwiftSignatureMethod {
    override var description: String {
        return "HMAC-SHA1"
    }
    override func sign(key: Data, message: Data) -> Data? {
        return HMAC.sha1(key: key, message: message)
    }
    override func sign(data: Data) -> Data? {
        let mac = SHA1(data).calculate()
        return Data(bytes: UnsafePointer<UInt8>(mac), count: mac.count)
    }
}
