//
//  OAuthSwiftClient.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation

var OAuthSwiftDataEncoding: String.Encoding = String.Encoding.utf8

public protocol OAuthSwiftRequestHandle {
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
    public init(consumerKey: String, consumerSecret: String) {
        self.credential = OAuthSwiftCredential(consumer_key: consumerKey, consumer_secret: consumerSecret)
    }
    
    public init(consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String) {
        self.credential = OAuthSwiftCredential(oauth_token: accessToken, oauth_token_secret: accessTokenSecret)
        self.credential.consumer_key = consumerKey
        self.credential.consumer_secret = consumerSecret
    }
    
    public init(credential: OAuthSwiftCredential) {
        self.credential = credential
    }

    // MARK: client methods
    open func get(_ urlString: String, parameters: [String: Any] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .GET, parameters: parameters, headers: headers, success: success, failure: failure)
    }
    
    open func post(_ urlString: String, parameters: [String: Any] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .POST, parameters: parameters, headers: headers, success: success, failure: failure)
    }

    open func put(_ urlString: String, parameters: [String: Any] = [:], headers: [String:String]? = nil, body: Data? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .PUT, parameters: parameters, headers: headers, body: body, success: success, failure: failure)
    }

    open func delete(_ urlString: String, parameters: [String: Any] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .DELETE, parameters: parameters, headers: headers,success: success, failure: failure)
    }

    open func patch(_ urlString: String, parameters: [String: Any] = [:], headers: [String:String]? = nil, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        return self.request(urlString, method: .PATCH, parameters: parameters, headers: headers,success: success, failure: failure)
    }
    
    open func request(_ url: String, method: OAuthSwiftHTTPRequest.Method, parameters: [String: Any] = [:], headers: [String:String]? = nil, body: Data? = nil, checkTokenExpiration: Bool = true, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) -> OAuthSwiftRequestHandle? {
        
        if checkTokenExpiration && self.credential.isTokenExpired()  {
            let errorInfo = [NSLocalizedDescriptionKey: NSLocalizedString("The provided token is expired.", comment:"Token expired, retrieve new token by using the refresh token")]
            
            if let failureHandler = failure {
                failureHandler(NSError(domain: OAuthSwiftErrorDomain, code: OAuthSwiftErrorCode.tokenExpiredError.rawValue, userInfo: errorInfo))
            }
            
            return nil
        }
        
        if let request = makeRequest(url, method: method, parameters: parameters, headers: headers, body: body) {
            request.successHandler = success
            request.failureHandler = failure
            request.start()
            return request
        }
        return nil
    }

    open func makeRequest(_ request: URLRequest) -> OAuthSwiftHTTPRequest {
        let request = OAuthSwiftHTTPRequest(request: request, paramsLocation: self.paramsLocation)
        return makeOAuthSwiftHTTPRequest(request)
    }

    open func makeRequest(_ urlString: String, method: OAuthSwiftHTTPRequest.Method, parameters: [String: Any] = [:], headers: [String:String]? = nil, body: Data? = nil) -> OAuthSwiftHTTPRequest? {
        guard let url = URL(string: urlString) else {
            return nil
        }

        let request = OAuthSwiftHTTPRequest(URL: url, method: method, parameters: parameters, paramsLocation: self.paramsLocation)
        if let addHeaders = headers {
            request.headers = addHeaders
        }
        if let addBody = body {
            request.HTTPBody = addBody
        }
        return makeOAuthSwiftHTTPRequest(request)
    }

    open func makeOAuthSwiftHTTPRequest(_ request: OAuthSwiftHTTPRequest) -> OAuthSwiftHTTPRequest {
        var requestHeaders = [String:String]()
        var signatureUrl = request.URL
        var signatureParameters = request.parameters

        // Check if body must be hashed (oauth1)
        let body: Data? = nil
        if request.HTTPMethod.isBody {
            if let contentType = request.headers["Content-Type"]?.lowercased() {

                if contentType.range(of: "application/json") != nil {
                    // TODO: oauth_body_hash create body before signing if implementing body hashing
                    /*do {
                    let jsonData: NSData = try NSJSONSerialization.dataWithJSONObject(parameters, options: [])
                    request.HTTPBody = jsonData
                    requestHeaders["Content-Length"] = "\(jsonData.length)"
                    body = jsonData
                    }
                    catch {
                    }*/

                    signatureParameters = [:] // parameters are not used for general signature (could only be used for body hashing
                }
                // else other type are not supported, see setupRequestForOAuth()
            }
        }

        // Need to account for the fact that some consumers will have additional parameters on the
        // querystring, including in the case of fetching a request token. Especially in the case of
        // additional parameters on the request, authorize, or access token exchanges, we need to
        // normalize the URL and add to the parametes collection.

        var queryStringParameters = [String: Any]()
        var urlComponents = URLComponents(url: request.URL as URL, resolvingAgainstBaseURL: false )
        if let queryItems = urlComponents?.queryItems {
            for queryItem in queryItems {
                let value = queryItem.value?.safeStringByRemovingPercentEncoding ?? ""
                queryStringParameters.updateValue(value as AnyObject, forKey: queryItem.name)
            }
        }

        // According to the OAuth1.0a spec, the url used for signing is ONLY scheme, path, and query
        if(queryStringParameters.count>0)
        {
            urlComponents?.query = nil
            // This is safe to unwrap because these just came from an NSURL
            signatureUrl = urlComponents?.url ?? request.URL
        }
        signatureParameters = signatureParameters.join(queryStringParameters)

        switch self.paramsLocation {
        case .authorizationHeader:
            //Add oauth parameters in the Authorization header
            requestHeaders += self.credential.makeHeaders(signatureUrl, method: request.HTTPMethod, parameters: signatureParameters, body: body)
        case .requestURIQuery:
            //Add oauth parameters as request parameters
            request.parameters += self.credential.authorizationParametersWithSignatureForMethod(request.HTTPMethod, url: signatureUrl, parameters: signatureParameters, body: body)
        }

        request.headers = requestHeaders + request.headers
        request.dataEncoding = OAuthSwiftDataEncoding
        
        return request
    }

    open func postImage(_ urlString: String, parameters: [String: Any], image: Data, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?)  -> OAuthSwiftRequestHandle? {
        return self.multiPartRequest(urlString, method: .POST, parameters: parameters, image: image, success: success, failure: failure)
    }

    func multiPartRequest(_ url: String, method: OAuthSwiftHTTPRequest.Method, parameters: [String: Any], image: Data, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?)  -> OAuthSwiftRequestHandle? {

        if let request = makeRequest(url, method: method, parameters: parameters) {
            
            var paramImage = [String: Any]()
            paramImage["media"] = image
            let boundary = "AS-boundary-\(arc4random())-\(arc4random())"
            let type = "multipart/form-data; boundary=\(boundary)"
            let body = self.multiPartBodyFromParams(paramImage, boundary: boundary)
            
            request.HTTPBody = body
            request.headers += ["Content-Type": type] // "Content-Length": body.length.description
            
            request.successHandler = success
            request.failureHandler = failure
            request.start()
            return request
        }
        return nil
    }

    open func multiPartBodyFromParams(_ parameters: [String: Any], boundary: String) -> Data {
        let data = NSMutableData()

        let prefixString = "--\(boundary)\r\n"
        let prefixData = prefixString.data(using: OAuthSwiftDataEncoding)!

        
        for (key, value) in parameters {
            var sectionData: Data
            var sectionType: String?
            var sectionFilename: String?
            if  let multiData = value as? Data , key == "media" {
                sectionData = multiData
                sectionType = "image/jpeg"
                sectionFilename = "file"
            } else {
                sectionData = "\(value)".data(using: OAuthSwiftDataEncoding)!
            }

            data.append(prefixData)
            let multipartData = OAuthSwiftMultipartData(name: key, data: sectionData, fileName: sectionFilename, mimeType: sectionType)
            data.appendMultipartData(multipartData, encoding: OAuthSwiftDataEncoding, separatorData: OAuthSwiftClient.separatorData)
        }

        let endingString = "--\(boundary)--\r\n"
        let endingData = endingString.data(using: OAuthSwiftDataEncoding)!
        data.append(endingData)
        return data as Data
    }
    
    open func postMultiPartRequest(_ url: String, method: OAuthSwiftHTTPRequest.Method, parameters: [String: Any], headers: Dictionary<String, String>? = nil, multiparts: Array<OAuthSwiftMultipartData> = [], checkTokenExpiration: Bool = true, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        
        if let request = makeRequest(url, method: method, parameters: parameters, headers: headers) {

            let boundary = "POST-boundary-\(arc4random())-\(arc4random())"
            let type = "multipart/form-data; boundary=\(boundary)"
            let body = self.multiDataFromObject(parameters, multiparts: multiparts, boundary: boundary)

            request.HTTPBody = body
            request.headers += ["Content-Type": type] // "Content-Length": body.length.description
            
            request.successHandler = success
            request.failureHandler = failure
            request.start()
        }
    }

    func multiDataFromObject(_ object: [String: Any], multiparts: Array<OAuthSwiftMultipartData>, boundary: String) -> Data? {
        let data = NSMutableData()

        let prefixString = "--\(boundary)\r\n"
        let prefixData = prefixString.data(using: OAuthSwiftDataEncoding)!

        for (key, value) in object {
            guard let valueData = "\(value)".data(using: OAuthSwiftDataEncoding) else {
                continue
            }
            data.append(prefixData)
            let multipartData = OAuthSwiftMultipartData(name: key, data: valueData, fileName: nil, mimeType: nil)
            data.appendMultipartData(multipartData, encoding: OAuthSwiftDataEncoding, separatorData: OAuthSwiftClient.separatorData)
        }

        for multipart in multiparts {
            data.append(prefixData)
            data.appendMultipartData(multipart, encoding: OAuthSwiftDataEncoding, separatorData: OAuthSwiftClient.separatorData)
        }

        let endingString = "--\(boundary)--\r\n"
        let endingData = endingString.data(using: OAuthSwiftDataEncoding)!
        data.append(endingData)

        return data as Data
    }

}
