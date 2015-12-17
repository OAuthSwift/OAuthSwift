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
        static var topViewController: UIViewController? {
            return UIApplication.sharedApplication().topViewController
        }

        var topViewController: UIViewController? {
            guard let rootController = self.keyWindow?.rootViewController else {
                return nil
            }
            return UIViewController.topViewController(rootController)
        }
    }

    extension UIViewController {

        static func topViewController(viewController: UIViewController) -> UIViewController {
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
