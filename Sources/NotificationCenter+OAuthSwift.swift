//
//  NotificationCenter+OAuthSwift.swift
//  OAuthSwift
//
//  Created by hiragram on 2017/04/04.
//  Copyright © 2017年 Dongri Jin. All rights reserved.
//

import Foundation

@available(iOSApplicationExtension, unavailable)
public extension Notification.Name {
    @available(*, deprecated, renamed: "OAuthSwift.didHandleCallbackURL")
    static let OAuthSwiftHandleCallbackURL: Notification.Name = OAuthSwift.didHandleCallbackURL
}
@available(iOSApplicationExtension, unavailable)
public extension OAuthSwift {
    static let didHandleCallbackURL: Notification.Name = .init("OAuthSwiftCallbackNotificationName")
}
