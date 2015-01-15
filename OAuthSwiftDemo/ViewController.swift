//
//  ViewController.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import UIKit
import OAuthSwift

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var services = ["Twitter", "Flickr", "Github", "Instagram", "Foursquare", "Fitbit", "Withings", "Linkedin", "Dropbox", "Dribbble"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "OAuth"
        let tableView: UITableView = UITableView(frame: self.view.bounds, style: .Plain)
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func doOAuthTwitter(){
        let oauthswift = OAuth1Swift(
            consumerKey:    Twitter["consumerKey"]!,
            consumerSecret: Twitter["consumerSecret"]!,
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl:    "https://api.twitter.com/oauth/authorize",
            accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
        )
        
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
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/github")!, scope: "user,repo", state: "GITHUB", success: {
            credential, response in
            self.showAlertView("Github", message: "oauth_token:\(credential.oauth_token)")
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
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/instagram")!, scope: "likes+comments", state:"INSTAGRAM", success: {
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
            authorizeUrl:    "https://www.fitbit.com/oauth/authorize",
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

    func doOAuthDropbox(){
        let oauthswift = OAuth2Swift(
            consumerKey:    Dropbox["consumerKey"]!,
            consumerSecret: Dropbox["consumerSecret"]!,
            authorizeUrl:   "https://www.dropbox.com/1/oauth2/authorize",
            accessTokenUrl: "https://api.dropbox.com/1/oauth2/token",
            responseType:   "token"
        )
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

    func showAlertView(title: String, message: String) {
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int  {
        return services.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        cell.textLabel?.text = services[indexPath.row]
        return cell;
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        var service: String = services[indexPath.row]
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
            case "Dropbox":
                doOAuthDropbox()
            case "Dribbble":
                doOAuthDribbble();
            default:
                println("default (check ViewController tableView)")
        }
        tableView.deselectRowAtIndexPath(indexPath, animated:true)
    }
    
    
}

