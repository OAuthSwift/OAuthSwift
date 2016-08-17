//
//  String+OAuthSwift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

extension String {

    internal func indexOf(_ sub: String) -> Int? {
        var pos: Int?
        
        if let range = self.range(of: sub) {
            if !range.isEmpty {
                pos = self.characters.distance(from: self.startIndex, to: range.lowerBound)
            }
        }
        
        return pos
    }

    func urlEncodedStringWithEncoding(_ encoding: String.Encoding) -> String {
        let originalString = self as NSString
        let customAllowedSet =  CharacterSet(charactersIn:"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        let escapedString = originalString.addingPercentEncoding(withAllowedCharacters: customAllowedSet)
        return escapedString! as String
    }

    func parametersFromQueryString() -> Dictionary<String, String> {
        return dictionaryBySplitting("&", keyValueSeparator: "=")
    }
    
    var urlQueryEncoded: String? {
        return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
    }

    func dictionaryBySplitting(_ elementSeparator: String, keyValueSeparator: String) -> Dictionary<String, String> {
		
		var string = self
		if(hasPrefix(elementSeparator)) {
			string = String(characters.dropFirst(1))
		}
		
        var parameters = Dictionary<String, String>()

        let scanner = Scanner(string: string)

        var key: NSString?
        var value: NSString?

        while !scanner.isAtEnd {
            key = nil
            scanner.scanUpTo(keyValueSeparator, into: &key)
            scanner.scanString(keyValueSeparator, into: nil)

            value = nil
            scanner.scanUpTo(elementSeparator, into: &value)
            scanner.scanString(elementSeparator, into: nil)

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
        return self.removingPercentEncoding ?? self
    }
    
    func split(_ s:String)->[String]{
        if s.isEmpty{
            var x=[String]()
            for y in self.characters{
                x.append(String(y))
            }
            return x
        }
        return self.components(separatedBy: s)
    }
    func trim()->String{
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    func has(_ s:String)->Bool{
        if (self.range(of: s) != nil) {
            return true
        }else{
            return false
        }
    }
    func hasBegin(_ s:String)->Bool{
        if self.hasPrefix(s) {
            return true
        }else{
            return false
        }
    }
    func hasEnd(_ s:String)->Bool{
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
    func `repeat`(_ times: Int) -> String{
        var result = ""
        for _ in 0..<times {
            result += self
        }
        return result
    }
    func reverse()-> String{
        let s=Array(self.split("").reversed())
        var x=""
        for y in s{
            x+=y
        }
        return x
    }
}

