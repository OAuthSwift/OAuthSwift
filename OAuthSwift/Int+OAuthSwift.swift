//
//  Int+OAuthSwift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 1/28/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import Foundation

extension Int {
    public func bytes(_ totalBytes: Int = sizeof(Int)) -> [UInt8] {
        return arrayOfBytes(self, length: totalBytes)
    }
}

func arrayOfBytes<T>(_ value:T, length:Int? = nil) -> [UInt8] {
    let totalBytes = length ?? (sizeofValue(value) * 8)
    
    let valuePointer = UnsafeMutablePointer<T>(allocatingCapacity: 1)
    valuePointer.pointee = value
    
    let bytesPointer = UnsafeMutablePointer<UInt8>(valuePointer)
    var bytes = [UInt8](repeating: 0, count: totalBytes)
    for j in 0..<min(sizeof(T),totalBytes) {
        bytes[totalBytes - 1 - j] = (bytesPointer + j).pointee
    }
    
    valuePointer.deinitialize()
    valuePointer.deallocateCapacity(1)
    
    return bytes
}
