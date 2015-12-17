//
//  Dictionary+OAuthSwift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

extension Dictionary {

    func join(other: Dictionary) -> Dictionary {
        var joinedDictionary = Dictionary()

        for (key, value) in self {
            joinedDictionary.updateValue(value, forKey: key)
        }

        for (key, value) in other {
            joinedDictionary.updateValue(value, forKey: key)
        }

        return joinedDictionary
    }

    func filter(predicate: (key: Key, value: Value) -> Bool) -> Dictionary {
        var filteredDictionary = Dictionary()

        for (key, value) in self {
            if predicate(key: key, value: value) {
                filteredDictionary.updateValue(value, forKey: key)
            }
        }

        return filteredDictionary
    }

    func urlEncodedQueryStringWithEncoding(encoding: NSStringEncoding) -> String {
        var parts = [String]()

        for (key, value) in self {
            let keyString = "\(key)".urlEncodedStringWithEncoding(encoding)
            let valueString = "\(value)".urlEncodedStringWithEncoding(encoding)
            let query = "\(keyString)=\(valueString)" as String
            parts.append(query)
        }

        return parts.joinWithSeparator("&") as String
    }

    mutating func merge<K, V>(dictionaries: Dictionary<K, V>...) {
        for dict in dictionaries {
            for (key, value) in dict {
                self.updateValue(value as! Value, forKey: key as! Key)
            }
        }
    }

    func map<K: Hashable, V> (transform: (Key, Value) -> (K, V)) -> Dictionary<K, V> {
        var results: Dictionary<K, V> = [:]
        for k in self.keys {
            if let value = self[ k ] {
                let (u, w) = transform(k, value)
                results.updateValue(w, forKey: u)
            }
        }
        return results
    }
}

public func +=<K, V> (inout left: [K : V], right: [K : V]) { left.merge(right) }
public func +<K, V> (left: [K : V], right: [K : V]) -> [K : V] { return left.join(right) }
