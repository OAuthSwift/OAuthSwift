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

    var urlEncodedString: String {
        let customAllowedSet =  CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        let escapedString = self.addingPercentEncoding(withAllowedCharacters: customAllowedSet)
        return escapedString!
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

            if let key = key as? String, let value = value as? String {
                parameters.updateValue(value, forKey: key)
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
    
    var droppedLast: String {
       return self.substring(to: self.index(before: self.endIndex))
    }

    mutating func dropLast() {
        self.remove(at: self.index(before: self.endIndex))
    }

    func substring(to offset: String.IndexDistance) -> String{
        return self.substring(to: self.index(self.startIndex, offsetBy: offset))
    }

    func substring(from offset: String.IndexDistance) -> String{
        return self.substring(from: self.index(self.startIndex, offsetBy: offset))
    }
    
}

extension String.Encoding {
    
    var charset: String {
        let charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.rawValue))
        return charset as! String
    }

}

