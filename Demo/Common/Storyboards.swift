//
//  Storyboards.swift
//  OAuthSwift
//
//  Created by phimage on 23/07/16.
//  Copyright © 2016 Dongri Jin. All rights reserved.
//

import Foundation

#if os(iOS)
    import UIKit
    public typealias OAuthStoryboard = UIStoryboard
    public typealias OAuthStoryboardSegue = UIStoryboardSegue
    
    // add missing classes for iOS
    extension OAuthStoryboard {
        public struct Name {
            var rawValue: String
            init(_ rawValue: String) {
                self.rawValue = rawValue
            }
        }
        public struct SceneIdentifier {
            var rawValue: String
            init(_ rawValue: String) {
                self.rawValue = rawValue
            }
        }
        
        public convenience init(name: OAuthStoryboard.Name, bundle: Bundle? = nil) {
            self.init(name: name.rawValue, bundle: bundle)
        }

        public func instantiateController(withIdentifier id: OAuthStoryboard.SceneIdentifier) -> UIViewController {
            return self.instantiateViewController(withIdentifier: id.rawValue)
        }
        
    }
    
    extension UIViewController {
        func performSegue(withIdentifier: OAuthStoryboardSegue.Identifier, sender: Any?) {
            self.performSegue(withIdentifier: withIdentifier.rawValue, sender: sender)
        }
    }
    
    extension OAuthStoryboardSegue {
        struct Identifier {
            var rawValue: String
            init(_ rawValue: String) {
                self.rawValue = rawValue
            }
        }
    }
    
    extension OAuthStoryboardSegue.Identifier :Equatable {
        static func ==(l: OAuthStoryboardSegue.Identifier, r: OAuthStoryboardSegue.Identifier) -> Bool {
            return l.rawValue == r.rawValue
        }
        static func == (l: String, r: OAuthStoryboardSegue.Identifier) -> Bool {
            return l == r.rawValue
        }
        static func == (l: String?, r: OAuthStoryboardSegue.Identifier) -> Bool {
            guard let l = l else {
                return false
            }
            return l == r.rawValue
        }
    }
    
#elseif os(OSX)
    import AppKit
    public typealias OAuthStoryboard = NSStoryboard
    public typealias OAuthStoryboardSegue = NSStoryboardSegue
#endif


struct Storyboards {
    struct Main {
        
        static let identifier = OAuthStoryboard.Name("Storyboard")
        static let formIdentifier = OAuthStoryboard.SceneIdentifier("Form")
        static let formSegue = OAuthStoryboardSegue.Identifier("form")
        
        static var storyboard: OAuthStoryboard {
            return OAuthStoryboard(name: self.identifier, bundle: nil)
        }
        
        static func instantiateForm() -> FormViewController {
            return self.storyboard.instantiateController(withIdentifier: formIdentifier) as! FormViewController
        }


    }
}
