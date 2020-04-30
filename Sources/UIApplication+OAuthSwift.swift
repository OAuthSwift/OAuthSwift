//
//  UIApplication+OAuthSwift.swift
//  OAuthSwift
//
//  Created by phimage on 11/12/15.
//  Copyright © 2015 Dongri Jin. All rights reserved.
//

#if os(iOS) || os(tvOS)
    import UIKit

    extension UIApplication {
        @nonobjc static var topViewController: UIViewController? {
            #if !OAUTH_APP_EXTENSIONS
                return UIApplication.shared.topViewController
            #else
                return nil
            #endif
        }

        @available(iOS 13.0, tvOS 13.0, *)
        public var connectedWindowScenes: [UIWindowScene] {
            return self.connectedScenes.compactMap { $0 as? UIWindowScene }
        }

        @available(iOS 13.0, tvOS 13.0, *)
        public var topWindowScene: UIWindowScene? {
            let scenes = connectedWindowScenes
            return scenes.filter { $0.activationState == .foregroundActive }.first ?? scenes.first
        }

        public var topWindow: UIWindow? {
            if #available(iOS 13.0, tvOS 13.0, *) {
                return self.topWindowScene?.windows.first
            } else {
                return self.keyWindow
            }
        }

        var topViewController: UIViewController? {
            guard let rootController = self.topWindow?.rootViewController else {
                return nil
            }
            return UIViewController.topViewController(rootController)
        }
    }

    extension UIViewController {

        static func topViewController(_ viewController: UIViewController) -> UIViewController {
            guard let presentedViewController = viewController.presentedViewController else {
                return viewController
            }
            #if !topVCCastDisabled
            if let navigationController = presentedViewController as? UINavigationController {
                if let visibleViewController = navigationController.visibleViewController {
                    return topViewController(visibleViewController)
                }
            } else if let tabBarController = presentedViewController as? UITabBarController {
                if let selectedViewController = tabBarController.selectedViewController {
                    return topViewController(selectedViewController)
                }
            }
            #endif
            return topViewController(presentedViewController)
        }
    }

#endif
