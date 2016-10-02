//
//  HMAC.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 1/28/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//


import Foundation

open class HMAC {
    
    let key:[UInt8] = []
    
    class internal func sha1(key: Data, message: Data) -> Data? {
        let blockSize = 64
        var key = key.bytes
        let message = message.bytes

        if (key.count > blockSize) {
            key = SHA1(key).calculate()
        }
        else if (key.count < blockSize) { // padding
            key = key + [UInt8](repeating: 0, count: blockSize - key.count)
        }
        
        var ipad = [UInt8](repeating: 0x36, count: blockSize)
        for idx in key.indices {
            ipad[idx] = key[idx] ^ ipad[idx]
        }

        var opad = [UInt8](repeating: 0x5c, count: blockSize)
        for idx in key.indices {
            opad[idx] = key[idx] ^ opad[idx]
        }

        let ipadAndMessageHash = SHA1(ipad + message).calculate()
        let mac = SHA1(opad + ipadAndMessageHash).calculate()

        return Data(bytes: UnsafePointer<UInt8>(mac), count: mac.count)

    }

}
