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
        if count(queryString.utf16) == 0 {
            return self
        }

        var absoluteURLString = self.absoluteString!

        if absoluteURLString.hasSuffix("?") {
            absoluteURLString = (absoluteURLString as NSString).substringToIndex(count(absoluteURLString.utf16) - 1)
        }

        let URLString = absoluteURLString + (absoluteURLString.rangeOfString("?") != nil ? "&" : "?") + queryString

        return NSURL(string: URLString)!
    }

}
