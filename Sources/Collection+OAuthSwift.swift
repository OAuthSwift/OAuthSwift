//
//  Collection+OAuthSwift.swift
//  OAuthSwift
//
//  Created by phimage on 02/10/16.
//  Copyright © 2016 Dongri Jin. All rights reserved.
//

import Foundation

extension Collection where Self.Iterator.Element == UInt8, Self.Index == Int {
    
    var toUInt32: UInt32 {
        assert(self.count > 3)
        // XXX optimize do the job only for the first one...
        return toUInt32Array()[0]
    }
    
    func toUInt32Array() -> Array<UInt32> {
        var result = Array<UInt32>()
        result.reserveCapacity(16)
        for idx in stride(from: self.startIndex, to: self.endIndex, by: MemoryLayout<UInt32>.size) {
            var val: UInt32 = 0
            val |= self.count > 3 ? UInt32(self[idx.advanced(by: 3)]) << 24 : 0
            val |= self.count > 2 ? UInt32(self[idx.advanced(by: 2)]) << 16 : 0
            val |= self.count > 1 ? UInt32(self[idx.advanced(by: 1)]) << 8  : 0
            val |= self.count > 0 ? UInt32(self[idx]) : 0
            result.append(val)
        }
        
        return result
    }
}
