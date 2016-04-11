//
//  OAuthSwiftMultipartData.swift
//  OAuthSwift
//
//  Created by Tomohiro Kawaji on 12/18/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import Foundation

public struct OAuthSwiftMultipartData {

    public var name: String
    public var data: NSData
    public var fileName: String?
    public var mimeType: String?

    public init(name: String, data: NSData, fileName: String?, mimeType: String?) {
        self.name = name
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }

}

extension NSMutableData {

    public func appendMultipartData(multipartData: OAuthSwiftMultipartData, encoding: NSStringEncoding, separatorData: NSData) {
        var filenameClause = ""
        if let filename = multipartData.fileName {
            filenameClause = " filename=\"\(filename)\""
        }
        let contentDispositionString = "Content-Disposition: form-data; name=\"\(multipartData.name)\";\(filenameClause)\r\n"
        let contentDispositionData = contentDispositionString.dataUsingEncoding(encoding)!
        self.appendData(contentDispositionData)

        if let mimeType = multipartData.mimeType {
            let contentTypeString = "Content-Type: \(mimeType)\r\n"
            let contentTypeData = contentTypeString.dataUsingEncoding(encoding)!
            self.appendData(contentTypeData)
        }

        self.appendData(separatorData)
        self.appendData(multipartData.data)
        self.appendData(separatorData)
    }
}