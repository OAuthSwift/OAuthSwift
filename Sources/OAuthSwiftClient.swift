//
//  OAuthSwiftClient.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

var OAuthSwiftDataEncoding: String.Encoding = .utf8

@objc public protocol OAuthSwiftRequestHandle {
    func cancel()
}

open class OAuthSwiftClient: NSObject {

    fileprivate(set) open var credential: OAuthSwiftCredential
    open var paramsLocation: OAuthSwiftHTTPRequest.ParamsLocation = .authorizationHeader

    static let separator: String = "\r\n"
    static var separatorData: Data = {
        return OAuthSwiftClient.separator.data(using: OAuthSwiftDataEncoding)!
    }()

    // MARK: init
    public init(credential: OAuthSwiftCredential) {
        self.credential = credential
    }
    
    public convenience init(consumerKey: String, consumerSecret: String, version: OAuthSwiftCredential.Version = .oauth1) {
        let credential = OAuthSwiftCredential(consumerKey: consumerKey, consumerSecret: consumerSecret)
        credential.version = version
        self.init(credential: credential)
    }

    public convenience init(consumerKey: String, consumerSecret: String, oauthToken: String, oauthTokenSecret: String, version: OAuthSwiftCredential.Version) {
        self.init(consumerKey: consumerKey, consumerSecret: consumerSecret, version: version)
        self.credential.oauthToken = oauthToken
        self.credential.oauthTokenSecret = oauthTokenSecret
        
    }

    // MARK: client methods
    @discardableResult
    open func get(_ urlString: String, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .GET, parameters: parameters, headers: headers, success: success, failure: failure)
    }
    
    @discardableResult
    open func post(_ urlString: String, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, body: Data? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .POST, parameters: parameters, headers: headers, body: body, success: success, failure: failure)
    }
    
    @discardableResult
    open func put(_ urlString: String, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, body: Data? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .PUT, parameters: parameters, headers: headers, body: body, success: success, failure: failure)
    }
    
    @discardableResult
    open func delete(_ urlString: String, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .DELETE, parameters: parameters, headers: headers,success: success, failure: failure)
    }
    
    @discardableResult
    open func patch(_ urlString: String, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .PATCH, parameters: parameters, headers: headers,success: success, failure: failure)
    }
    
    @discardableResult
    open func request(_ urlString: String, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, body: Data? = nil, checkTokenExpiration: Bool = true, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        
        if checkTokenExpiration && self.credential.isTokenExpired() {
            failure?(OAuthSwiftError.tokenExpired(error: nil))
            return nil
        }

        guard let _ = URL(string: urlString) else {
            failure?(OAuthSwiftError.encodingError(urlString: urlString))
            return nil
        }

        if let request = makeRequest(urlString, method: method, parameters: parameters, headers: headers, body: body) {
            request.start(success: success, failure: failure)
            return request
        }
        return nil
    }

    open func makeRequest(_ request: URLRequest) -> OAuthSwiftHTTPRequest {
        let request = OAuthSwiftHTTPRequest(request: request, paramsLocation: self.paramsLocation)
        request.config.updateRequest(credential: self.credential)
        return request
    }

    open func makeRequest(_ urlString: String, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters = [:], headers: OAuthSwift.Headers? = nil, body: Data? = nil) -> OAuthSwiftHTTPRequest? {
        guard let url = URL(string: urlString) else {
            return nil
        }

        let request = OAuthSwiftHTTPRequest(url: url, method: method, parameters: parameters, paramsLocation: self.paramsLocation, httpBody: body, headers: headers ?? [:])
        request.config.updateRequest(credential: self.credential)
        return request
    }
    
    @discardableResult
    public func postImage(_ urlString: String, parameters: OAuthSwift.Parameters, image: Data, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?)  -> OAuthSwiftRequestHandle? {
        return self.multiPartRequest(url: urlString, method: .POST, parameters: parameters, image: image, success: success, failure: failure)
    }

    open func makeMultiPartRequest(_ urlString: String, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters = [:], multiparts: Array<OAuthSwiftMultipartData> = [], headers: OAuthSwift.Headers? = nil) -> OAuthSwiftHTTPRequest? {
        let boundary = "AS-boundary-\(arc4random())-\(arc4random())"
        let type = "multipart/form-data; boundary=\(boundary)"
        let body = self.multiDataFromObject(parameters, multiparts: multiparts, boundary: boundary)

        var finalHeaders = [kHTTPHeaderContentType: type]
        finalHeaders += headers ?? [:]

        return makeRequest(urlString, method: method, parameters: parameters, headers: finalHeaders, body: body)
    }

    func multiPartRequest(url: String, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters, image: Data, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        let multiparts = [ OAuthSwiftMultipartData(name: "media", data: image, fileName: "file", mimeType: "image/jpeg") ]

        if let request = makeMultiPartRequest(url, method: method, parameters: parameters, multiparts: multiparts) {
            request.start(success: success, failure: failure)
            return request
        }

        return nil
    }

    open func multiPartBody(from inputParameters: OAuthSwift.Parameters, boundary: String) -> Data {
        var parameters = OAuthSwift.Parameters()
        var multiparts = Array<OAuthSwiftMultipartData>()
        
        for (key, value) in inputParameters {
            if  let data = value as? Data , key == "media" {
                let sectionType = "image/jpeg"
                let sectionFilename = "file"
                multiparts.append(OAuthSwiftMultipartData(name: key, data: data, fileName: sectionFilename, mimeType: sectionType))
            } else {
                parameters[key] = value
            }
        }
        
        return multiDataFromObject(parameters, multiparts: multiparts, boundary: boundary)
    }
    
    @discardableResult
    open func postMultiPartRequest(_ url: String, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters, headers: Dictionary<String, String>? = nil, multiparts: Array<OAuthSwiftMultipartData> = [], checkTokenExpiration: Bool = true, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        
        if checkTokenExpiration && self.credential.isTokenExpired() {
            failure?(OAuthSwiftError.tokenExpired(error: nil))
            return nil
        }

        if let request = makeMultiPartRequest(url, method: method, parameters: parameters, multiparts: multiparts, headers: headers) {
            request.start(success: success, failure: failure)
            return request
        }
        return nil
    }

    func multiDataFromObject(_ object: OAuthSwift.Parameters, multiparts: Array<OAuthSwiftMultipartData>, boundary: String) -> Data {
        var data = Data()

        let prefixString = "--\(boundary)\r\n"
        let prefixData = prefixString.data(using: OAuthSwiftDataEncoding)!

        for (key, value) in object {
            guard let valueData = "\(value)".data(using: OAuthSwiftDataEncoding) else {
                continue
            }
            data.append(prefixData)
            let multipartData = OAuthSwiftMultipartData(name: key, data: valueData, fileName: nil, mimeType: nil)
            data.append(multipartData, encoding: OAuthSwiftDataEncoding, separatorData: OAuthSwiftClient.separatorData)
        }

        for multipart in multiparts {
            data.append(prefixData)
            data.append(multipart, encoding: OAuthSwiftDataEncoding, separatorData: OAuthSwiftClient.separatorData)
        }

        let endingString = "--\(boundary)--\r\n"
        let endingData = endingString.data(using: OAuthSwiftDataEncoding)!
        data.append(endingData)

        return data
    }

}
