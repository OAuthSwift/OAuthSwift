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
        var isOn: Bool {
            get { return  self.state == .on }
            set { self.state = newValue ? .on : .off}
        }
        func setOn(_ value: Bool, animated: Bool) {
            isOn = value
        }
    }
#endif

enum URLHandlerType {
    case `internal`
    case external
    case safari
    case asWeb
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
            safariURLHandlerView.isHidden = !self.safariURLHandlerAvailable
        #endif
        self.urlHandlerType = .`internal`
    }
    

    
    @IBOutlet weak var externalURLHandler: Button!
    @IBOutlet weak var internalURLHandler: Button!
    @IBOutlet var keyTextField: TextField!
    @IBOutlet var secretTextField: TextField!
    #if os(iOS)
    @IBOutlet weak var safariURLHandler: UISwitch!
    @IBOutlet weak var safariURLHandlerView: UITableViewCell!
    @IBOutlet weak var asWebURLHandler: UISwitch!
    #endif

    @IBAction func ok(_ sender: AnyObject?) {
        self.dismiss(sender: sender)

        let key = keyTextField.text
        let secret = secretTextField.text
        let handlerType = urlHandlerType
        delegate?.didValidate(key: key, secret: secret, handlerType: handlerType)
    }

    @IBAction func cancel(_ sender: AnyObject?) {
        self.dismiss(sender: sender)
        delegate?.didCancel()
    }
    
    func dismiss(sender: AnyObject?) {
        #if os(iOS)
            // let parent
        #else
            self.dismiss(sender)
        #endif
    }
    
    @IBAction func urlHandlerChange(_ sender: Button) {
        if sender.isOn {
            if externalURLHandler == sender {
                urlHandlerType = .external
            }
            else if internalURLHandler == sender {
                urlHandlerType = .`internal`
            }
            #if os(iOS)
            if safariURLHandler == sender  {
                urlHandlerType = .safari
            }
            if asWebURLHandler == sender  {
                urlHandlerType = .asWeb
            }
            #endif
        } else {
            // set another...
            if externalURLHandler == sender {
                urlHandlerType = .`internal`
            }
            else if internalURLHandler == sender {
                urlHandlerType = .external
            }
            #if os(iOS)
            if safariURLHandler == sender  {
                urlHandlerType = .`internal`
            }
            if asWebURLHandler == sender  {
                urlHandlerType = .`internal`
            }
            #endif
        }
    }

    var urlHandlerType: URLHandlerType {
        get {
            if externalURLHandler.isOn {
                return .external
            }
            if internalURLHandler.isOn {
                return .`internal`
            }
            #if os(iOS)
            if safariURLHandler.isOn {
                return .safari
            }
            if asWebURLHandler.isOn {
                return .asWeb
            }
            #endif
            return .`internal`
        }
        set {
            switch newValue {
            case .external:
                externalURLHandler.setOn(true, animated: true)
                internalURLHandler.setOn(false, animated: true)
                #if os(iOS)
                safariURLHandler.setOn(false, animated: true)
                asWebURLHandler.setOn(false, animated: true)
                #endif
                break
            case .`internal`:
                internalURLHandler.setOn(true, animated: true)
                externalURLHandler.setOn(false, animated: true)
                #if os(iOS)
                safariURLHandler.setOn(false, animated: true)
                asWebURLHandler.setOn(false, animated: true)
                #endif
                break
            case .safari:
                #if os(iOS)
                safariURLHandler.setOn(true, animated: true)
                asWebURLHandler.setOn(false, animated: true)
                #endif
                externalURLHandler.setOn(false, animated: true)
                internalURLHandler.setOn(false, animated: true)
                break
            case .asWeb:
                #if os(iOS)
                safariURLHandler.setOn(false, animated: true)
                asWebURLHandler.setOn(true, animated: true)
                #endif
                externalURLHandler.setOn(false, animated: true)
                internalURLHandler.setOn(false, animated: true)
                break
            }
        }
    }
    
}
