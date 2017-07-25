//
//  OAuthWebViewController.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 2/11/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import Foundation

#if os(iOS)  || os(tvOS)
    import UIKit
    public typealias OAuthViewController = UIViewController
#elseif os(watchOS)
    import WatchKit
    public typealias OAuthViewController = WKInterfaceController
#elseif os(OSX)
    import AppKit
    public typealias OAuthViewController = NSViewController
#endif

/// Delegate for OAuthWebViewController
public protocol OAuthWebViewControllerDelegate: class {

    #if os(iOS) || os(tvOS)
    /// Did web view presented (work only without navigation controller)
    func oauthWebViewControllerDidPresent()
    /// Did web view dismiss (work only without navigation controller)
    func oauthWebViewControllerDidDismiss()
    #endif

    func oauthWebViewControllerWillAppear()
    func oauthWebViewControllerDidAppear()
    func oauthWebViewControllerWillDisappear()
    func oauthWebViewControllerDidDisappear()
}

/// A web view controller, which handler OAuthSwift authentification.
open class OAuthWebViewController: OAuthViewController, OAuthSwiftURLHandlerType {

    #if os(iOS) || os(tvOS) || os(OSX)
    /// Delegate for this view
    public weak var delegate: OAuthWebViewControllerDelegate?
    #endif

    #if os(iOS) || os(tvOS)
    /// If controller have an navigation controller, application top view controller could be used if true
    public var useTopViewControlerInsteadOfNavigation = false

    /// If you want you could set animation transition to NO
    public var presentViewControllerAnimated = true

    public var topViewController: UIViewController? {
        #if !OAUTH_APP_EXTENSIONS
            return UIApplication.topViewController
        #else
            return nil
        #endif
    }
    #elseif os(OSX)
    /// How to present this view controller if parent view controller set
    public enum Present {
        case asModalWindow
        case asSheet
        case asPopover(relativeToRect: NSRect, ofView : NSView, preferredEdge: NSRectEdge, behavior: NSPopoverBehavior)
        case transitionFrom(fromViewController: NSViewController, options: NSViewControllerTransitionOptions)
        case animator(animator: NSViewControllerPresentationAnimator)
        case segue(segueIdentifier: String)
    }
    public var present: Present = .asModalWindow
    #endif

    open func handle(_ url: URL) {
        // do UI in main thread
        OAuthSwift.main { [unowned self] in
             self.doHandle(url)
        }
    }

    #if os(watchOS)
    public static var userActivityType: String = "org.github.dongri.oauthswift.connect"
    #endif

    open func doHandle(_ url: URL) {
        #if os(iOS) || os(tvOS)
            let completion: () -> Void = { [unowned self] in
                self.delegate?.oauthWebViewControllerDidPresent()
            }
            if let navigationController = self.navigationController, (!useTopViewControlerInsteadOfNavigation || self.topViewController == nil) {
                navigationController.pushViewController(self, animated: presentViewControllerAnimated)
            } else if let p = self.parent {
                p.present(self, animated: presentViewControllerAnimated, completion: completion)
            } else if let topViewController = topViewController {
                topViewController.present(self, animated: presentViewControllerAnimated, completion: completion)
            } else {
                // assert no presentation
                assertionFailure("Failed to present. Maybe add a parent")
            }
        #elseif os(watchOS)
            if url.scheme == "http" || url.scheme == "https" {
                self.updateUserActivity(OAuthWebViewController.userActivityType, userInfo: nil, webpageURL: url)
            }
        #elseif os(OSX)
            if let p = self.parent { // default behaviour if this controller affected as child controller
                switch self.present {
                case .asSheet:
                    p.presentViewControllerAsSheet(self)
                    break
                case .asModalWindow:
                    p.presentViewControllerAsModalWindow(self)
                    // FIXME: if we present as window, window close must detected and oauthswift.cancel() must be called...
                    break
                case .asPopover(let positioningRect, let positioningView, let preferredEdge, let behavior):
                    p.presentViewController(self, asPopoverRelativeTo: positioningRect, of : positioningView, preferredEdge: preferredEdge, behavior: behavior)
                    break
                case .transitionFrom(let fromViewController, let options):
                    let completion: () -> Void = { /*[unowned self] in*/
                        //self.delegate?.oauthWebViewControllerDidPresent()
                    }
                    p.transition(from: fromViewController, to: self, options: options, completionHandler: completion)
                    break
                case .animator(let animator):
                    p.presentViewController(self, animator: animator)
                case .segue(let segueIdentifier):
                    p.performSegue(withIdentifier: segueIdentifier, sender: self) // The segue must display self.view
                    break
                }
            } else if let window = self.view.window {
                window.makeKeyAndOrderFront(nil)
            } else {
                assertionFailure("Failed to present. Add controller into a window or add a parent")
            }
            // or create an NSWindow or NSWindowController (/!\ keep a strong reference on it)
        #endif
    }

    open func dismissWebViewController() {
        #if os(iOS) || os(tvOS)
            let completion: () -> Void = { [unowned self] in
                self.delegate?.oauthWebViewControllerDidDismiss()
            }
            let animated = true
            if let navigationController = self.navigationController, (!useTopViewControlerInsteadOfNavigation || self.topViewController == nil) {
                navigationController.popViewController(animated: animated)
            } else if let parentViewController = self.parent {
                // The presenting view controller is responsible for dismissing the view controller it presented
                parentViewController.dismiss(animated: animated, completion: completion)
            } else if let topViewController = topViewController {
                topViewController.dismiss(animated: animated, completion: completion)
            } else {
                // keep old code...
                self.dismiss(animated: animated, completion: completion)
            }
        #elseif os(watchOS)
            self.dismiss()
        #elseif os(OSX)
            if self.presenting != nil {
                self.dismiss(nil)
                if self.parent != nil {
                    self.removeFromParentViewController()
                }
            } else if let window = self.view.window {
                window.performClose(nil)
            }
        #endif
    }

    // MARK: overrides
    #if os(iOS) || os(tvOS)
    open override func viewWillAppear(_ animated: Bool) {
        self.delegate?.oauthWebViewControllerWillAppear()
    }
    open override func viewDidAppear(_ animated: Bool) {
        self.delegate?.oauthWebViewControllerDidAppear()
    }
    open override func viewWillDisappear(_ animated: Bool) {
        self.delegate?.oauthWebViewControllerWillDisappear()
    }
    open override func viewDidDisappear(_ animated: Bool) {
        self.delegate?.oauthWebViewControllerDidDisappear()
    }
    #elseif os(OSX)
    open override func viewWillAppear() {
        self.delegate?.oauthWebViewControllerWillAppear()
    }
    open override func viewDidAppear() {
        self.delegate?.oauthWebViewControllerDidAppear()
    }
    open override func viewWillDisappear() {
        self.delegate?.oauthWebViewControllerWillDisappear()
    }
    open override func viewDidDisappear() {
        self.delegate?.oauthWebViewControllerDidDisappear()
    }

    #endif
}
