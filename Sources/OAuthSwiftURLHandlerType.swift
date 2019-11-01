//
//  OAuthSwiftURLHandlerType.swift
//  OAuthSwift
//
//  Created by phimage on 11/05/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(OSX)
import AppKit
#endif

/// Protocol to defined how to open the url.
/// You could choose to open using an external browser, a safari controller, an internal webkit view controller, etc...
@objc public protocol OAuthSwiftURLHandlerType {
    func handle(_ url: URL)
}

public struct OAuthSwiftURLHandlerTypeFactory {

    static var `default`: OAuthSwiftURLHandlerType = OAuthSwiftOpenURLExternally.sharedInstance
}
