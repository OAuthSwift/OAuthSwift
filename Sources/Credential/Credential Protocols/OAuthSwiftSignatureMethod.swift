//
//  OAuthSwiftSignatureMethod.swift
//  OAuthSwift
//
//  Created by Noam Bar-on on 6/22/17.
//  Copyright © 2017 Dongri Jin. All rights reserved.
//

import Foundation

// Protocol for signature method object.
// For your convenience, find below a concrete BaseSignatureMethod class you can subclass
public protocol OAuthSwiftSignatureMethod: CustomStringConvertible, NSCoding, NSObjectProtocol {
    var description: String {get}
    func sign(key: Data, message: Data) -> Data?
    func sign(data: Data) -> Data?
}
