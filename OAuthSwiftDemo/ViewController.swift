//
//  ViewController.swift
//  oauth-swift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIWebViewDelegate, UITableViewDelegate, UITableViewDataSource {

    var services = ["Twitter", "Flickr", "Github", "Instagram", "Foursquare"]
    
    let failureHandler: ((NSError) -> Void) = {
        error in
        println(error.localizedDescription)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "OAuth"
        
        self.view.backgroundColor = UIColor.whiteColor()
        
        let tableView: UITableView = UITableView(frame: self.view.bounds, style: .Grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame.inset(dx: 0, dy: 29)
        
        let statusBarViewRect: CGRect  = UIApplication.sharedApplication().statusBarFrame;
        let statusBarHeight = statusBarViewRect.size.height
        
        let naviBarHeight = self.navigationController.navigationBar.bounds.height

        let heightPadding = statusBarHeight + naviBarHeight
        
        let buttonHeight: CGFloat = 50
        
        let buttonWidth: CGFloat = 320
        // Do any additional setup after loading the view, typically from a nib.
        var oauthButtonTwitter: UIButton = UIButton(frame: CGRectMake(0, heightPadding, buttonWidth, buttonHeight))
        oauthButtonTwitter.backgroundColor = UIColor.cyanColor()
        oauthButtonTwitter.setTitle("Twitter", forState: UIControlState.Normal)
        oauthButtonTwitter.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        oauthButtonTwitter.addTarget(self, action: "doOAuthTwitter", forControlEvents: UIControlEvents.TouchDown)
        self.view.addSubview(oauthButtonTwitter)
        
        var oauthButtonFlickr: UIButton = UIButton(frame: CGRectMake(0, heightPadding + buttonHeight * 1, buttonWidth, buttonHeight))
        oauthButtonFlickr.backgroundColor = UIColor.magentaColor()
        oauthButtonFlickr.setTitle("Flickr", forState: UIControlState.Normal)
        oauthButtonFlickr.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        oauthButtonFlickr.addTarget(self, action: "doOAuthFlickr", forControlEvents: UIControlEvents.TouchDown)
        self.view.addSubview(oauthButtonFlickr)

        var oauthButtonGithub: UIButton = UIButton(frame: CGRectMake(0, heightPadding + buttonHeight * 2, buttonWidth, buttonHeight))
        oauthButtonGithub.backgroundColor = UIColor.orangeColor()
        oauthButtonGithub.setTitle("Github", forState: UIControlState.Normal)
        oauthButtonGithub.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        oauthButtonGithub.addTarget(self, action: "doOAuthGithub", forControlEvents: UIControlEvents.TouchDown)
        self.view.addSubview(oauthButtonGithub)

        var oauthButtonInstagram: UIButton = UIButton(frame: CGRectMake(0, heightPadding + buttonHeight * 3, buttonWidth, buttonHeight))
        oauthButtonInstagram.backgroundColor = UIColor.yellowColor()
        oauthButtonInstagram.setTitle("Instagram", forState: UIControlState.Normal)
        oauthButtonInstagram.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        oauthButtonInstagram.addTarget(self, action: "doOAuthInstagram", forControlEvents: UIControlEvents.TouchDown)
        self.view.addSubview(oauthButtonInstagram)
        
        var oauthButton4sq: UIButton = UIButton(frame: CGRectMake(0, heightPadding + buttonHeight * 4, buttonWidth, buttonHeight))
        oauthButton4sq.backgroundColor = UIColor.greenColor()
        oauthButton4sq.setTitle("Foursquare", forState: UIControlState.Normal)
        oauthButton4sq.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        oauthButton4sq.addTarget(self, action: "doOAuthFoursquare", forControlEvents: UIControlEvents.TouchDown)
        self.view.addSubview(oauthButton4sq)

//        var oauthButtonGoogle: UIButton = UIButton(frame: CGRectMake(0, 350, 320, 50))
//        oauthButtonGoogle.setTitle("OAuth Google", forState: UIControlState.Normal)
//        oauthButtonGoogle.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
//        oauthButtonGoogle.addTarget(self, action: "doOAuthGoogle", forControlEvents: UIControlEvents.TouchDown)
//        self.view.addSubview(oauthButtonGoogle)
        
        self.view.addSubview(tableView);
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func doOAuthTwitter(){
        let oauthswift = OAuth1Swift(
            consumerKey: "t2U3FRYWOhMOAe26BSOpSo51v",
            consumerSecret: "UTcxQH6kf2UBVDgzYcNiQl83XWkqVdTTQzbipiPlqwpsrlDRlH",
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl:    "https://api.twitter.com/oauth/authorize",
            accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
        )
        
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/twitter"), success: {
            credential, response in
            self.showAlertView("Twitter", message: "noauth_token:\(credential.oauth_token)\n\n oauth_toke_secret:\(credential.oauth_token_secret)")
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
            self.showAlertView("Flickr", message: "oauth_token:\(credential.oauth_token)\n\n oauth_toke_secret:\(credential.oauth_token_secret)")
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
    
    func doOAuthGoogle(){
        let callbackURL = NSURL(string: "urn:ietf:wg:oauth:2.0:oob")
        let authorizeURL = NSURL(string: "https://accounts.google.com/o/oauth2/auth")
        let queryURL = NSURL(string: authorizeURL.absoluteString + "?client_id=929482709049-fcjfsaql6mrq6lentcvirda7pn5agv78.apps.googleusercontent.com&redirect_uri=\(callbackURL.absoluteString)&response_type=code&scope=email")
        self.openWebView(queryURL.absoluteString)
    }
    
    func openWebView(urlString: String){
        let webview: UIWebView = UIWebView()
        webview.frame = self.view.bounds
        webview.delegate = self;
        self.view.addSubview(webview)
        
        var url: NSURL = NSURL.URLWithString(urlString)
        var urlRequest: NSURLRequest = NSURLRequest(URL: url)
        webview.loadRequest(urlRequest)
    }

    func webView(webView: UIWebView!, shouldStartLoadWithRequest request: NSURLRequest!, navigationType: UIWebViewNavigationType) -> Bool{
        return true
    }
    func webViewDidStartLoad(webView: UIWebView!){
        
    }
    func webViewDidFinishLoad(webView: UIWebView!){
        //webView.ti
        //NSString* title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        //println(webView.stringByEvaluatingJavaScriptFromString("document.title"))
        //let title = webView.stringByEvaluatingJavaScriptFromString("document.title")
        let code = webView.stringByEvaluatingJavaScriptFromString("document.getElementById('code').value")
        if (!code.isEmpty){
            println(code)
            let oauthswift = OAuth2Swift(
                consumerKey: "929482709049-fcjfsaql6mrq6lentcvirda7pn5agv78.apps.googleusercontent.com",
                consumerSecret: "pKEznCFX4UonijP6Zwo1Jyls",
                authorizeUrl: "https://accounts.google.com/o/oauth2/auth",
                accessTokenUrl: "https://accounts.google.com/o/oauth2/token",
                responseType:   "code"
            )
            
            let callbackURL = NSURL(string: "urn:ietf:wg:oauth:2.0:oob")
        
            webView.removeFromSuperview()
            oauthswift.postOAuthAccessTokenWithRequestTokenByCode(code, success: {
                accessToken, response in
                println(accessToken)
            }, failure: failureHandler)
        }
    }
    func webView(webView: UIWebView!, didFailLoadWithError error: NSError!){
        
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
                println()
        }
        tableView!.deselectRowAtIndexPath(indexPath, animated:true)
    }
}

