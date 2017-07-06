//
//  OAuthSwiftVersion.swift
//  OAuthSwift
//
//  Created by Noam Bar-on on 6/22/17.
//  Copyright © 2017 Dongri Jin. All rights reserved.
//

import Foundation

// Protocol for version object
// For your convenience, find BaseVersion class you can subclass
public protocol OAuthSwiftVersion: CustomStringConvertible, NSCoding, NSObjectProtocol {
    var description: String {get}
    var shortVersion: String {get}
    var signatureMethod: OAuthSwiftSignatureMethod {set get}
}
