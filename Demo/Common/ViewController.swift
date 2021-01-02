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
import SafariServices
#elseif os(OSX)
import AppKit
#endif

class ViewController: OAuthViewController {
    // oauth swift object (retain)
    var oauthswift: OAuthSwift?
    
    var currentParameters = [String: String]()
    let formData = Semaphore<FormViewControllerData>()
    
    lazy var internalWebViewController: WebViewController = {
        let controller = WebViewController()
        #if os(OSX)
        controller.view = NSView(frame: NSRect(x:0, y:0, width: 450, height: 500)) // needed if no nib or not loaded from storyboard
        #elseif os(iOS)
        controller.view = UIView(frame: UIScreen.main.bounds) // needed if no nib or not loaded from storyboard
        #endif
        controller.delegate = self
        controller.viewDidLoad() // allow WebViewController to use this ViewController as parent to be presented
        return controller
    }()
    
}

extension ViewController: OAuthWebViewControllerDelegate {
    #if os(iOS) || os(tvOS)
    
    func oauthWebViewControllerDidPresent() {
        
    }
    func oauthWebViewControllerDidDismiss() {
        
    }
    #endif
    
    func oauthWebViewControllerWillAppear() {
        
    }
    func oauthWebViewControllerDidAppear() {
        
    }
    func oauthWebViewControllerWillDisappear() {
        
    }
    func oauthWebViewControllerDidDisappear() {
        // Ensure all listeners are removed if presented web view close
        oauthswift?.cancel()
    }
}

extension ViewController {
    
    // MARK: - do authentification
    func doAuthService(service: String) {
        
        // Check parameters
        guard var parameters = services[service] else {
            showAlertView(title: "Miss configuration", message: "\(service) not configured")
            return
        }
        self.currentParameters = parameters
        
        // Ask to user by showing form from storyboards
        self.formData.data = nil
        Queue.main.async { [unowned self] in
            self.performSegue(withIdentifier: Storyboards.Main.formSegue, sender: self)
            // see prepare for segue
        }
        // Wait for result
        guard let data = formData.waitData() else {
            // Cancel
            return
        }
        
        parameters["consumerKey"] = data.key
        parameters["consumerSecret"] = data.secret
        
        if Services.parametersEmpty(parameters) { // no value to set
            let message = "\(service) seems to have not weel configured. \nPlease fill consumer key and secret into configuration file \(self.confPath)"
            print(message)
            Queue.main.async { [unowned self] in
                self.showAlertView(title: "Key and secret must not be empty", message: message)
            }
        }
        
        parameters["name"] = service
        
        switch service {
        case "Imgur" :
            doOAuthImgur(parameters)
        case "500px" :
            doOAuth500px(parameters)
        case "Spotify" :
            doOAuthSpotify(parameters)
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
        case "Fitbit2":
            doOAuthFitbit2(parameters)
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
        case "Gitter":
            doOAuthGitter(parameters)
        case "Facebook":
            doOAuthFacebook(parameters)
        case "Hatena":
            doOAuthHatena(parameters)
        case "Trello":
            doOAuthTrello(parameters)
        case "Buffer":
            doOAuthBuffer(parameters)
        case "Goodreads":
            doOAuthGoodreads(parameters)
        case "Typetalk":
            doOAuthTypetalk(parameters)
        case "SoundCloud":
            doOAuthSoundCloud(parameters)
        case "Wordpress":
            doOAuthWordpress(parameters)
        case "Digu":
            doOAuthDigu(parameters)
        case "Noun":
            doOAuthNoun(parameters)
        case "Lyft":
            doOAuthLyft(parameters)
        case "Twitch":
            doOAuthTwitch(parameters)
        case "Reddit":
            doOauthReddit(parameters)
        default:
            print("\(service) not implemented")
        }
    }
    
    // MARK: 500px
    func doOAuth500px(_ serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://api.500px.com/v1/oauth/request_token",
            authorizeUrl:"https://api.500px.com/v1/oauth/authorize",
            accessTokenUrl:"https://api.500px.com/v1/oauth/access_token"
        )
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/500px")!) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    // MARK: Spotify
    func doOAuthSpotify(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://accounts.spotify.com/en/authorize",
            accessTokenUrl: "https://accounts.spotify.com/api/token",
            responseType:   "code"
        )
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        
        let _ = oauthswift.authorize(
            withCallbackURL: URL(string: "oauth-swift://oauth-callback/spotify")!,
            scope: "user-library-modify",
            state: state) { result in
                switch result {
                case .success(let (credential, _, _)):
                    self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                case .failure(let error):
                    print(error.description)
                }
        }
    }
    
    // MARK: Imgur
    func doOAuthImgur(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://api.imgur.com/oauth2/authorize",
            accessTokenUrl: "https://api.imgur.com/oauth2/token",
            responseType:   "token"
        )
        self.oauthswift = oauthswift
        oauthswift.encodeCallbackURL = true
        oauthswift.encodeCallbackURLQuery = false
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        
        let _ = oauthswift.authorize(
            withCallbackURL: URL(string: "oauth-swift://oauth-callback/imgur")!,
            scope: "",
            state: state) { result in
                switch result {
                case .success(let (credential, _, _)):
                    self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                case .failure(let error):
                    print(error.description)
                }
        }
    }
    
    // MARK: Twitter
    func doOAuthTwitter(_ serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl:    "https://api.twitter.com/oauth/authorize",
            accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
        )
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "http://oauthswift.herokuapp.com/callback/twitter")!) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testTwitter(oauthswift)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    func testTwitter(_ oauthswift: OAuth1Swift) {
        let _ = oauthswift.client.get("https://api.twitter.com/1.1/statuses/mentions_timeline.json", parameters: [:]) { result in
            switch result {
            case .success(let response):
                let jsonDict = try? response.jsonObject()
                print(String(describing: jsonDict))
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: Flickr
    func doOAuthFlickr(_ serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://www.flickr.com/services/oauth/request_token",
            authorizeUrl:    "https://www.flickr.com/services/oauth/authorize",
            accessTokenUrl:  "https://www.flickr.com/services/oauth/access_token"
        )
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/flickr")!) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testFlickr(oauthswift, consumerKey: serviceParameters["consumerKey"]!)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    func testFlickr (_ oauthswift: OAuth1Swift, consumerKey: String) {
        let url :String = "https://api.flickr.com/services/rest/"
        let parameters :Dictionary = [
            "method"         : "flickr.photos.search",
            "api_key"        : consumerKey,
            "user_id"        : "128483205@N08",
            "format"         : "json",
            "nojsoncallback" : "1",
            "extras"         : "url_q,url_z"
        ]
        let _ = oauthswift.client.get(url, parameters: parameters) { result in
            switch result {
            case .success(let response):
                let jsonDict = try? response.jsonObject()
                print(jsonDict as Any)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: Github
    func doOAuthGithub(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://github.com/login/oauth/authorize",
            accessTokenUrl: "https://github.com/login/oauth/access_token",
            responseType:   "code"
        )
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/github")!, scope: "user,repo", state: state) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    //MARK: Salesforce
    func doOAuthSalesforce(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://login.salesforce.com/services/oauth2/authorize",
            accessTokenUrl: "https://login.salesforce.com/services/oauth2/token",
            responseType:   "code"
        )
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/salesforce")!, scope: "full", state: state) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    // MARK: Instagram
    func doOAuthInstagram(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://api.instagram.com/oauth/authorize",
            responseType:   "token"
            // or
            // accessTokenUrl: "https://api.instagram.com/oauth/access_token",
            // responseType:   "code"
        )
        
        let state = generateState(withLength: 20)
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/instagram")!, scope: "likes+comments", state:state) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testInstagram(oauthswift)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    func testInstagram(_ oauthswift: OAuth2Swift) {
        let url :String = "https://api.instagram.com/v1/users/1574083/?access_token=\(oauthswift.client.credential.oauthToken)"
        let parameters :Dictionary = Dictionary<String, AnyObject>()
        let _ = oauthswift.client.get(url, parameters: parameters) { result in
            switch result {
            case .success(let response):
                let jsonDict = try? response.jsonObject()
                print(jsonDict as Any)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: Foursquare
    func doOAuthFoursquare(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://foursquare.com/oauth2/authorize",
            responseType:   "token"
        )
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/foursquare")!, scope: "", state: "") { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    // MARK: Fitbit
    func doOAuthFitbit(_ serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://api.fitbit.com/oauth/request_token",
            authorizeUrl:    "https://www.fitbit.com/oauth/authorize?display=touch",
            accessTokenUrl:  "https://api.fitbit.com/oauth/access_token"
        )
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/fitbit")!) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    func doOAuthFitbit2(_ serviceParameters: [String:String]) {
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://www.fitbit.com/oauth2/authorize",
            accessTokenUrl: "https://api.fitbit.com/oauth2/token",
            responseType:   "code"
        )
        oauthswift.accessTokenBasicAuthentification = true
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/fitbit2")!, scope: "profile weight", state: state) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testFitbit2(oauthswift)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    func testFitbit2(_ oauthswift: OAuth2Swift) {
        let _ = oauthswift.client.get(
            "https://api.fitbit.com/1/user/-/profile.json",
            parameters: [:]) { result in
                switch result {
                case .success(let response):
                    let jsonDict = try? response.jsonObject()
                    print(jsonDict as Any)
                case .failure(let error):
                    print(error.description)
                }
        }
    }
    
    // MARK: Withings
    func doOAuthWithings(_ serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://oauth.withings.com/account/request_token",
            authorizeUrl:    "https://oauth.withings.com/account/authorize",
            accessTokenUrl:  "https://oauth.withings.com/account/access_token"
        )
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/withings")!) { result in
            switch result {
            case .success(let (credential, _, parameters)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testWithings(oauthswift, userId: parameters["userid"] as! String)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    func testWithings(_ oauthswift: OAuth1Swift, userId : String) {
        oauthswift.client.paramsLocation = .requestURIQuery
        let _ = oauthswift.client.get(
            "https://wbsapi.withings.net/v2/measure",
            parameters: ["action": "getactivity", "userid": userId, "date":"2016-02-15"]) { result in
                switch result {
                case .success(let response):
                    let jsonDict = try? response.jsonObject()
                    print(jsonDict as Any)
                case .failure(let error):
                    print(error.description)
                }
        }
    }
    
    // MARK: Linkedin
    func doOAuthLinkedin(_ serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://api.linkedin.com/uas/oauth/requestToken",
            authorizeUrl:    "https://api.linkedin.com/uas/oauth/authenticate",
            accessTokenUrl:  "https://api.linkedin.com/uas/oauth/accessToken"
        )
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/linkedin")!) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testLinkedin(oauthswift)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    func testLinkedin(_ oauthswift: OAuth1Swift) {
        let _ = oauthswift.client.get(
        "https://api.linkedin.com/v1/people/~", parameters: [:]) { result in
            switch result {
            case .success(let response):
                let dataString = response.string!
                print(dataString)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func doOAuthLinkedin2(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://www.linkedin.com/uas/oauth2/authorization",
            accessTokenUrl: "https://www.linkedin.com/uas/oauth2/accessToken",
            responseType:   "code"
        )
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "http://oauthswift.herokuapp.com/callback/linkedin2")!, scope: "r_fullprofile", state: state) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testLinkedin2(oauthswift)
                
            case .failure(let error):
                print(error.description)
            }
        }
    }
    func testLinkedin2(_ oauthswift: OAuth2Swift) {
        let _ = oauthswift.client.get(
        "https://api.linkedin.com/v1/people/~?format=json", parameters: [:]) { result in
            switch result {
            case .success(let response):
                let dataString = response.string!
                print(dataString)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: Smugmug
    func doOAuthSmugmug(_ serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "http://api.smugmug.com/services/oauth/getRequestToken.mg",
            authorizeUrl:    "http://api.smugmug.com/services/oauth/authorize.mg",
            accessTokenUrl:  "http://api.smugmug.com/services/oauth/getAccessToken.mg"
        )
        oauthswift.allowMissingOAuthVerifier = true
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        // NOTE: Smugmug's callback URL is configured on their site and the one passed in is ignored.
        let _ = oauthswift.authorize(
        withCallbackURL: "oauth-swift://oauth-callback/smugmug") { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    // MARK: Dropbox
    func doOAuthDropbox(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://www.dropbox.com/oauth2/authorize",
            accessTokenUrl: "https://api.dropbox.com/oauth2/token",
            responseType:   "token"
        )
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/dropbox")!, scope: "", state: "") { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                // Get Dropbox Account Info
                let parameters =  Dictionary<String, AnyObject>()
                let _ = oauthswift.client.get(
                "https://api.dropbox.com/2/users/get_account", parameters: parameters) { result in
                    switch result {
                    case .success(let response):
                        let jsonDict = try? response.jsonObject()
                        print(jsonDict as Any)
                    case .failure(let error):
                        print(error)
                    }
                }
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    // MARK: Dribbble
    func doOAuthDribbble(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://dribbble.com/oauth/authorize",
            accessTokenUrl: "https://dribbble.com/oauth/token",
            responseType:   "code"
        )
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/dribbble")!, scope: "", state: "") { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                // Get User
                let parameters =  [String: Any]()
                let _ = oauthswift.client.get("https://api.dribbble.com/v1/user?access_token=\(credential.oauthToken)", parameters: parameters) { result in
                    switch result {
                    case .success(let response):
                        let jsonDict = try? response.jsonObject()
                        print(jsonDict as Any)
                    case .failure(let error):
                        print(error)
                    }
                }
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    // MARK: BitBucket
    func doOAuthBitBucket(_ serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://bitbucket.org/api/1.0/oauth/request_token",
            authorizeUrl:    "https://bitbucket.org/api/1.0/oauth/authenticate",
            accessTokenUrl:  "https://bitbucket.org/api/1.0/oauth/access_token"
        )
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/bitbucket")!) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testBitBucket(oauthswift)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    func testBitBucket(_ oauthswift: OAuth1Swift) {
        let _ = oauthswift.client.get(
        "https://bitbucket.org/api/1.0/user", parameters: [:]) { result in
            switch result {
            case .success(let response):
                let dataString = response.string!
                print(dataString)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: Google
    func doOAuthGoogle(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://accounts.google.com/o/oauth2/auth",
            accessTokenUrl: "https://accounts.google.com/o/oauth2/token",
            responseType:   "code"
        )
        // For googgle the redirect_uri should match your this syntax: your.bundle.id:/oauth2Callback
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        oauthswift.allowMissingStateCheck = true
        // in plist define a url schem with: your.bundle.id:
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "https://oauthswift.herokuapp.com/callback/google")!, scope: "https://www.googleapis.com/auth/drive", state: "") { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                let parameters =  Dictionary<String, AnyObject>()
                // Multi-part upload
                let _ = oauthswift.client.postImage(
                "https://www.googleapis.com/upload/drive/v2/files", parameters: parameters, image: self.snapshot()) { result in
                    switch result {
                    case .success(let response):
                        let jsonDict = try? response.jsonObject()
                        print("SUCCESS: \(String(describing: jsonDict))")
                    case .failure(let error):
                        print(error)
                    }
                    
                }
            case .failure(let error):
                print("ERROR: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK/ Intuit
    func doOAuthIntuit(_ serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://oauth.intuit.com/oauth/v1/get_request_token",
            authorizeUrl:    "https://appcenter.intuit.com/Connect/Begin",
            accessTokenUrl:  "https://oauth.intuit.com/oauth/v1/get_access_token"
        )
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/intuit")!) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testIntuit(oauthswift, serviceParameters: serviceParameters)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    func testIntuit(_ oauthswift: OAuth1Swift, serviceParameters: [String:String]){
        guard let companyId = serviceParameters["companyId"] else { return }
        
        let _ = oauthswift.client.get("https://sandbox-quickbooks.api.intuit.com/v3/company/\(companyId)/account/1", headers: ["Accept":"application/json"]) { result in
            switch result {
            case .success(let response):
                if let jsonDict = try? response.jsonObject(options: .allowFragments) , let dico = jsonDict as? [String: AnyObject] {
                    print(dico)
                    
                    // XXX to generate with good date etc...
                    let jsonUpdate: [String : Any] = [
                        "Name": "Accounts Payable (A/P)",
                        "SubAccount": false,
                        "FullyQualifiedName": "Accounts Payable (A/P)",
                        "Active": true,
                        "Classification": "Liability",
                        "Description": "Description added during update.",
                        "AccountType": "Accounts Payable",
                        "AccountSubType": "AccountsPayable",
                        "CurrentBalance": -1091.23,
                        "CurrentBalanceWithSubAccounts": -1091.23,
                        "domain": "QBO",
                        "sparse": false,
                        "Id": "33",
                        "SyncToken": "0",
                        "MetaData": [
                            "CreateTime": "2014-09-12T10:12:02-07:00",
                            "LastUpdatedTime": "2015-06-30T15:09:07-07:00"
                        ]
                    ]
                    
                    // FIXME #80
                    let _ = oauthswift.client.post(
                        "https://sandbox-quickbooks.api.intuit.com/v3/company/\(companyId)/account?operation=update", parameters: jsonUpdate,
                        headers: ["Accept": "application/json", "Content-Type":"application/json"]) { result in
                            switch result {
                            case .success(let response):
                                print(response.data)
                            case .failure(let error):
                                print(error)
                            }
                    }
                }
                else {
                    print("no json response")
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: Zaim
    func doOAuthZaim(_ serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://api.zaim.net/v2/auth/request",
            authorizeUrl:    "https://auth.zaim.net/users/auth",
            accessTokenUrl:  "https://api.zaim.net/v2/auth/access"
        )
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/zaim")!) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    // MARK: Tumblr
    func doOAuthTumblr(_ serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:     serviceParameters["consumerKey"]!,
            consumerSecret:  serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://www.tumblr.com/oauth/request_token",
            authorizeUrl:    "https://www.tumblr.com/oauth/authorize",
            accessTokenUrl:  "https://www.tumblr.com/oauth/access_token"
        )
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/tumblr")!) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testTumblr(oauthswift, serviceParameters: serviceParameters)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    func testTumblr(_ oauthswift: OAuth1Swift, serviceParameters: [String:String]){
        let _ = oauthswift.client.get(
        "https://api.tumblr.com/v2/user/info", headers: ["Accept":"application/json"]) { result in
            switch result {
            case .success(let response):
                if let jsonDict = try? response.jsonObject(options: .allowFragments) , let dico = jsonDict as? [String: Any] {
                    print(dico)
                }
                else {
                    print("no json response")
                }
            case .failure(let error):
                print(error)
            }
        }
        
        let url = serviceParameters["blogURL"] ?? "good.tumblr.com"
        let _ = oauthswift.client.post(
        "https://api.tumblr.com/v2/user/follow", parameters: ["url": url]) { result in
            switch result {
            case .success(let response):
                let dataString = response.string!
                print(dataString)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    
    // MARK: Slack
    func doOAuthSlack(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://slack.com/oauth/authorize",
            accessTokenUrl: "https://slack.com/api/oauth.access",
            responseType:   "code"
        )
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/slack")!, scope: "", state: state) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
            case .failure(let error):
                print(error.localizedDescription, terminator: "")
            }
        }
    }
    
    // MARK: Uber
    func doOAuthUber(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://login.uber.com/oauth/authorize",
            accessTokenUrl: "https://login.uber.com/oauth/token",
            responseType:   "code",
            contentType:    "multipart/form-data"
        )
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        let redirectURL = "https://oauthswift.herokuapp.com/callback/uber".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: redirectURL!)!, scope: "profile", state: state) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
            case .failure(let error):
                print(error.localizedDescription, terminator: "")
            }
        }
    }
    
    // MARK Gitter
    func doOAuthGitter(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://gitter.im/login/oauth/authorize",
            accessTokenUrl: "https://gitter.im/login/oauth/token",
            responseType:   "code"
        )
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/gitter")!, scope: "flow", state: state) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
            case .failure(let error):
                print(error.localizedDescription, terminator: "")
            }
        }
    }
    
    // MAK : Facebook
    func doOAuthFacebook(_ serviceParameters: [String:String]) {
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://www.facebook.com/dialog/oauth",
            accessTokenUrl: "https://graph.facebook.com/oauth/access_token",
            responseType:   "code"
        )
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "https://oauthswift.herokuapp.com/callback/facebook")!, scope: "public_profile", state: state) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testFacebook(oauthswift)
            case .failure(let error):
                print(error.localizedDescription, terminator: "")
            }
        }
    }
    func testFacebook(_ oauthswift: OAuth2Swift) {
        let _ = oauthswift.client.get(
        "https://graph.facebook.com/me?") { result in
            switch result {
            case .success(let response):
                let dataString = response.string!
                print(dataString)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: Hatena
    func doOAuthHatena(_ serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://www.hatena.com/oauth/initiate",
            authorizeUrl:    "https://www.hatena.ne.jp/oauth/authorize",
            accessTokenUrl:  "https://www.hatena.com/oauth/token"
        )
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "https://oauthswift.herokuapp.com/callback/hatena")!) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    // MARK: Trello
    func doOAuthTrello(_ serviceParameters: [String:String]) {
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl:    "https://trello.com/1/OAuthGetRequestToken",
            authorizeUrl:       "https://trello.com/1/OAuthAuthorizeToken",
            accessTokenUrl:     "https://trello.com/1/OAuthGetAccessToken"
        )
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "https://oauthswift.herokuapp.com/callback/trello")!) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testTrello(oauthswift)
            case .failure(let error):
                print(error.localizedDescription, terminator: "")
            }
        }
    }
    
    func testTrello(_ oauthswift: OAuth1Swift) {
        let _ = oauthswift.client.get(
        "https://trello.com/1/members/me/boards") { result in
            switch result {
            case .success(let response):
                let dataString = response.string!
                print(dataString)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: Buffer
    func doOAuthBuffer(_ serviceParameters: [String:String]) {
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://bufferapp.com/oauth2/authorize",
            accessTokenUrl: "https://api.bufferapp.com/1/oauth2/token.json",
            responseType:   "code"
        )
        let state = generateState(withLength: 20)
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "https://oauthswift.herokuapp.com/callback/buffer")!, scope: "", state: state) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testBuffer(oauthswift)
            case .failure(let error):
                print(error.localizedDescription, terminator: "")
            }
        }
    }
    
    func testBuffer(_ oauthswift: OAuth2Swift) {
        let _ = oauthswift.client.get(
        "https://api.bufferapp.com/1/user.json") { result in
            switch result {
            case .success(let response):
                let dataString = response.string!
                print(dataString)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: Goodreads
    func doOAuthGoodreads(_ serviceParameters: [String:String]) {
        let oauthswift = OAuth1Swift(
            consumerKey:        serviceParameters["consumerKey"]!,
            consumerSecret:     serviceParameters["consumerSecret"]!,
            requestTokenUrl:    "https://www.goodreads.com/oauth/request_token",
            authorizeUrl:       "https://www.goodreads.com/oauth/authorize?mobile=1",
            accessTokenUrl:     "https://www.goodreads.com/oauth/access_token"
        )
        oauthswift.allowMissingOAuthVerifier = true
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        // The callback url you set here doesn't seem to make a differnce,
        // you have to set it up at the site when you get your developer key.
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/goodreads")!) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testGoodreads(oauthswift)
            case .failure(let error):
                print(error.localizedDescription, terminator: "")
            }
        }
    }
    
    func testGoodreads(_ oauthswift: OAuth1Swift) {
        let _ = oauthswift.client.get(
        "https://www.goodreads.com/api/auth_user") { result in
            switch result {
            case .success(let response):
                // Most Goodreads methods return XML, you'll need a way to parse it.
                let dataString = response.string!
                print(dataString)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: Typetalk
    func doOAuthTypetalk(_ serviceParameters: [String:String]) {
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://typetalk.in/oauth2/authorize",
            accessTokenUrl: "https://typetalk.in/oauth2/access_token",
            responseType:   "code"
        )
        let state = generateState(withLength: 20)
        
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "https://oauthswift.herokuapp.com/callback/typetalk")!, scope: "", state: state) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testTypetalk(oauthswift)
            case .failure(let error):
                print(error.localizedDescription, terminator: "")
            }
        }
    }
    
    func testTypetalk(_ oauthswift: OAuth2Swift) {
        let _ = oauthswift.client.get(
        "https://typetalk.in/api/v1/profile") { result in
            switch result {
            case .success(let response):
                let dataString = response.string!
                print(dataString)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: SoundCloud
    func doOAuthSoundCloud(_ serviceParameters: [String:String]) {
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://soundcloud.com/connect",
            accessTokenUrl: "https://api.soundcloud.com/oauth2/token",
            responseType:   "code"
        )
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "https://oauthswift.herokuapp.com/callback/soundcloud")!, scope: "", state: state) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testSoundCloud(oauthswift,credential.oauthToken)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    func testSoundCloud(_ oauthswift: OAuth2Swift, _ oauthToken: String) {
        let _ = oauthswift.client.get(
        "https://api.soundcloud.com/me?oauth_token=\(oauthToken)") { result in
            switch result {
            case .success(let response):
                let dataString = response.string!
                print(dataString)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: Wordpress
    func doOAuthWordpress(_ serviceParameters: [String:String]) {
        let wordpressURL = serviceParameters["url"] ?? "http://localhost/wordpress"
        let oauthswift = OAuth1Swift(
            consumerKey:        serviceParameters["consumerKey"]!,
            consumerSecret:     serviceParameters["consumerSecret"]!,
            requestTokenUrl:    "\(wordpressURL)/oauth1/request",
            authorizeUrl:       "\(wordpressURL)/oauth1/authorize",
            accessTokenUrl:     "\(wordpressURL)/oauth1/access"
            
        )
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        // The callback url you set here doesn't seem to make a differnce,
        // you have to set it up at the site when you get your developer key.
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/wordpress")!) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                
            case .failure(let error):
                print(error.localizedDescription, terminator: "")
            }
        }
        
    }
    
    // MARK: Digu
    func doOAuthDigu(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://digu.io/login/oauth/authorize",
            accessTokenUrl: "https://digu.io/login/oauth/access_token",
            responseType:   "code"
        )
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/digu")!, scope: "user,news,statuses", state: state) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    // MARK: Noun
    func doOAuthNoun(_ serviceParameters: [String:String]) {
        let oauthswift = OAuth1Swift(
            consumerKey:        serviceParameters["consumerKey"]!,
            consumerSecret:     serviceParameters["consumerSecret"]!,
            requestTokenUrl:    "",
            authorizeUrl:       "",
            accessTokenUrl: ""
        )
        self.oauthswift = oauthswift
        
        self.testNoun(oauthswift)
    }
    func testNoun(_ oauthswift: OAuth1Swift) {
        let _ = oauthswift.client.get("http://api.thenounproject.com/icon/apple") { result in
            switch result {
            case .success(let response):
                let dataJSON = try? response.jsonObject()
                print(String(describing: dataJSON))
            case .failure(let error):
                print(error)
            }
        }
    }
    
    // MARK: Lyft
    func doOAuthLyft(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://api.lyft.com/oauth/authorize",
            accessTokenUrl: "https://api.lyft.com/oauth/token",
            responseType:   "code",
            contentType:    "application/json"
        )
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/lift")!, scope: "rides.read", state: state) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
            case .failure(let error):
                print(error.description)
            }
        }
    }
  
    // MARK: Twitch
    func doOAuthTwitch(_ serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://id.twitch.tv/oauth2/authorize",
            accessTokenUrl: "https://id.twitch.tv/oauth2/token",
            responseType:   "code",
            contentType:    "application/json"
        )
        self.oauthswift = oauthswift
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/twitch")!, scope: "user_read", state: state) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testTwitch(oauthswift,credential.oauthToken)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    func testTwitch(_ oauthswift: OAuth2Swift, _ oauthToken: String) {
        let _ = oauthswift.client.get(
        "https://api.twitch.tv/kraken/user?oauth_token=\(oauthToken)", headers: ["Accept":"application/vnd.twitchtv.v5+json"]) { result in
            switch result {
            case .success(let response):
                let dataString = response.string!
                print(dataString)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func doOauthReddit(_ serviceParameters: [String:String]) {
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://www.reddit.com/api/v1/authorize.compact",
            accessTokenUrl: "https://www.reddit.com/api/v1/access_token",
            responseType:   "code",
            contentType:    "application/json"
        )
        self.oauthswift = oauthswift
        oauthswift.accessTokenBasicAuthentification = true
        oauthswift.authorizeURLHandler = getURLHandler()
        let state = generateState(withLength: 20)
        let _ = oauthswift.authorize(
        withCallbackURL: URL(string: "oauth-swift://oauth-callback/reddit")!, scope: "read", state: state) { result in
            switch result {
            case .success(let (credential, _, _)):
                self.showTokenAlert(name: serviceParameters["name"], credential: credential)
                self.testReddit(oauthswift, credential.oauthToken)
            case .failure(let error):
                print(error.description)
            }
        }
    }
    
    func testReddit(_ oauthswift: OAuth2Swift, _ oauthToken: String) {
        let applicationName = ""    // Provided by developer
        let username = ""           // Provided by developer
        let userAgent = "ios:\(applicationName):1.0 (by /u/\(username)"
        let headers = ["Authorization": "Bearer \(oauthToken)", "User-Agent": userAgent]
        let _ = oauthswift.client.get(
        "https://oauth.reddit.com/r/all", headers: headers) { result in
            switch result {
            case .success(let response):
                let dataString = response.string!
                print(dataString)
            case .failure(let error):
                print(error)
            }
        }
    }
}

let services = Services()
let DocumentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
let FileManager: FileManager = Foundation.FileManager.default

extension ViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load config from files
        initConf()
        
        // init now web view handler
        let _ = internalWebViewController.webView
        
        #if os(iOS)
        self.navigationItem.title = "OAuth"
        let tableView: UITableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        #endif
    }
    
    // MARK: utility methods
    
    var confPath: String {
        let appPath = "\(DocumentDirectory)/.oauth/"
        if !FileManager.fileExists(atPath: appPath) {
            do {
                try FileManager.createDirectory(atPath: appPath, withIntermediateDirectories: false, attributes: nil)
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
        if let path = Bundle.main.path(forResource: "Services", ofType: "plist") {
            services.loadFromFile(path)
            
            if !FileManager.fileExists(atPath: confPath) {
                do {
                    try FileManager.copyItem(atPath: path, toPath: confPath)
                }catch {
                    print("Failed to copy empty conf to\(confPath)")
                }
            }
        }
        services.loadFromFile(confPath)
      
        // Configure log level, if desired
        OAuthSwift.setLogLevel(.trace)
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
        services["Digu"] = Digu
    }
    
    func snapshot() -> Data {
        #if os(iOS)
        UIGraphicsBeginImageContext(self.view.frame.size)
        self.view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let fullScreenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        UIImageWriteToSavedPhotosAlbum(fullScreenshot!, nil, nil, nil)
        return fullScreenshot!.jpegData(compressionQuality: 0.5)!
        #elseif os(OSX)
        let rep: NSBitmapImageRep = self.view.bitmapImageRepForCachingDisplay(in: self.view.bounds)!
        self.view.cacheDisplay(in: self.view.bounds, to:rep)
        return rep.tiffRepresentation!
        #endif
    }
    
    func showAlertView(title: String, message: String) {
        #if os(iOS)
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        #elseif os(OSX)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "Close")
        alert.runModal()
        #endif
    }
    
    func showTokenAlert(name: String?, credential: OAuthSwiftCredential) {
        var message = "oauth_token:\(credential.oauthToken)"
        if !credential.oauthTokenSecret.isEmpty {
            message += "\n\noauth_token_secret:\(credential.oauthTokenSecret)"
        }
        self.showAlertView(title: name ?? "Service", message: message)
        
        if let service = name {
            services.updateService(service, dico: ["authentified":"1"])
            // TODO refresh graphic
        }
    }
    
    // MARK: handler
    
    func getURLHandler() -> OAuthSwiftURLHandlerType {
        guard let type = self.formData.data?.handlerType else {
            return OAuthSwiftOpenURLExternally.sharedInstance
        }
        switch type {
        case .external :
            return OAuthSwiftOpenURLExternally.sharedInstance
        case .`internal`:
            if internalWebViewController.parent == nil {
                self.addChild(internalWebViewController)
            }
            return internalWebViewController
        case .safari:
            #if os(iOS)
            if #available(iOS 9.0, *) {
                let handler = SafariURLHandler(viewController: self, oauthSwift: self.oauthswift!)
                handler.presentCompletion = {
                    print("Safari presented")
                }
                handler.dismissCompletion = {
                    print("Safari dismissed")
                }
                handler.factory = { url in
                    let controller = SFSafariViewController(url: url)
                    // Customize it, for instance
                    if #available(iOS 10.0, *) {
                        //  controller.preferredBarTintColor = UIColor.red
                    }
                    return controller
                }
                
                return handler
            }
            #endif
            return OAuthSwiftOpenURLExternally.sharedInstance
        case .asWeb:
            #if os(iOS)
            if #available(iOS 13.0, tvOS 13.0, *) {
                return ASWebAuthenticationURLHandler(callbackUrlScheme: "oauth-swift://oauth-callback/", presentationContextProvider: self)
            }
            #endif
            return OAuthSwiftOpenURLExternally.sharedInstance
        }

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
    //let webViewController: WebViewController = internalWebViewController
    //(S)
    //var urlForWebView:?URL = nil
    
    
    override func prepare(for segue: OAuthStoryboardSegue, sender: Any?) {
        if segue.identifier == Storyboards.Main.formSegue {
            #if os(OSX)
            let controller = segue.destinationController as? FormViewController
            #else
            let controller = segue.destination as? FormViewController
            #endif
            // Fill the controller
            if let controller = controller {
                controller.delegate = self
            }
        }
        
        super.prepare(for: segue, sender: sender)
    }
    
}

public typealias Queue = DispatchQueue
// MARK: - Table

#if os(iOS)
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.keys.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "Cell")
        let service = services.keys[indexPath.row]
        cell.textLabel?.text = service
        
        if let parameters = services[service] , Services.parametersEmpty(parameters) {
            cell.textLabel?.textColor = UIColor.red
        }
        if let parameters = services[service], let authentified = parameters["authentified"], authentified == "1" {
            cell.textLabel?.textColor = UIColor.green
        }
        return cell
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let service: String = services.keys[indexPath.row]
        
        DispatchQueue.global(qos: .background).async {
            self.doAuthService(service: service)
        }
        tableView.deselectRow(at: indexPath, animated:true)
    }
}
#elseif os(OSX)
extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    // MARK: NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return services.keys.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return services.keys[row]
    }
    
    // MARK: NSTableViewDelegate
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        let service = services.keys[row]
        if let parameters = services[service], Services.parametersEmpty(parameters) {
            rowView.backgroundColor = NSColor.red
        }
        if let parameters = services[service], let authentified = parameters["authentified"], authentified == "1" {
            rowView.backgroundColor  = NSColor.green
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let tableView = notification.object as? NSTableView {
            let row = tableView.selectedRow
            if  row != -1 {
                let service: String = services.keys[row]
                
                
                DispatchQueue.global(qos: .background).async {
                    self.doAuthService(service: service)
                }
                tableView.deselectRow(row)
            }
        }
    }
}
#endif

#if os(iOS)
import SafariServices
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
@available(iOS 13.0, tvOS 13.0, macCatalyst 13.0, *)
extension ViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.topWindow ?? ASPresentationAnchor()
    }
}
#endif

struct FormViewControllerData {
    var key: String
    var secret: String
    var handlerType: URLHandlerType
}

extension ViewController: FormViewControllerDelegate {
    
    var key: String? { return self.currentParameters["consumerKey"] }
    var secret: String? {return self.currentParameters["consumerSecret"] }
    
    func didValidate(key: String?, secret: String?, handlerType: URLHandlerType) {
        self.dismissForm()
        
        self.formData.publish(data: FormViewControllerData(key: key ?? "", secret: secret ?? "", handlerType: handlerType))
    }
    
    func didCancel() {
        self.dismissForm()
        
        self.formData.cancel()
    }
    
    func dismissForm() {
        #if os(iOS)
        /*self.dismissViewControllerAnimated(true) { // without animation controller
         print("form dismissed")
         }*/
        let _ = self.navigationController?.popViewController(animated: true)
        #endif
    }
}

// Little utility class to wait on data
class Semaphore<T> {
    let segueSemaphore = DispatchSemaphore(value: 0)
    var data: T?
    
    func waitData(timeout: DispatchTime? = nil) -> T? {
        if let timeout = timeout {
            let _ = segueSemaphore.wait(timeout: timeout) // wait user
        } else {
            segueSemaphore.wait()
        }
        return data
    }
    
    func publish(data: T) {
        self.data = data
        segueSemaphore.signal()
    }
    
    func cancel() {
        segueSemaphore.signal()
    }
}
