//
//  Data+OAuthSwift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 1/28/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import Foundation

extension Data {

    internal init(data: Data) {
        self.init()
        self.append(data)
    }

    internal mutating func append(_ bytes: [UInt8]) {
        self.append(bytes, count: bytes.count)
    }
    internal mutating func append(_ byte: UInt8) {
        append([byte])
    }
    internal mutating func append(_ byte: UInt16) {
        append(UInt8(byte >> 0 & 0xFF))
        append(UInt8(byte >> 8 & 0xFF))
    }
    internal  mutating func append(_ byte: UInt32) {
        append(UInt16(byte >>  0 & 0xFFFF))
        append(UInt16(byte >> 16 & 0xFFFF))
    }
    internal mutating func append(_  byte: UInt64) {
        append(UInt32(byte >>  0 & 0xFFFFFFFF))
        append(UInt32(byte >> 32 & 0xFFFFFFFF))
    }

    var bytes: [UInt8] {
        return Array(self)
        /* let count = self.count / MemoryLayout<UInt8>.size
         var bytesArray = [UInt8](repeating: 0, count: count)
        self.copyBytes(to:&bytesArray, count: count * MemoryLayout<UInt8>.size)
        return bytesArray*/
    }

}

