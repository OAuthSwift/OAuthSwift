//
//  ViewController.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import OAuthSwift

#if os(iOS)
    import UIKit
    class ViewController: UIViewController {}
#elseif os(OSX)
    import AppKit
    class ViewController: NSViewController {}
#endif


// MARK: - do authentification
extension ViewController {
    
    func doAuthService(service: String) {

        guard let parameters = services[service] else {
            showAlertView("Miss configuration", message: "\(service) not configured")
            return
        }
        
        if Services.parametersEmpty(parameters) { // no value to set
            let message = "\(service) seems to have not weel configured. \nPlease fill consumer key and secret into configuration file \(self.confPath)"
            print(message)
            showAlertView("Miss configuration", message: message)
            // TODO here ask for parameters instead
        }

        switch service {
        case "Twitter":
            doOAuthTwitter(parameters)
        case "Flickr":
            doOAuthFlickr(parameters)
        case "Github":
            doOAuthGithub(parameters)
        case "Instagram":
            doOAuthInstagram(parameters)
        case "Foursquare":
            doOAuthFoursquare(parameters)
        case "Fitbit":
            doOAuthFitbit(parameters)
        case "Withings":
            doOAuthWithings(parameters)
        case "Linkedin":
            doOAuthLinkedin(parameters)
        case "Linkedin2":
            doOAuthLinkedin2(parameters)
        case "Dropbox":
            doOAuthDropbox(parameters)
        case "Dribbble":
            doOAuthDribbble(parameters)
        case "Salesforce":
            doOAuthSalesforce(parameters)
        case "BitBucket":
            doOAuthBitBucket(parameters)
        case "GoogleDrive":
            doOAuthGoogle(parameters)
        case "Smugmug":
            doOAuthSmugmug(parameters)
        case "Intuit":
            doOAuthIntuit(parameters)
        case "Zaim":
            doOAuthZaim(parameters)
        case "Tumblr":
            doOAuthTumblr(parameters)
        case "Slack":
            doOAuthSlack(parameters)
        case "Uber":
            doOAuthUber(parameters)
        default:
            print("\(service) not implemented")
        }
    }

    func doOAuthTwitter(parameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl:    "https://api.twitter.com/oauth/authorize",
            accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
        )
        //oauthswift.authorize_url_handler = get_url_handler()
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/twitter")!, success: {
            credential, response in
            self.showAlertView("Twitter", message: "auth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            let parameters =  Dictionary<String, AnyObject>()
            oauthswift.client.get("https://api.twitter.com/1.1/statuses/mentions_timeline.json", parameters: parameters,
                success: {
                    data, response in
                    let jsonDict: AnyObject! = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                    print(jsonDict)
                }, failure: {(error:NSError!) -> Void in
                    print(error)
                })
            }, failure: {(error:NSError!) -> Void in
                print(error.localizedDescription)
            }
        )
    }

    func doOAuthFlickr(parameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
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
                "api_key"        : parameters["consumerKey"]!,
                "user_id"        : "128483205@N08",
                "format"         : "json",
                "nojsoncallback" : "1",
                "extras"         : "url_q,url_z"
            ]
            oauthswift.client.get(url, parameters: parameters,
                success: {
                    data, response in
                    let jsonDict: AnyObject! = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                    print(jsonDict)
                }, failure: {(error:NSError!) -> Void in
                    print(error)
            })
        }, failure: {(error:NSError!) -> Void in
            print(error.localizedDescription)
        })
    }

    func doOAuthGithub(parameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            authorizeUrl:   "https://github.com/login/oauth/authorize",
            accessTokenUrl: "https://github.com/login/oauth/access_token",
            responseType:   "code"
        )
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/github")!, scope: "user,repo", state: state, success: {
            credential, response, parameters in
            self.showAlertView("Github", message: "oauth_token:\(credential.oauth_token)")
            }, failure: {(error:NSError!) -> Void in
                print(error.localizedDescription)
            })
    }
    func doOAuthSalesforce(parameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            authorizeUrl:   "https://login.salesforce.com/services/oauth2/authorize",
            accessTokenUrl: "https://login.salesforce.com/services/oauth2/token",
            responseType:   "code"
        )
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/salesforce")!, scope: "full", state: state, success: {
            credential, response, parameters in
            self.showAlertView("Salesforce", message: "oauth_token:\(credential.oauth_token)")
            }, failure: {(error:NSError!) -> Void in
                print(error.localizedDescription)
        })
    }

    func doOAuthInstagram(parameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            authorizeUrl:   "https://api.instagram.com/oauth/authorize",
            responseType:   "token"
        )

        let state: String = generateStateWithLength(20) as String
        oauthswift.authorize_url_handler = get_url_handler()
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/instagram")!, scope: "likes+comments", state:state, success: {
            credential, response, parameters in
            self.showAlertView("Instagram", message: "oauth_token:\(credential.oauth_token)")
            let url :String = "https://api.instagram.com/v1/users/1574083/?access_token=\(credential.oauth_token)"
            let parameters :Dictionary = Dictionary<String, AnyObject>()
            oauthswift.client.get(url, parameters: parameters,
                success: {
                    data, response in
                    let jsonDict: AnyObject! = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                    print(jsonDict)
                }, failure: {(error:NSError!) -> Void in
                    print(error)
            })
        }, failure: {(error:NSError!) -> Void in
            print(error.localizedDescription)
        })
    }

    func doOAuthFoursquare(parameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            authorizeUrl:   "https://foursquare.com/oauth2/authorize",
            responseType:   "token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/foursquare")!, scope: "", state: "", success: {
            credential, response, parameters in
            self.showAlertView("Foursquare", message: "oauth_token:\(credential.oauth_token)")
            }, failure: {(error:NSError!) -> Void in
                print(error.localizedDescription)
            })
    }

    func doOAuthFitbit(parameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            requestTokenUrl: "https://api.fitbit.com/oauth/request_token",
            authorizeUrl:    "https://www.fitbit.com/oauth/authorize?display=touch",
            accessTokenUrl:  "https://api.fitbit.com/oauth/access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/fitbit")!, success: {
            credential, response in
            self.showAlertView("Fitbit", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            }, failure: {(error:NSError!) -> Void in
                print(error.localizedDescription)
        })
    }

    func doOAuthWithings(parameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            requestTokenUrl: "https://oauth.withings.com/account/request_token",
            authorizeUrl:    "https://oauth.withings.com/account/authorize",
            accessTokenUrl:  "https://oauth.withings.com/account/access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/withings")!, success: {
            credential, response in
            self.showAlertView("Withings", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            }, failure: {(error:NSError!) -> Void in
                print(error.localizedDescription)
        })
    }

    func doOAuthLinkedin(parameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            requestTokenUrl: "https://api.linkedin.com/uas/oauth/requestToken",
            authorizeUrl:    "https://api.linkedin.com/uas/oauth/authenticate",
            accessTokenUrl:  "https://api.linkedin.com/uas/oauth/accessToken"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/linkedin")!, success: {
            credential, response in
            self.showAlertView("Linkedin", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            let parameters =  Dictionary<String, AnyObject>()
            oauthswift.client.get("https://api.linkedin.com/v1/people/~", parameters: parameters,
                    success: {
                        data, response in
                        let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                        print(dataString)
                    }, failure: {(error:NSError!) -> Void in
                print(error)
            })
        }, failure: {(error:NSError!) -> Void in
            print(error.localizedDescription)
        })
    }

    func doOAuthLinkedin2(parameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            authorizeUrl:   "https://www.linkedin.com/uas/oauth2/authorization",
            accessTokenUrl: "https://www.linkedin.com/uas/oauth2/accessToken",
            responseType:   "code"
        )
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "http://oauthswift.herokuapp.com/callback/linkedin2")!, scope: "r_fullprofile", state: state, success: {
            credential, response, parameters in
            self.showAlertView("Linkedin2", message: "oauth_token:\(credential.oauth_token)")
            let parameters =  Dictionary<String, AnyObject>()
            oauthswift.client.get("https://api.linkedin.com/v1/people/~?format=json", parameters: parameters,
                success: {
                    data, response in
                    let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                    print(dataString)
                }, failure: {(error:NSError!) -> Void in
                    print(error)
            })
            }, failure: {(error:NSError!) -> Void in
                print(error.localizedDescription)
        })
    }

    func doOAuthSmugmug(parameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
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
            print(error.localizedDescription)
        })
    }

    func doOAuthDropbox(parameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            authorizeUrl:   "https://www.dropbox.com/1/oauth2/authorize",
            accessTokenUrl: "https://api.dropbox.com/1/oauth2/token",
            responseType:   "token"
        )
        oauthswift.authorize_url_handler = get_url_handler()
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/dropbox")!, scope: "", state: "", success: {
            credential, response, parameters in
            self.showAlertView("Dropbox", message: "oauth_token:\(credential.oauth_token)")
            // Get Dropbox Account Info
            let parameters =  Dictionary<String, AnyObject>()
            oauthswift.client.get("https://api.dropbox.com/1/account/info", parameters: parameters,
                success: {
                    data, response in
                    let jsonDict: AnyObject! = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                    print(jsonDict)
                }, failure: {(error:NSError!) -> Void in
                    print(error)
                })
            }, failure: {(error:NSError!) -> Void in
                print(error.localizedDescription)
        })
    }

    func doOAuthDribbble(parameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            authorizeUrl:   "https://dribbble.com/oauth/authorize",
            accessTokenUrl: "https://dribbble.com/oauth/token",
            responseType:   "code"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/dribbble")!, scope: "", state: "", success: {
            credential, response, parameters in
            self.showAlertView("Dribbble", message: "oauth_token:\(credential.oauth_token)")
            // Get User
            let parameters =  Dictionary<String, AnyObject>()
            oauthswift.client.get("https://api.dribbble.com/v1/user?access_token=\(credential.oauth_token)", parameters: parameters,
                success: {
                    data, response in
                    let jsonDict: AnyObject! = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                    print(jsonDict)
                }, failure: {(error:NSError!) -> Void in
                    print(error)
                })
            }, failure: {(error:NSError!) -> Void in
                print(error.localizedDescription)
        })
    }

	func doOAuthBitBucket(parameters: [String:String]){
		let oauthswift = OAuth1Swift(
			consumerKey:    parameters["consumerKey"]!,
			consumerSecret: parameters["consumerSecret"]!,
			requestTokenUrl: "https://bitbucket.org/api/1.0/oauth/request_token",
			authorizeUrl:    "https://bitbucket.org/api/1.0/oauth/authenticate",
			accessTokenUrl:  "https://bitbucket.org/api/1.0/oauth/access_token"
		)
		oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/bitbucket")!, success: {
			credential, response in
			self.showAlertView("BitBucket", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
			let parameters =  Dictionary<String, AnyObject>()
			oauthswift.client.get("https://bitbucket.org/api/1.0/user", parameters: parameters,
				success: {
					data, response in
					let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
					print(dataString)
				}, failure: {(error:NSError!) -> Void in
					print(error)
			})
			}, failure: {(error:NSError!) -> Void in
				print(error.localizedDescription)
		})
	}
    func doOAuthGoogle(parameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            authorizeUrl:   "https://accounts.google.com/o/oauth2/auth",
            accessTokenUrl: "https://accounts.google.com/o/oauth2/token",
            responseType:   "code"
        )
        // For googgle the redirect_uri should match your this syntax: your.bundle.id:/oauth2Callback
        // in plist define a url schem with: your.bundle.id:
        oauthswift.authorizeWithCallbackURL( NSURL(string: "https://oauthswift.herokuapp.com/callback/google")!, scope: "https://www.googleapis.com/auth/drive", state: "", success: {
            credential, response, parameters in
            self.showAlertView("Google", message: "oauth_token:\(credential.oauth_token)")
            let parameters =  Dictionary<String, AnyObject>()
            // Multi-part upload
            oauthswift.client.postImage("https://www.googleapis.com/upload/drive/v2/files", parameters: parameters, image: self.snapshot(),
                success: {
                    data, response in
                    let jsonDict: AnyObject! = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                    print("SUCCESS: \(jsonDict)")
                }, failure: {(error:NSError!) -> Void in
                    print(error)
            })
            }, failure: {(error:NSError!) -> Void in
                print("ERROR: \(error.localizedDescription)")
        })
    }

    func doOAuthIntuit(parameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            requestTokenUrl: "https://oauth.intuit.com/oauth/v1/get_request_token",
            authorizeUrl:    "https://appcenter.intuit.com/Connect/Begin",
            accessTokenUrl:  "https://oauth.intuit.com/oauth/v1/get_access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/intuit")!, success: {
            credential, response in
            self.showAlertView("Intuit", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            }, failure: {(error:NSError!) -> Void in
                print(error.localizedDescription)
        })
    }
    func doOAuthZaim(parameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            requestTokenUrl: "https://api.zaim.net/v2/auth/request",
            authorizeUrl:    "https://auth.zaim.net/users/auth",
            accessTokenUrl:  "https://api.zaim.net/v2/auth/access"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/zaim")!, success: {
            credential, response in
            self.showAlertView("Zaim", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            }, failure: {(error:NSError!) -> Void in
                print(error.localizedDescription)
        })
    }
    func doOAuthTumblr(parameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            requestTokenUrl: "http://www.tumblr.com/oauth/request_token",
            authorizeUrl:    "http://www.tumblr.com/oauth/authorize",
            accessTokenUrl:  "http://www.tumblr.com/oauth/access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/tumblr")!, success: {
            credential, response in
            self.showAlertView("Tumblr", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            }, failure: {(error:NSError!) -> Void in
                print(error.localizedDescription)
        })
    }
    func doOAuthSlack(parameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            authorizeUrl:   "https://slack.com/oauth/authorize",
            accessTokenUrl: "https://slack.com/api/oauth.access",
            responseType:   "code"
        )
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/slack")!, scope: "", state: state, success: {
            credential, response, parameters in
            self.showAlertView("Slack", message: "oauth_token:\(credential.oauth_token)")
            }, failure: {(error:NSError!) -> Void in
                print(error.localizedDescription, terminator: "")
        })
    }

    func doOAuthUber(parameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    parameters["consumerKey"]!,
            consumerSecret: parameters["consumerSecret"]!,
            authorizeUrl:   "https://login.uber.com/oauth/authorize",
            accessTokenUrl: "https://login.uber.com/oauth/token",
            responseType:   "code",
            contentType:    "multipart/form-data"
        )
        let state: String = generateStateWithLength(20) as String
        let redirectURL = "https://oauthswift.herokuapp.com/callback/uber".stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
        oauthswift.authorizeWithCallbackURL( NSURL(string: redirectURL!)!, scope: "profile", state: state, success: {
            credential, response, parameters in
            self.showAlertView("Uber", message: "oauth_token:\(credential.oauth_token)")
            }, failure: {(error:NSError!) -> Void in
                print(error.localizedDescription, terminator: "")
        })
    }

}

let services = Services()
let DocumentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
let FileManager: NSFileManager = NSFileManager.defaultManager()

extension ViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load config from files
        initConf()
        
        #if os(iOS)
            self.navigationItem.title = "OAuth"
            let tableView: UITableView = UITableView(frame: self.view.bounds, style: .Plain)
            tableView.delegate = self
            tableView.dataSource = self
            self.view.addSubview(tableView)
        #endif
    }
    
    // MARK: utility methods
    
    var confPath: String {
        let appPath = "\(DocumentDirectory)/.oauth/"
        if !FileManager.fileExistsAtPath(appPath) {
            do {
                try FileManager.createDirectoryAtPath(appPath, withIntermediateDirectories: false, attributes: nil)
            }catch {
                print("Failed to create \(appPath)")
            }
        }
        return "\(appPath)Services.plist"
    }
    
    func initConf() {
        initConfOld()
        print("Load configuration from \n\(self.confPath)")
        
        // Load config from model file
        if let path = NSBundle.mainBundle().pathForResource("Services", ofType: "plist") {
            services.loadFromFile(path)
            
            if !FileManager.fileExistsAtPath(confPath) {
                do {
                    try FileManager.copyItemAtPath(path, toPath: confPath)
                }catch {
                    print("Failed to copy empty conf to\(confPath)")
                }
            }
        }
        services.loadFromFile(confPath)
    }

    func initConfOld() { // TODO Must be removed later
        services["Twitter"] = Twitter
        services["Salesforce"] = Salesforce
        services["Flickr"] = Flickr
        services["Github"] = Github
        services["Instagram"] = Instagram
        services["Foursquare"] = Foursquare
        services["Fitbit"] = Fitbit
        services["Withings"] = Withings
        services["Linkedin"] = Linkedin
        services["Linkedin2"] = Linkedin2
        services["Dropbox"] = Dropbox
        services["Dribbble"] = Dribbble
        services["BitBucket"] = BitBucket
        services["GoogleDrive"] = GoogleDrive
        services["Smugmug "] =  Smugmug
        services["Intuit"] = Intuit
        services["Zaim"] = Zaim
        services["Tumblr"] = Tumblr
        services["Slack"] = Slack
        services["Uber"] = Uber
    }
    
    func snapshot() -> NSData {
        #if os(iOS)
            UIGraphicsBeginImageContext(self.view.frame.size)
            self.view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
            let fullScreenshot = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            UIImageWriteToSavedPhotosAlbum(fullScreenshot, nil, nil, nil)
            return  UIImageJPEGRepresentation(fullScreenshot, 0.5)!
        #elseif os(OSX)
            let rep: NSBitmapImageRep = self.view.bitmapImageRepForCachingDisplayInRect(self.view.bounds)!
            self.view.cacheDisplayInRect(self.view.bounds, toBitmapImageRep:rep)
            return rep.TIFFRepresentation!
        #endif
    }
    
    func showAlertView(title: String, message: String) {
        #if os(iOS)
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        #elseif os(OSX)
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.addButtonWithTitle("Close")
            alert.runModal()
        #endif
    }
    
    // MARK: create an optionnal internal web view to handle connection
    func createWebViewController() -> WebViewController {
        let controller = WebViewController()
        #if os(OSX)
            controller.view = NSView(frame: NSRect(x:0, y:0, width: 450, height: 500)) // needed if no nib or not loaded from storyboard
            controller.viewDidLoad()
        #endif
        return controller
    }
    
    func get_url_handler() -> OAuthSwiftURLHandlerType {
        // Create a WebViewController with default behaviour from OAuthWebViewController
        let url_handler = createWebViewController()
        #if os(OSX)
            self.addChildViewController(url_handler) // allow WebViewController to use this ViewController as parent to be presented
        #endif
        return url_handler
        
        #if os(OSX)
            // a better way is
            // - to make this ViewController implement OAuthSwiftURLHandlerType and assigned in oauthswift object
            /* return self */
            // - have an instance of WebViewController here (I) or a segue name to launch (S)
            // - in handle(url)
            //    (I) : affect url to WebViewController, and  self.presentViewControllerAsModalWindow(self.webViewController)
            //    (S) : affect url to a temp variable (ex: urlForWebView), then perform segue
            /* performSegueWithIdentifier("oauthwebview", sender:nil) */
            //         then override prepareForSegue() to affect url to destination controller WebViewController
            
        #endif
    }
    //(I)
    //let webViewController: WebViewController = createWebViewController()
    //(S)
    //var urlForWebView:?NSURL = nil
}

// MARK: - Table

#if os(iOS)
    extension ViewController: UITableViewDelegate, UITableViewDataSource {
        // MARK: UITableViewDataSource
        
        func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return services.keys.count
        }
        func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
            let service = services.keys[indexPath.row]
            cell.textLabel?.text = service

            if let parameters = services[service] where Services.parametersEmpty(parameters) {
                cell.textLabel?.textColor = UIColor.redColor()
            }
            return cell
        }

        // MARK: UITableViewDelegate

        func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
            let service: String = services.keys[indexPath.row]
            
            doAuthService(service)
            tableView.deselectRowAtIndexPath(indexPath, animated:true)
        }
    }
#elseif os(OSX)
    extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
        // MARK: NSTableViewDataSource
        
        func numberOfRowsInTableView(tableView: NSTableView) -> Int {
            return services.keys.count
        }
        
        func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
            return services.keys[row]
        }
        
        func tableView(tableView: NSTableView, didAddRowView rowView: NSTableRowView, forRow row: Int) {
            let service = services.keys[row]
            if let parameters = services[service] where Services.parametersEmpty(parameters) {
                rowView.backgroundColor = NSColor.redColor()
            }
        }

        // MARK: NSTableViewDelegate

        func tableViewSelectionDidChange(notification: NSNotification) {
            if let tableView = notification.object as? NSTableView {
                let row = tableView.selectedRow
                if  row != -1 {
                    let service: String = services.keys[row]
                    
                    doAuthService(service)
                    tableView.deselectRow(row)
                }
            }
        }
    }
#endif
