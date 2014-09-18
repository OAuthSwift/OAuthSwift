//
//  ViewController.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var services = ["Twitter", "Flickr", "Github", "Instagram", "Foursquare"]
    
//    let failureHandler: (NSError) -> Void = {
//        error in
//        println(error.localizedDescription)
//    }
    
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
        
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/twitter"), success: {
            credential, response in
            self.showAlertView("Twitter", message: "auth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
            }, failure: {(error:NSError!) -> Void in
                println(error.localizedDescription)
            })
    }

    func doOAuthFlickr(){
        let oauthswift = OAuth1Swift(
            consumerKey:    Flickr["consumerKey"]!,
            consumerSecret: Flickr["consumerSecret"]!,
            requestTokenUrl: "https://www.flickr.com/services/oauth/request_token",
            authorizeUrl:    "https://www.flickr.com/services/oauth/authorize",
            accessTokenUrl:  "https://www.flickr.com/services/oauth/access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/flickr"), success: {
            credential, response in
            self.showAlertView("Flickr", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
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
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/github"), scope: "user,repo", state: "GITHUB", success: {
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
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/instagram"), scope: "likes+comments", state:"INSTAGRAM", success: {
            credential, response in
            self.showAlertView("Instagram", message: "oauth_token:\(credential.oauth_token)")
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
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/foursquare"), scope: "", state: "", success: {
            credential, response in
            self.showAlertView("Foursquare", message: "oauth_token:\(credential.oauth_token)")
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
        cell.textLabel!.text = services[indexPath.row]
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
            default:
                println("default")
        }
        tableView.deselectRowAtIndexPath(indexPath, animated:true)
    }
    
    
}

