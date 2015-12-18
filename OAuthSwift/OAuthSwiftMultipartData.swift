//
//  OAuthSwiftMultipartData.swift
//  Pods
//
//  Created by Tomohiro Kawaji on 2015/12/18.
//
//

import Foundation

public struct OAuthSwiftMultipartData {

    var name: String?
    var data: NSData?
    var fileName: String?
    var mimeType: String?

    public init(name: String, data: NSData, fileName: String, mimeType: String) {
        self.name = name
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }

}
