//
//  HMAC.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 1/28/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//


import Foundation

public class HMAC {
    
    let key:[UInt8] = []
    
    class internal func sha1(key  key: NSData, message: NSData) -> NSData? {
        var key = key.bytes()
        let message = message.bytes()
        
        // key
        if (key.count > 64) {
            key = SHA1(NSData.withBytes(key)).calculate().bytes()
        }
        
        if (key.count < 64) {
            key = key + [UInt8](count: 64 - key.count, repeatedValue: 0)
        }
        
        //
        var opad = [UInt8](count: 64, repeatedValue: 0x5c)
        for (idx, _) in key.enumerate() {
            opad[idx] = key[idx] ^ opad[idx]
        }
        var ipad = [UInt8](count: 64, repeatedValue: 0x36)
        for (idx, _) in key.enumerate() {
            ipad[idx] = key[idx] ^ ipad[idx]
        }
        
        let ipadAndMessageHash = SHA1(NSData.withBytes(ipad + message)).calculate().bytes()
        let finalHash = SHA1(NSData.withBytes(opad + ipadAndMessageHash)).calculate().bytes()
        let mac = finalHash

        return NSData(bytes: mac, length: mac.count)

    }

}