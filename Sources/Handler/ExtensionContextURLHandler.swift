//
//  ExtensionContextURLHandler.swift
//  OAuthSwift
//
//  Created by phimage on 01/11/2019.
//  Copyright © 2019 Dongri Jin, Marchand Eric. All rights reserved.
//

import Foundation

/// Open url using `NSExtensionContext``
open class ExtensionContextURLHandler: OAuthSwiftURLHandlerType {

    fileprivate var extensionContext: NSExtensionContext

    public init(extensionContext: NSExtensionContext) {
        self.extensionContext = extensionContext
    }

    @objc open func handle(_ url: URL) {
        extensionContext.open(url, completionHandler: nil)
    }
}
