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
    
    let failureHandler: ((NSError) -> Void) = {
        error in
        println(error.localizedDescription)
    }

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
            consumerKey:    "t2U3FRYWOhMOAe26BSOpSo51v",
            consumerSecret: "UTcxQH6kf2UBVDgzYcNiQl83XWkqVdTTQzbipiPlqwpsrlDRlH",
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl:    "https://api.twitter.com/oauth/authorize",
            accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
        )
        
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/twitter"), success: {
            credential, response in
            self.showAlertView("Twitter", message: "auth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
        }, failure: failureHandler)
    }

    func doOAuthFlickr(){
        let oauthswift = OAuth1Swift(
            consumerKey:     "93ef032c7fc940daef72919669eb0f3f",
            consumerSecret:  "2a6338717e0532dc",
            requestTokenUrl: "https://www.flickr.com/services/oauth/request_token",
            authorizeUrl:    "https://www.flickr.com/services/oauth/authorize",
            accessTokenUrl:  "https://www.flickr.com/services/oauth/access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/flickr"), success: {
            credential, response in
            self.showAlertView("Flickr", message: "oauth_token:\(credential.oauth_token)\n\noauth_toke_secret:\(credential.oauth_token_secret)")
        }, failure: failureHandler)
        
    }

    func doOAuthGithub(){
        let oauthswift = OAuth2Swift(
            consumerKey:    "a80f8187bb1ead11e1ef",
            consumerSecret: "bca5df25821d9d5bfdb7a3c6286c5b48b856f233",
            authorizeUrl:   "https://github.com/login/oauth/authorize",
            accessTokenUrl: "https://github.com/login/oauth/access_token",
            responseType:   "code"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/github"), scope: "user,repo", state: "GITHUB", success: {
            credential, response in
            self.showAlertView("Github", message: "oauth_token:\(credential.oauth_token)")
        }, failure: failureHandler)
        
    }

    func doOAuthInstagram(){
        let oauthswift = OAuth2Swift(
            consumerKey:    "32319c77fdc94c43959f25206060c11a",
            consumerSecret: "04e86de6a0e14b0ba2060bc5ae636c30",
            authorizeUrl:   "https://api.instagram.com/oauth/authorize",
            responseType:   "token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/instagram"), scope: "likes+comments", state:"INSTAGRAM", success: {
            credential, response in
            self.showAlertView("Instagram", message: "oauth_token:\(credential.oauth_token)")
        }, failure: failureHandler)
        
    }

    func doOAuthFoursquare(){
        let oauthswift = OAuth2Swift(
            consumerKey:    "HW4EN2F4GBP1XZKSB4UWZXOMYVDVMDCRUASSK1RH5GDUBJ13",
            consumerSecret: "JLMP4UAT4RR00J01Y4HGOZCZ4N5QZESMYL1D2HATO4RB0W2N",
            authorizeUrl:   "https://foursquare.com/oauth2/authorize",
            responseType:   "token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/foursquare"), scope: nil, state: nil, success: {
            credential, response in
            self.showAlertView("Foursquare", message: "oauth_token:\(credential.oauth_token)")
        }, failure: failureHandler)
        
    }
    
    func showAlertView(title: String, message: String) {
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int  {
        return services.count
    }
    
    func tableView(tableView: UITableView?, cellForRowAtIndexPath indexPath:NSIndexPath!) -> UITableViewCell! {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        cell.text = services[indexPath.row]
        return cell;
    }
    
    func tableView(tableView: UITableView?, didSelectRowAtIndexPath indexPath:NSIndexPath!) {
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
        tableView!.deselectRowAtIndexPath(indexPath, animated:true)
    }
}

