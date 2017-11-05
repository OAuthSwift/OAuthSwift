//
//  Utils.swift
//  OAuthSwift
//
//  Created by phimage on 06/10/16.
//  Copyright © 2016 Dongri Jin. All rights reserved.
//

import Foundation

import XCTest
@testable import OAuthSwift

class UtilsTest: XCTestCase {
    
    func testMergeNilDictionaryWithOp() {
        
        var nilDico: OAuthSwift.Headers? = nil
        let addDico = ["Auth": "Bearer"]
        
        nilDico += addDico
        
        guard let dico = nilDico else {
            XCTFail()
            return
        }
        XCTAssertEqualDictionaries(dico, addDico)
    }
    
    func testMergeDictionary() {
        
        var dico: [String: String] = ["param": "value"]
        let addDico = ["Auth": "Bearer"]
        
        dico.merge(addDico)
      
        XCTAssertEqualDictionaries(dico, dico + addDico)
        
        
        XCTAssertEqualDictionaries(dico, ["param": "value", "Auth": "Bearer"])
        
    }
    
    func testGenerateState() {
        for l  in 0 ..< 20 {
            let str = generateState(withLength: l)
            XCTAssertEqual(str.count, l)
        }
    }
    
}
