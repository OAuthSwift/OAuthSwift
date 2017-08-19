//
//  RSA.swift
//  OAuthSwift
//
//  Created by Noam Bar-on on 6/19/17.
//  Copyright © 2017 Dongri Jin. All rights reserved.
//

import Foundation
import SwiftyRSA

open class RSA {
    
    class internal func sha1(key: Data, message: Data) -> Data? {
        var signedData:Data = Data()
        do {
            let privateKey = try PrivateKey(pemNamed: "private")
            let text = String.init(data:message, encoding:.utf8)!
            let clear = try ClearMessage(string: text, using: .utf8)
            let signature = try clear.signed(with: privateKey, digestType: .sha1)
            signedData = signature.data
        }catch {
            print("error caught \(error)")
        }
        return signedData
    }
}
