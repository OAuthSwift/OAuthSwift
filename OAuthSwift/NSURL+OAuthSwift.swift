//
//  NSURL+OAuthSwift.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation


extension URL {

    func URLByAppendingQueryString(_ queryString: String) -> URL {
        if queryString.utf16.count == 0 {
            return self
        }

        var absoluteURLString = unsafeAbsoluteString

        if absoluteURLString.hasSuffix("?") {
            absoluteURLString = (absoluteURLString as NSString).substring(to: absoluteURLString.utf16.count - 1)
        }

        let URLString = absoluteURLString + (absoluteURLString.range(of: "?") != nil ? "&" : "?") + queryString

        return URL(string: URLString)!
    }
    
    var unsafeAbsoluteString: String {
        return self.absoluteString
    }

}
