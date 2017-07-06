//
//  BaseOAuthSwiftSignatureMethod.swift
//  OAuthSwift
//
//  Created by Noam Bar-on on 6/22/17.
//  Copyright © 2017 Dongri Jin. All rights reserved.
//

import Foundation

class  BaseOAuthSwiftSignatureMethod: NSObject, OAuthSwiftSignatureMethod {
    override var description: String {
        preconditionFailure("This abstract method must be overridden")
        // return "HMAC-SHA1"
    }
    func sign(key: Data, message: Data) -> Data? {
        preconditionFailure("This abstract method must be overridden")
        // return HMAC.sha1(key: key, message: message)
    }
    func sign(data: Data) -> Data? {
        preconditionFailure("This abstract method must be overridden")
        // let mac = SHA1(data).calculate()
        // return Data(bytes: UnsafePointer<UInt8>(mac), count: mac.count)
    }
    // MARK: init
    override init() {
    }
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
    }
    public required convenience init?(coder decoder: NSCoder) {
        self.init()
    }
}
