//
//  SafariURLHandler.swift
//  OAuthSwift
//
//  Created by phimage on 01/11/2019.
//  Copyright © 2019 Dongri Jin, Marchand Eric. All rights reserved.
//

import Foundation

// MARK: Open SFSafariViewController
#if os(iOS)
import SafariServices
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

@available(iOS 9.0, *)
open class SafariURLHandler: NSObject, OAuthSwiftURLHandlerType, SFSafariViewControllerDelegate {

    public typealias UITransion = (_ controller: SFSafariViewController, _ handler: SafariURLHandler) -> Void

    weak open var oauthSwift: OAuthSwift?
    open var present: UITransion
    open var dismiss: UITransion
    /// retains observers
    var observers = [String: NSObjectProtocol]()

    open var factory: (_ URL: URL) -> SFSafariViewController = {URL in
        return SFSafariViewController(url: URL)
    }

    /// delegates
    open weak var delegate: SFSafariViewControllerDelegate?

    // configure default presentation and dismissal code

    open var animated: Bool = true
    open var presentCompletion: (() -> Void)?
    open var dismissCompletion: (() -> Void)?
    open var delay: UInt32? = 1

    /// init
    public init(viewController: UIViewController, oauthSwift: OAuthSwift) {
        self.oauthSwift = oauthSwift
        self.present = { [weak viewController] controller, handler in
            viewController?.present(controller, animated: handler.animated, completion: handler.presentCompletion)
        }
        self.dismiss = { [weak viewController] _, handler in
            viewController?.dismiss(animated: handler.animated, completion: handler.dismissCompletion)
        }
    }

    public init(present: @escaping UITransion, dismiss: @escaping UITransion, oauthSwift: OAuthSwift) {
        self.oauthSwift = oauthSwift
        self.present = present
        self.dismiss = dismiss
    }

    @objc open func handle(_ url: URL) {
        let controller = factory(url)
        controller.delegate = self
        OAuthSwift.log?.trace("SFSafariViewController: present Safari view controller")

        // present controller in main thread
        OAuthSwift.main { [weak self] in
            guard let this = self else {
                return
            }
            if let delay = this.delay { // sometimes safari show a blank view..
                sleep(delay)
            }
            this.present(controller, this)
        }

        let key = UUID().uuidString

        observers[key] = OAuthSwift.notificationCenter.addObserver(
            forName: OAuthSwift.didHandleCallbackURL,
            object: nil,
            queue: OperationQueue.main,
            using: { [weak self] _ in
                guard let this = self else {
                    return
                }
                if let observer = this.observers[key] {
                    OAuthSwift.notificationCenter.removeObserver(observer)
                    this.observers.removeValue(forKey: key)
                }
                OAuthSwift.main {
                    OAuthSwift.log?.trace("SFSafariViewController: dismiss view controller")
                    this.dismiss(controller, this)
                }
            }
        )
    }

    /// Clear internal observers on authentification flow
    open func clearObservers() {
        OAuthSwift.log?.trace("SFSafariViewController: clear observers")
        clearLocalObservers()
        self.oauthSwift?.removeCallbackNotificationObserver()
    }

    open func clearLocalObservers() {
        for (_, observer) in observers {
            OAuthSwift.notificationCenter.removeObserver(observer)
        }
        observers.removeAll()
    }

    /// SFSafariViewControllerDelegate
    public func safariViewController(_ controller: SFSafariViewController, activityItemsFor URL: Foundation.URL, title: String?) -> [UIActivity] {
        return self.delegate?.safariViewController?(controller, activityItemsFor: URL, title: title) ?? []
    }

    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        // "Done" pressed
        self.clearObservers()
        self.delegate?.safariViewControllerDidFinish?(controller)
    }

    public func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        self.delegate?.safariViewController?(controller, didCompleteInitialLoad: didLoadSuccessfully)
    }

}
#endif
