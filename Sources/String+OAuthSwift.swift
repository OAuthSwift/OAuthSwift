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

        while !scanner.isAtEnd {
            if #available(iOS 13.0, tvOS 13.0, OSX 10.15, watchOS 6.0, *) {
                let key = scanner.scanUpToString(keyValueSeparator)
                _ = scanner.scanString(keyValueSeparator)

                let value = scanner.scanUpToString(elementSeparator)
                _ = scanner.scanString(elementSeparator)

                if let key = key {
                    if let value = value {
                        if key.contains(elementSeparator) {
                            var keys = key.components(separatedBy: elementSeparator)
                            if let key = keys.popLast() {
                                parameters.updateValue(value, forKey: String(key))
                            }
                            for flag in keys {
                                parameters.updateValue("", forKey: flag)
                            }
                        } else {
                            parameters.updateValue(value, forKey: key)
                        }
                    } else {
                        parameters.updateValue("", forKey: key)
                    }
                }
            } else {
                var key: NSString?
                scanner.scanUpTo(keyValueSeparator, into: &key)
                scanner.scanString(keyValueSeparator, into: nil)

                var value: NSString?
                scanner.scanUpTo(elementSeparator, into: &value)
                scanner.scanString(elementSeparator, into: nil)
                if let key = key as String? {
                    if let value = value as String? {
                        if key.contains(elementSeparator) {
                            var keys = key.components(separatedBy: elementSeparator)
                            if let key = keys.popLast() {
                                parameters.updateValue(value, forKey: String(key))
                            }
                            for flag in keys {
                                parameters.updateValue("", forKey: flag)
                            }
                        } else {
                            parameters.updateValue(value, forKey: key)
                        }
                    } else {
                        parameters.updateValue("", forKey: key)
                    }
                }
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

    mutating func dropLast() {
        self.remove(at: self.index(before: self.endIndex))
    }

    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}

extension String.Encoding {

    var charset: String {
        let charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.rawValue))
         // swiftlint:disable:next force_cast superfluous_disable_command
        return charset! as String
    }

}
