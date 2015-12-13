//
//  String+OAuthSwift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

extension String {

    internal func indexOf(sub: String) -> Int? {
        var pos: Int?
        
        if let range = self.rangeOfString(sub) {
            if !range.isEmpty {
                pos = self.startIndex.distanceTo(range.startIndex)
            }
        }
        
        return pos
    }
    
    internal subscript (r: Range<Int>) -> String {
        get {
            let startIndex = self.startIndex.advancedBy(r.startIndex)
            let endIndex = startIndex.advancedBy(r.endIndex - r.startIndex)
            
            return self[Range(start: startIndex, end: endIndex)]
        }
    }

    func urlEncodedStringWithEncoding(encoding: NSStringEncoding) -> String {
        let originalString: NSString = self
        let customAllowedSet =  NSCharacterSet(charactersInString:" :/?&=;+!@#$()',*=\"#%/<>?@\\^`{|}").invertedSet
        let escapedString = originalString.stringByAddingPercentEncodingWithAllowedCharacters(customAllowedSet)
        return escapedString! as String
    }

    func parametersFromQueryString() -> Dictionary<String, String> {
        return dictionaryBySplitting("&", keyValueSeparator: "=")
    }
    
    func dictionaryBySplitting(elementSeparator: String, keyValueSeparator: String) -> Dictionary<String, String> {
        var parameters = Dictionary<String, String>()

        let scanner = NSScanner(string: self)

        var key: NSString?
        var value: NSString?

        while !scanner.atEnd {
            key = nil
            scanner.scanUpToString(keyValueSeparator, intoString: &key)
            scanner.scanString(keyValueSeparator, intoString: nil)

            value = nil
            scanner.scanUpToString(elementSeparator, intoString: &value)
            scanner.scanString(elementSeparator, intoString: nil)

            if (key != nil && value != nil) {
                parameters.updateValue(value! as String, forKey: key! as String)
            }
        }
        
        return parameters
    }
        
    public var headerDictionary: Dictionary<String, String> {
        return dictionaryBySplitting(",", keyValueSeparator: "=")
    }
    
    var safeStringByRemovingPercentEncoding: String {
        return self.stringByRemovingPercentEncoding ?? self
    }
    
    func split(s:String)->[String]{
        if s.isEmpty{
            var x=[String]()
            for y in self.characters{
                x.append(String(y))
            }
            return x
        }
        return self.componentsSeparatedByString(s)
    }
    func trim()->String{
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    func has(s:String)->Bool{
        if (self.rangeOfString(s) != nil) {
            return true
        }else{
            return false
        }
    }
    func hasBegin(s:String)->Bool{
        if self.hasPrefix(s) {
            return true
        }else{
            return false
        }
    }
    func hasEnd(s:String)->Bool{
        if self.hasSuffix(s) {
            return true
        }else{
            return false
        }
    }
    func length()->Int{
        return self.utf16.count
    }
    func size()->Int{
        return self.utf16.count
    }
    func `repeat`(times: Int) -> String{
        var result = ""
        for _ in 0..<times {
            result += self
        }
        return result
    }
    func reverse()-> String{
        let s=Array(self.split("").reverse())
        var x=""
        for y in s{
            x+=y
        }
        return x
    }
}

