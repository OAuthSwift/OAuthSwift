//
//  OAuthSwiftURLHandlerProxy.swift
//  OAuthSwift
//
//  Created by phimage on 01/11/2019.
//  Copyright © 2019 Dongri Jin, Marchand Eric. All rights reserved.
//

import Foundation

/// Proxy class to make weak reference to handler.
open class OAuthSwiftURLHandlerProxy: OAuthSwiftURLHandlerType {
    weak var proxiable: OAuthSwiftURLHandlerType?
    public init(_ proxiable: OAuthSwiftURLHandlerType) {
        self.proxiable = proxiable
    }
    open func handle(_ url: URL) {
        proxiable?.handle(url)
    }
}

extension OAuthSwiftURLHandlerType {

    public func weak() -> OAuthSwiftURLHandlerType {
        return OAuthSwiftURLHandlerProxy(self)
    }
}
