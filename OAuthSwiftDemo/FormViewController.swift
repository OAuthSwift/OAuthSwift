//
//  FormViewController.swift
//  OAuthSwift
//
//  Created by phimage on 23/07/16.
//  Copyright © 2016 Dongri Jin. All rights reserved.
//

#if os(iOS)
    import UIKit
    typealias FormViewControllerType = UITableViewController
    typealias Button = UISwitch
    typealias TextField = UITextField
    
#elseif os(OSX)
    import AppKit
    typealias FormViewControllerType = NSViewController
    typealias Button = NSButton
    typealias TextField = NSTextField
    
    extension NSTextField {
        var text: String? {
            get { return  self.stringValue }
            set { self.stringValue = newValue ?? "" }
        }
    }
    extension NSButton {
        var on: Bool {
            get { return  self.state == NSOnState }
            set { self.state = newValue ? NSOnState : NSOffState}
        }
        func setOn(value: Bool, animated: Bool) {
            on = value
        }
    }
#endif

enum URLHandlerType {
    case Internal
    case External
    case Safari
}


protocol FormViewControllerProvider {
    var key: String? {get}
    var secret: String? {get}
    
}
protocol FormViewControllerDelegate: FormViewControllerProvider {
    func didValidate(key: String?, secret: String?, handlerType: URLHandlerType)
    func didCancel()
}

class FormViewController: FormViewControllerType {
    
    var delegate: FormViewControllerDelegate?

    var safariURLHandlerAvailable: Bool {
        if #available(iOS 9.0, *) {
            return true
        }
        return false
    }
    
    override func viewDidLoad() {
        self.keyTextField.text = self.delegate?.key
        self.secretTextField.text = self.delegate?.secret
        
        #if os(iOS)
            safariURLHandlerView.hidden = !self.safariURLHandlerAvailable
        #endif
        self.urlHandlerType = .Internal
    }
    

    
    @IBOutlet weak var externalURLHandler: Button!
    @IBOutlet weak var internalURLHandler: Button!
    @IBOutlet var keyTextField: TextField!
    @IBOutlet var secretTextField: TextField!
    #if os(iOS)
    @IBOutlet weak var safariURLHandler: UISwitch!
    @IBOutlet weak var safariURLHandlerView: UITableViewCell!
    #endif

    @IBAction func ok(sender: AnyObject?) {
        self.dismiss(sender)

        let key = keyTextField.text
        let secret = secretTextField.text
        let handlerType = urlHandlerType
        delegate?.didValidate(key, secret: secret, handlerType: handlerType)
    }

    @IBAction func cancel(sender: AnyObject?) {
        self.dismiss(sender)
        delegate?.didCancel()
    }
    
    func dismiss(sender: AnyObject?) {
        #if os(iOS)
            // let parent
        #else
            self.dismissController(sender)
        #endif
    }
    
    @IBAction func urlHandlerChange(sender: Button) {
        if sender.on {
            if externalURLHandler == sender {
                urlHandlerType = .External
            }
            else if internalURLHandler == sender {
                urlHandlerType =  .Internal
            }
            #if os(iOS)
                if safariURLHandler == sender  {
                    urlHandlerType =  .Safari
                }
            #endif
        } else {
            // set another...
            if externalURLHandler == sender {
                urlHandlerType = .Internal
            }
            else if internalURLHandler == sender {
                urlHandlerType =  .External
            }
            #if os(iOS)
                if safariURLHandler == sender  {
                    urlHandlerType =  .Internal
                }
            #endif
        }
    }

    var urlHandlerType: URLHandlerType {
        get {
            if externalURLHandler.on {
                return .External
            }
            if internalURLHandler.on {
                return .Internal
            }
            #if os(iOS)
                if safariURLHandler.on {
                    return .Safari
                }
            #endif
            return .Internal
        }
        set {
            switch newValue {
            case .External:
                externalURLHandler.setOn(true, animated: false)
                internalURLHandler.setOn(false, animated: true)
                #if os(iOS)
                    safariURLHandler.setOn(false, animated: true)
                #endif
                break
            case .Internal:
                internalURLHandler.setOn(true, animated: false)
                externalURLHandler.setOn(false, animated: true)
                #if os(iOS)
                    safariURLHandler.setOn(false, animated: true)
                #endif
                break
            case .Safari:
                #if os(iOS)
                    safariURLHandler.setOn(true, animated: false)
                 #endif
                externalURLHandler.setOn(false, animated: true)
                internalURLHandler.setOn(false, animated: true)
                break
            }
        }
    }
    
}
