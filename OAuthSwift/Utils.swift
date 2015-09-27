//
//  Utils.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 1/28/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import Foundation

func rotateLeft(v:UInt16, n:UInt16) -> UInt16 {
    return ((v << n) & 0xFFFF) | (v >> (16 - n))
}

func rotateLeft(v:UInt32, n:UInt32) -> UInt32 {
    return ((v << n) & 0xFFFFFFFF) | (v >> (32 - n))
}

func rotateLeft(x:UInt64, n:UInt64) -> UInt64 {
    return (x << n) | (x >> (64 - n))
}

func rotateRight(x:UInt16, n:UInt16) -> UInt16 {
    return (x >> n) | (x << (16 - n))
}

func rotateRight(x:UInt32, n:UInt32) -> UInt32 {
    return (x >> n) | (x << (32 - n))
}

func rotateRight(x:UInt64, n:UInt64) -> UInt64 {
    return ((x >> n) | (x << (64 - n)))
}

func reverseBytes(value: UInt32) -> UInt32 {
    let tmp1 = ((value & 0x000000FF) << 24) | ((value & 0x0000FF00) << 8)
    let tmp2 = ((value & 0x00FF0000) >> 8)  | ((value & 0xFF000000) >> 24)
    return tmp1 | tmp2
}

public func generateStateWithLength (len : Int) -> NSString {
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let randomString : NSMutableString = NSMutableString(capacity: len)
    for (var i=0; i < len; i++){
        let length = UInt32 (letters.length)
        let rand = arc4random_uniform(length)
        randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
    }
    return randomString
}
