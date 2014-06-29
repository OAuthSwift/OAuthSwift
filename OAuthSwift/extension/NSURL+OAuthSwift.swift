//
//  NSURL+OAuthSwift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation


extension NSURL {

    func URLByAppendingQueryString(queryString: String) -> NSURL {
        if queryString.utf16count == 0 {
            return self
        }

        var absoluteURLString = self.absoluteString

        if absoluteURLString.hasSuffix("?") {
            absoluteURLString = absoluteURLString.substringToIndex(absoluteURLString.utf16count - 1)
        }

        let URLString = absoluteURLString + (absoluteURLString.rangeOfString("?") ? "&" : "?") + queryString

        return NSURL(string: URLString)
    }

}
