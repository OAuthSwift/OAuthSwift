//
//  ViewController.swift
//  OAuthSwiftOSXDemo
//
//  Created by phimage on 07/05/15.
//  Copyright (c) 2015 Dongri Jin. All rights reserved.
//

import Cocoa
import OAuthSwiftOSX

class ViewController: NSViewController , NSTableViewDelegate, NSTableViewDataSource {

    var services = ["Twitter", "Flickr", "Github", "Instagram", "Foursquare", "Fitbit", "Withings", "Linkedin", "Linkedin2", "Dropbox", "Dribbble", "Salesforce", "BitBucket", "GoogleDrive", "Smugmug", "Intuit", "Zaim"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func createWebViewController() -> WebViewController {
        let controller = WebViewController()
        controller.view = NSView(frame: NSRect(x:0, y:0, width: 450, height: 500)) // needed if no nib or not loaded from storyboard
        controller.viewDidLoad()
        return controller
    }

    func get_url_handler() -> OAuthSwiftURLHandlerType {
        // Create a WebViewController with default behaviour from OAuthWebViewController
        let url_handler = createWebViewController()
        self.addChildViewController(url_handler) // allow WebViewController to use this ViewController as parent to be presented
        return url_handler
        
        // a better way is 
        // - to make this ViewController implement OAuthSwiftURLHandlerType and assigned in oauthswift object
        /* return self */
        // - have an instance of WebViewController here (I) or a segue name to launch (S)
        // - in handle(url) 
        //    (I) : affect url to WebViewController, and  self.presentViewControllerAsModalWindow(self.webViewController)
        //    (S) : affect url to a temp variable (ex: urlForWebView), then perform segue
        /* performSegueWithIdentifier("oauthwebview", sender:nil) */
        //         then override prepareForSegue() to affect url to destination controller WebViewController
        
    }
    //(I)
    //let webViewController: WebViewController = createWebViewController()
    //(S)
    //var urlForWebView:?NSURL = nil
    
    func doOAuthTwitter(){
        let oauthswift = OAuth1Swift(
            consumerKey:    Twitter["consumerKey"]!,
            consumerSecret: Twitter["consumerSecret"]!,
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl:    "https://api.twitter.com/oauth/authorize",
            accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
        )
        
        //oauthswift.authorize_url_handler = createWebViewController()
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/twitter")!, success: {
            credential, response in
            self.showAlertView("Twitter", message: "auth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            var parameters =  Dictionary<String, AnyObject>()
            oauthswift.client.get("https://api.twitter.com/1.1/statuses/mentions_timeline.json", parameters: parameters,
                success: {
                    data, response in
                    let jsonDict: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil)
                    println(jsonDict)
                }, failure: {(error:NSError!) -> Void in
                    println(error)
            })
            
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
            }
        )
    }
    
    func doOAuthFlickr(){
        let oauthswift = OAuth1Swift(
            consumerKey:    Flickr["consumerKey"]!,
            consumerSecret: Flickr["consumerSecret"]!,
            requestTokenUrl: "https://www.flickr.com/services/oauth/request_token",
            authorizeUrl:    "https://www.flickr.com/services/oauth/authorize",
            accessTokenUrl:  "https://www.flickr.com/services/oauth/access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/flickr")!, success: {
            credential, response in
            self.showAlertView("Flickr", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            let url :String = "https://api.flickr.com/services/rest/"
            let parameters :Dictionary = [
                "method"         : "flickr.photos.search",
                "api_key"        : Flickr["consumerKey"]!,
                "user_id"        : "128483205@N08",
                "format"         : "json",
                "nojsoncallback" : "1",
                "extras"         : "url_q,url_z"
            ]
            oauthswift.client.get(url, parameters: parameters,
                success: {
                    data, response in
                    let jsonDict: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil)
                    println(jsonDict)
                }, failure: {(error:NSError!) -> Void in
                    println(error)
            })
            
            
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
        })
        
    }
    
    func doOAuthGithub(){
        let oauthswift = OAuth2Swift(
            consumerKey:    Github["consumerKey"]!,
            consumerSecret: Github["consumerSecret"]!,
            authorizeUrl:   "https://github.com/login/oauth/authorize",
            accessTokenUrl: "https://github.com/login/oauth/access_token",
            responseType:   "code"
        )
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/github")!, scope: "user,repo", state: state, success: {
            credential, response in
            self.showAlertView("Github", message: "oauth_token:\(credential.oauth_token)")
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
        })
        
    }
    
    func doOAuthSalesforce(){
        let oauthswift = OAuth2Swift(
            consumerKey:    Salesforce["consumerKey"]!,
            consumerSecret: Salesforce["consumerSecret"]!,
            authorizeUrl:   "https://login.salesforce.com/services/oauth2/authorize",
            accessTokenUrl: "https://login.salesforce.com/services/oauth2/token",
            responseType:   "code"
        )
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/salesforce")!, scope: "full", state: state, success: {
            credential, response in
            self.showAlertView("Salesforce", message: "oauth_token:\(credential.oauth_token)")
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
        })
        
    }

    
    func doOAuthInstagram(){
        let oauthswift = OAuth2Swift(
            consumerKey:    Instagram["consumerKey"]!,
            consumerSecret: Instagram["consumerSecret"]!,
            authorizeUrl:   "https://api.instagram.com/oauth/authorize",
            responseType:   "token"
        )
        
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorize_url_handler = get_url_handler()
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/instagram")!, scope: "likes+comments", state:state, success: {
            credential, response in
            self.showAlertView("Instagram", message: "oauth_token:\(credential.oauth_token)")
            let url :String = "https://api.instagram.com/v1/users/1574083/?access_token=\(credential.oauth_token)"
            let parameters :Dictionary = Dictionary<String, AnyObject>()
            oauthswift.client.get(url, parameters: parameters,
                success: {
                    data, response in
                    let jsonDict: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil)
                    println(jsonDict)
                }, failure: {(error:NSError!) -> Void in
                    println(error)
            })
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
        })
    }
    
    func doOAuthFoursquare(){
        let oauthswift = OAuth2Swift(
            consumerKey:    Foursquare["consumerKey"]!,
            consumerSecret: Foursquare["consumerSecret"]!,
            authorizeUrl:   "https://foursquare.com/oauth2/authorize",
            responseType:   "token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/foursquare")!, scope: "", state: "", success: {
            credential, response in
            self.showAlertView("Foursquare", message: "oauth_token:\(credential.oauth_token)")
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
        })
    }
    
    func doOAuthFitbit(){
        let oauthswift = OAuth1Swift(
            consumerKey:    Fitbit["consumerKey"]!,
            consumerSecret: Fitbit["consumerSecret"]!,
            requestTokenUrl: "https://api.fitbit.com/oauth/request_token",
            authorizeUrl:    "https://www.fitbit.com/oauth/authorize?display=touch",
            accessTokenUrl:  "https://api.fitbit.com/oauth/access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/fitbit")!, success: {
            credential, response in
            self.showAlertView("Fitbit", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
        })
    }
    
    func doOAuthWithings(){
        let oauthswift = OAuth1Swift(
            consumerKey:    Withings["consumerKey"]!,
            consumerSecret: Withings["consumerSecret"]!,
            requestTokenUrl: "https://oauth.withings.com/account/request_token",
            authorizeUrl:    "https://oauth.withings.com/account/authorize",
            accessTokenUrl:  "https://oauth.withings.com/account/access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/withings")!, success: {
            credential, response in
            self.showAlertView("Withings", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
        })
    }
    
    func doOAuthLinkedin(){
        let oauthswift = OAuth1Swift(
            consumerKey:    Linkedin["consumerKey"]!,
            consumerSecret: Linkedin["consumerSecret"]!,
            requestTokenUrl: "https://api.linkedin.com/uas/oauth/requestToken",
            authorizeUrl:    "https://api.linkedin.com/uas/oauth/authenticate",
            accessTokenUrl:  "https://api.linkedin.com/uas/oauth/accessToken"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/linkedin")!, success: {
            credential, response in
            self.showAlertView("Linkedin", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            var parameters =  Dictionary<String, AnyObject>()
            oauthswift.client.get("https://api.linkedin.com/v1/people/~", parameters: parameters,
                success: {
                    data, response in
                    let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                    println(dataString)
                }, failure: {(error:NSError!) -> Void in
                    println(error)
            })
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
        })
    }
    
    func doOAuthLinkedin2(){
        let oauthswift = OAuth2Swift(
            consumerKey:    Linkedin2["consumerKey"]!,
            consumerSecret: Linkedin2["consumerSecret"]!,
            authorizeUrl:   "https://www.linkedin.com/uas/oauth2/authorization",
            accessTokenUrl: "https://www.linkedin.com/uas/oauth2/accessToken",
            responseType:   "code"
        )
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "http://oauthswift.herokuapp.com/callback/linkedin2")!, scope: "r_fullprofile", state: state, success: {
            credential, response in
            self.showAlertView("Linkedin2", message: "oauth_token:\(credential.oauth_token)")
            var parameters =  Dictionary<String, AnyObject>()
            oauthswift.client.get("https://api.linkedin.com/v1/people/~?format=json", parameters: parameters,
                success: {
                    data, response in
                    let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                    println(dataString)
                }, failure: {(error:NSError!) -> Void in
                    println(error)
            })
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
        })
    }
    
    func doOAuthSmugmug(){
        let oauthswift = OAuth1Swift(
            consumerKey:    Smugmug["consumerKey"]!,
            consumerSecret: Smugmug["consumerSecret"]!,
            requestTokenUrl: "http://api.smugmug.com/services/oauth/getRequestToken.mg",
            authorizeUrl:    "http://api.smugmug.com/services/oauth/authorize.mg",
            accessTokenUrl:  "http://api.smugmug.com/services/oauth/getAccessToken.mg"
        )
        oauthswift.allowMissingOauthVerifier = true
        // NOTE: Smugmug's callback URL is configured on their site and the one passed in is ignored.
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/smugmug")!, success: {
            credential, response in
            self.showAlertView("Smugmug", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
        })
    }
    
    func doOAuthDropbox(){
        let oauthswift = OAuth2Swift(
            consumerKey:    Dropbox["consumerKey"]!,
            consumerSecret: Dropbox["consumerSecret"]!,
            authorizeUrl:   "https://www.dropbox.com/1/oauth2/authorize",
            accessTokenUrl: "https://api.dropbox.com/1/oauth2/token",
            responseType:   "token"
        )
        
        oauthswift.authorize_url_handler = get_url_handler()
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/dropbox")!, scope: "", state: "", success: {
            credential, response in
            self.showAlertView("Dropbox", message: "oauth_token:\(credential.oauth_token)")
            // Get Dropbox Account Info
            var parameters =  Dictionary<String, AnyObject>()
            oauthswift.client.get("https://api.dropbox.com/1/account/info?access_token=\(credential.oauth_token)", parameters: parameters,
                success: {
                    data, response in
                    let jsonDict: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil)
                    println(jsonDict)
                }, failure: {(error:NSError!) -> Void in
                    println(error)
            })
            
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
        })
    }
    
    func doOAuthDribbble(){
        let oauthswift = OAuth2Swift(
            consumerKey:    Dribbble["consumerKey"]!,
            consumerSecret: Dribbble["consumerSecret"]!,
            authorizeUrl:   "https://dribbble.com/oauth/authorize",
            accessTokenUrl: "https://dribbble.com/oauth/token",
            responseType:   "code"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/dribbble")!, scope: "", state: "", success: {
            credential, response in
            self.showAlertView("Dribbble", message: "oauth_token:\(credential.oauth_token)")
            // Get User
            var parameters =  Dictionary<String, AnyObject>()
            oauthswift.client.get("https://api.dribbble.com/v1/user?access_token=\(credential.oauth_token)", parameters: parameters,
                success: {
                    data, response in
                    let jsonDict: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil)
                    println(jsonDict)
                }, failure: {(error:NSError!) -> Void in
                    println(error)
            })
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
        })
    }
    
    func doOAuthBitBucket(){
        let oauthswift = OAuth1Swift(
            consumerKey:    BitBucket["consumerKey"]!,
            consumerSecret: BitBucket["consumerSecret"]!,
            requestTokenUrl: "https://bitbucket.org/api/1.0/oauth/request_token",
            authorizeUrl:    "https://bitbucket.org/api/1.0/oauth/authenticate",
            accessTokenUrl:  "https://bitbucket.org/api/1.0/oauth/access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/bitbucket")!, success: {
            credential, response in
            self.showAlertView("BitBucket", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            var parameters =  Dictionary<String, AnyObject>()
            oauthswift.client.get("https://bitbucket.org/api/1.0/user", parameters: parameters,
                success: {
                    data, response in
                    let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                    println(dataString)
                }, failure: {(error:NSError!) -> Void in
                    println(error)
            })
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
        })
    }
    
    func doOAuthGoogle(){
        let oauthswift = OAuth2Swift(
            consumerKey:    GoogleDrive["consumerKey"]!,
            consumerSecret: GoogleDrive["consumerSecret"]!,
            authorizeUrl:   "https://accounts.google.com/o/oauth2/auth",
            accessTokenUrl: "https://accounts.google.com/o/oauth2/token",
            responseType:   "code"
        )
        // For googgle the redirect_uri should match your this syntax: your.bundle.id:/oauth2Callback
        // in plist define a url schem with: your.bundle.id:
        oauthswift.authorizeWithCallbackURL( NSURL(string: "https://oauthswift.herokuapp.com/callback/google")!, scope: "https://www.googleapis.com/auth/drive", state: "", success: {
            credential, response in
            self.showAlertView("Github", message: "oauth_token:\(credential.oauth_token)")
            var parameters =  Dictionary<String, AnyObject>()
            // Multi-part upload
            oauthswift.client.postImage("https://www.googleapis.com/upload/drive/v2/files", parameters: parameters, image: self.snapshot(),
                success: {
                    data, response in
                    let jsonDict: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil)
                    println("SUCCESS: \(jsonDict)")
                }, failure: {(error:NSError!) -> Void in
                    println(error)
            })
            
            }, failure: {(error:NSError!) -> Void in
                println("ERROR: \(error.localizedDescription)")
        })
    }
    
    func doOAuthIntuit(){
        let oauthswift = OAuth1Swift(
            consumerKey:    Intuit["consumerKey"]!,
            consumerSecret: Intuit["consumerSecret"]!,
            requestTokenUrl: "https://oauth.intuit.com/oauth/v1/get_request_token",
            authorizeUrl:    "https://appcenter.intuit.com/Connect/Begin",
            accessTokenUrl:  "https://oauth.intuit.com/oauth/v1/get_access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/intuit")!, success: {
            credential, response in
            self.showAlertView("Intuit", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
        })
    }
    
    func doOAuthZaim(){
        let oauthswift = OAuth1Swift(
            consumerKey:    Zaim["consumerKey"]!,
            consumerSecret: Zaim["consumerSecret"]!,
            requestTokenUrl: "https://api.zaim.net/v2/auth/request",
            authorizeUrl:    "https://auth.zaim.net/users/auth",
            accessTokenUrl:  "https://api.zaim.net/v2/auth/access"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/zaim")!, success: {
            credential, response in
            self.showAlertView("Zaim", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
        })
    }

    func snapshot() -> NSData {
        var rep: NSBitmapImageRep = self.view.bitmapImageRepForCachingDisplayInRect(self.view.bounds)!
        self.view.cacheDisplayInRect(self.view.bounds, toBitmapImageRep:rep)
        return rep.TIFFRepresentation!
    }
    
    func showAlertView(title: String, message: String) {
        var alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButtonWithTitle("Close")
        alert.runModal()
    }

    // MARK: NSTableViewDataSource
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.services.count
    }
    
    // MARK: NSTableViewDelegate
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return self.services[row]
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        if let tableView = notification.object as? NSTableView {
            let row = tableView.selectedRow
            if  row != -1 {
                
                let service: String = self.services[row]
                
                switch service {
                case "Twitter":
                    doOAuthTwitter()
                case "Flickr":
                    doOAuthFlickr()
                case "Github":
                    doOAuthGithub()
                case "Instagram":
                    doOAuthInstagram()
                case "Foursquare":
                    doOAuthFoursquare()
                case "Fitbit":
                    doOAuthFitbit()
                case "Withings":
                    doOAuthWithings()
                case "Linkedin":
                    doOAuthLinkedin()
                case "Linkedin2":
                    doOAuthLinkedin2()
                case "Dropbox":
                    doOAuthDropbox()
                case "Dribbble":
                    doOAuthDribbble()
                case "Salesforce":
                    doOAuthSalesforce()
                case "BitBucket":
                    doOAuthBitBucket()
                case "GoogleDrive":
                    doOAuthGoogle()
                case "Smugmug":
                    doOAuthSmugmug()
                case "Intuit":
                    doOAuthIntuit()
                case "Zaim":
                    doOAuthZaim()
                default:
                    println("default (check ViewController tableView)")
                }
                
                tableView.deselectRow(row)
            }
        }
    }

}


