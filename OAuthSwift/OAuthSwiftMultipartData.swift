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
    public var data: Data
    public var fileName: String?
    public var mimeType: String?

    public init(name: String, data: Data, fileName: String?, mimeType: String?) {
        self.name = name
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }

}

extension Data {

    public mutating func append(_ multipartData: OAuthSwiftMultipartData, encoding: String.Encoding, separatorData: Data) {
        var filenameClause = ""
        if let filename = multipartData.fileName {
            filenameClause = " filename=\"\(filename)\""
        }
        let contentDispositionString = "Content-Disposition: form-data; name=\"\(multipartData.name)\";\(filenameClause)\r\n"
        let contentDispositionData = contentDispositionString.data(using: encoding)!
        self.append(contentDispositionData)

        if let mimeType = multipartData.mimeType {
            let contentTypeString = "Content-Type: \(mimeType)\r\n"
            let contentTypeData = contentTypeString.data(using: encoding)!
            self.append(contentTypeData)
        }

        self.append(separatorData)
        self.append(multipartData.data)
        self.append(separatorData)
    }
}
