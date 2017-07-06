//
//  BaseOAuthSwiftVersion.swift
//  OAuthSwift
//
//  Created by Noam Bar-on on 6/22/17.
//  Copyright © 2017 Dongri Jin. All rights reserved.
//

import Foundation

class BaseOAuthSwiftVersion: NSObject, OAuthSwiftVersion {
    override var description: String {
        preconditionFailure("This abstract method must be overridden")
        // return "oauth1"
    }
    var shortVersion: String {
        preconditionFailure("This abstract method must be overridden")
        //return "1.0"
    }
    var signatureMethod: OAuthSwiftSignatureMethod
    
    public convenience init(with signatureMethod: OAuthSwiftSignatureMethod) {
        self.init()
        self.signatureMethod = signatureMethod
    }
    // MARK: init
    override init() {
         self.signatureMethod = HMAC_SHA1SignatureMethod() // default
    }
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.signatureMethod, forKey: "signatureMethod")
    }
    public required convenience init?(coder decoder: NSCoder) {
        self.init()
        self.signatureMethod = (decoder.decodeObject(forKey: "signatureMethod") as! OAuthSwiftSignatureMethod)
    }
}
