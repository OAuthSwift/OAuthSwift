//
//  Int+OAuthSwift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 1/28/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import Foundation

extension Int {
    public func bytes(_ totalBytes: Int = sizeof(Int)) -> [Byte] {
        return arrayOfBytes(self, length: totalBytes)
    }
}

func arrayOfBytes<T>(value:T, length:Int? = nil) -> [Byte] {
    let totalBytes = length ?? (sizeofValue(value) * 8)
    var v = value
    
    var valuePointer = UnsafeMutablePointer<T>.alloc(1)
    valuePointer.memory = value
    
    var bytesPointer = UnsafeMutablePointer<Byte>(valuePointer)
    var bytes = [Byte](count: totalBytes, repeatedValue: 0)
    for j in 0..<min(sizeof(T),totalBytes) {
        bytes[totalBytes - 1 - j] = (bytesPointer + j).memory
    }
    
    valuePointer.destroy()
    valuePointer.dealloc(1)
    
    return bytes
}
