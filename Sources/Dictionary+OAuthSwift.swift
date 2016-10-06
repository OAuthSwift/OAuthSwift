//
//  Dictionary+OAuthSwift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

extension Dictionary {

    func join(_ other: Dictionary) -> Dictionary {
        var joinedDictionary = Dictionary()

        for (key, value) in self {
            joinedDictionary.updateValue(value, forKey: key)
        }

        for (key, value) in other {
            joinedDictionary.updateValue(value, forKey: key)
        }

        return joinedDictionary
    }

    func filter(_ predicate: (_ key: Key, _ value: Value) -> Bool) -> Dictionary {
        var filteredDictionary = Dictionary()

        for (key, value) in self {
            if predicate(key, value) {
                filteredDictionary.updateValue(value, forKey: key)
            }
        }

        return filteredDictionary
    }

    var urlEncodedQuery: String {
        var parts = [String]()

        for (key, value) in self {
            let keyString = "\(key)".urlEncodedString
            let valueString = "\(value)".urlEncodedString
            let query = "\(keyString)=\(valueString)"
            parts.append(query)
        }

        return parts.joined(separator: "&")
    }

    mutating func merge<K, V>(_ dictionaries: Dictionary<K, V>...) {
        for dict in dictionaries {
            for (key, value) in dict {
                self.updateValue(value as! Value, forKey: key as! Key)
            }
        }
    }

    func map<K: Hashable, V> (_ transform: (Key, Value) -> (K, V)) -> Dictionary<K, V> {
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

func +=<K, V> (left: inout [K : V], right: [K : V]) { left.merge(right) }
func +<K, V> (left: [K : V], right: [K : V]) -> [K : V] { return left.join(right) }
func +=<K, V> (left: inout [K : V]?, right: [K : V]) {
    if let _ = left { left?.merge(right) } else { left = right }
}
