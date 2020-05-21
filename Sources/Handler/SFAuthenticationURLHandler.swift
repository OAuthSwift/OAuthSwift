//
//  SFAuthenticationURLHandler.swift
//  OAuthSwift
//
//  Created by phimage on 01/11/2019.
//  Copyright © 2019 Dongri Jin, Marchand Eric. All rights reserved.
//

import Foundation
#if os(iOS)
import SafariServices
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

#if !targetEnvironment(macCatalyst)
@available(iOS, introduced: 11.0, deprecated: 12.0)
open class SFAuthenticationURLHandler: OAuthSwiftURLHandlerType {
    var webAuthSession: SFAuthenticationSession!
    let callbackUrlScheme: String

    public init(callbackUrlScheme: String) {
        self.callbackUrlScheme = callbackUrlScheme
    }

    public func handle(_ url: URL) {
      OAuthSwift.log?.trace("SFAuthenticationURLHandler: init session with url: \(url.absoluteString)")
        webAuthSession = SFAuthenticationSession(
            url: url,
            callbackURLScheme: callbackUrlScheme,
            completionHandler: { callback, error in
                if let error = error {
                    let msg = error.localizedDescription.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                    let errorDomain = (error as NSError).domain
                    let errorCode = (error as NSError).code
                    let urlString = "\(self.callbackUrlScheme)?error=\(msg ?? "UNKNOWN")&error_domain=\(errorDomain)&error_code=\(errorCode)"
                    let url = URL(string: urlString)!
                    #if !OAUTH_APP_EXTENSIONS
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    #endif
                } else if let successURL = callback {
                    #if !OAUTH_APP_EXTENSIONS
                    UIApplication.shared.open(successURL, options: [:], completionHandler: nil)
                    #endif
                }
        })

        _ = webAuthSession.start()
    }
}

@available(iOS, introduced: 11.0, deprecated: 12.0)
extension SFAuthenticationURLHandler {
    static func isCancelledError(domain: String, code: Int) -> Bool {
        return domain == SFAuthenticationErrorDomain &&
            code == SFAuthenticationError.canceledLogin.rawValue
    }
}
#endif
#endif
