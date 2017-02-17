//
//  URL+OAuthSwift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

extension URL {

    func urlByAppending(queryString: String) -> URL {
        if queryString.utf16.isEmpty {
            return self
        }

        var absoluteURLString = absoluteString

        if absoluteURLString.hasSuffix("?") {
             absoluteURLString.dropLast()
        }

        let string = absoluteURLString + (absoluteURLString.range(of: "?") != nil ? "&" : "?") + queryString

        return URL(string: string)!
    }

}
