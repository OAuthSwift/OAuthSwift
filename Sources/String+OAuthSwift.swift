//
//  String+OAuthSwift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

extension String {

    var parametersFromQueryString: [String: String] {
        return dictionaryBySplitting("&", keyValueSeparator: "=")
    }

    /// Encodes url string making it ready to be passed as a query parameter. This encodes pretty much everything apart from
    /// alphanumerics and a few other characters compared to standard query encoding.
    var urlEncoded: String {
        let customAllowedSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return self.addingPercentEncoding(withAllowedCharacters: customAllowedSet)!
    }

    var urlQueryEncoded: String? {
        return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
    }

    /// Returns new url query string by appending query parameter encoding it first, if specified.
    func urlQueryByAppending(parameter name: String, value: String, encode: Bool = true, _ encodeError: ((String, String) -> Void)? = nil) -> String? {
        if value.isEmpty {
            return self
        } else if let value = encode ? value.urlQueryEncoded : value {
            return "\(self)\(self.isEmpty ? "" : "&")\(name)=\(value)"
        } else {
            encodeError?(name, value)
            return nil
        }
    }

    /// Returns new url string by appending query string at the end.
    func urlByAppending(query: String) -> String {
        return "\(self)\(self.contains("?") ? "&" : "?")\(query)"
    }

    fileprivate func dictionaryBySplitting(_ elementSeparator: String, keyValueSeparator: String) -> [String: String] {
        var string = self

        if hasPrefix(elementSeparator) {
            string = String(dropFirst(1))
        }

        var parameters = [String: String]()

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

            if let key = key as String?, let value = value as String? {
                parameters.updateValue(value, forKey: key)
            }
        }

        return parameters
    }

    public var headerDictionary: OAuthSwift.Headers {
        return dictionaryBySplitting(",", keyValueSeparator: "=")
    }

    var safeStringByRemovingPercentEncoding: String {
        return self.removingPercentEncoding ?? self
    }

    var droppedLast: String {
        let to = self.index(before: self.endIndex)
        return String(self[..<to])
    }

    mutating func dropLast() {
        self.remove(at: self.index(before: self.endIndex))
    }

    func substring(to offset: String.IndexDistance) -> String {
        let to = self.index(self.startIndex, offsetBy: offset)
        return String(self[..<to])
    }

    func substring(from offset: String.IndexDistance) -> String {
        let from = self.index(self.startIndex, offsetBy: offset)
        return String(self[from...])
    }
}

extension String.Encoding {

    var charset: String {
        let charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.rawValue))
         // swiftlint:disable:next force_cast
        return charset! as String
    }

}
