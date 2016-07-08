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
        if queryString.utf16.count == 0 {
            return self
        }

        var absoluteURLString = unsafeAbsoluteString

        if absoluteURLString.hasSuffix("?") {
            absoluteURLString = (absoluteURLString as NSString).substringToIndex(absoluteURLString.utf16.count - 1)
        }

        let URLString = absoluteURLString + (absoluteURLString.rangeOfString("?") != nil ? "&" : "?") + queryString

        return NSURL(string: URLString)!
    }
    
    var unsafeAbsoluteString: String {
        #if swift(>=2.3)
            return self.absoluteString!
        #else
            return self.absoluteString
        #endif
    }

}
