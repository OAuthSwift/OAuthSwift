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
    class ViewController: NSViewController {
       let segueSemaphore = Semaphore()
    }
#endif


// MARK: - do authentification
extension ViewController {
    
    func doAuthService(service: String) {

        guard var parameters = services[service] else {
            showAlertView("Miss configuration", message: "\(service) not configured")
            return
        }
        
        #if os(OSX)
            // Ask to user
            if Services.parametersEmpty(parameters) {
                dispatch_async(dispatch_get_main_queue()) {
                    self.performSegueWithIdentifier(ConsumerSegue, sender: self)
                }
                segueSemaphore.wait()
                if let key = segueSemaphore.key, secret = segueSemaphore.secret where !key.isEmpty && !secret.isEmpty {
                    parameters["consumerKey"] = key
                    parameters["consumerSecret"] = secret
                }
            }
        #endif
        
        if Services.parametersEmpty(parameters) { // no value to set
            let message = "\(service) seems to have not weel configured. \nPlease fill consumer key and secret into configuration file \(self.confPath)"
            print(message)
            showAlertView("Miss configuration", message: message)
            // TODO here ask for parameters instead
        }
        
        parameters["name"] = service

        switch service {
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
        default:
            print("\(service) not implemented")
        }
    }
    
    func doOAuth500px(serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://api.500px.com/v1/oauth/request_token",
            authorizeUrl:"https://api.500px.com/v1/oauth/authorize",
            accessTokenUrl:"https://api.500px.com/v1/oauth/access_token"
        )
        
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/500px")!,
            success: {
                credential, response, parameters in
                self.showTokenAlert(serviceParameters["name"], credential: credential)
            }, failure: { error in
                print(error.localizedDescription)
        })
    }
    
    func doOAuthSpotify(serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://accounts.spotify.com/en/authorize",
            accessTokenUrl: "https://accounts.spotify.com/api/token",
            responseType:   "code"
        )
        let state: String = generateStateWithLength(20) as String
        
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/spotify")!,
            scope: "user-library-modify",
            state: state, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            }, failure: { error in
                print(error.localizedDescription)
        })
    }
    
    func doOAuthTwitter(serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl:    "https://api.twitter.com/oauth/authorize",
            accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
        )
        //oauthswift.authorize_url_handler = get_url_handler()
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/twitter")!, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            self.testTwitter(oauthswift)
            }, failure: { error in
                print(error.localizedDescription)
            }
        )
    }
    func testTwitter(oauthswift: OAuth1Swift) {
        oauthswift.client.get("https://api.twitter.com/1.1/statuses/mentions_timeline.json", parameters: [:],
            success: {
                data, response in
                let jsonDict: AnyObject! = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                print(jsonDict)
            }, failure: { error in
                print(error)
        })
    }

    func doOAuthFlickr(serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://www.flickr.com/services/oauth/request_token",
            authorizeUrl:    "https://www.flickr.com/services/oauth/authorize",
            accessTokenUrl:  "https://www.flickr.com/services/oauth/access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/flickr")!, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            self.testFlickr(oauthswift, consumerKey: serviceParameters["consumerKey"]!)
            }, failure: { error in
            print(error.localizedDescription)
        })
    }
    func testFlickr (oauthswift: OAuth1Swift, consumerKey: String) {
        let url :String = "https://api.flickr.com/services/rest/"
        let parameters :Dictionary = [
            "method"         : "flickr.photos.search",
            "api_key"        : consumerKey,
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
            }, failure: { error in
                print(error)
        })
    }

    func doOAuthGithub(serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://github.com/login/oauth/authorize",
            accessTokenUrl: "https://github.com/login/oauth/access_token",
            responseType:   "code"
        )
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/github")!, scope: "user,repo", state: state, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            }, failure: { error in
                print(error.localizedDescription)
            })
    }
    func doOAuthSalesforce(serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://login.salesforce.com/services/oauth2/authorize",
            accessTokenUrl: "https://login.salesforce.com/services/oauth2/token",
            responseType:   "code"
        )
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/salesforce")!, scope: "full", state: state, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            }, failure: { error in
                print(error.localizedDescription)
        })
    }

    func doOAuthInstagram(serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://api.instagram.com/oauth/authorize",
            responseType:   "token"
            // or 
            // accessTokenUrl: "https://api.instagram.com/oauth/access_token",
            // responseType:   "code"
        )

        let state: String = generateStateWithLength(20) as String
        oauthswift.authorize_url_handler = get_url_handler()
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/instagram")!, scope: "likes+comments", state:state, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            self.testInstagram(oauthswift)
            }, failure: { error in
                print(error.localizedDescription)
        })
    }
    func testInstagram(oauthswift: OAuth2Swift) {
        let url :String = "https://api.instagram.com/v1/users/1574083/?access_token=\(oauthswift.client.credential.oauth_token)"
        let parameters :Dictionary = Dictionary<String, AnyObject>()
        oauthswift.client.get(url, parameters: parameters,
            success: {
                data, response in
                let jsonDict: AnyObject! = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                print(jsonDict)
                
            }, failure: { error in
                print(error)
        })
    }

    func doOAuthFoursquare(serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://foursquare.com/oauth2/authorize",
            responseType:   "token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/foursquare")!, scope: "", state: "", success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            }, failure: { error in
                print(error.localizedDescription)
            })
    }

    func doOAuthFitbit(serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://api.fitbit.com/oauth/request_token",
            authorizeUrl:    "https://www.fitbit.com/oauth/authorize?display=touch",
            accessTokenUrl:  "https://api.fitbit.com/oauth/access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/fitbit")!, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            }, failure: { error in
                print(error.localizedDescription)
        })
    }
    
    func doOAuthFitbit2(serviceParameters: [String:String]) {
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://www.fitbit.com/oauth2/authorize",
            accessTokenUrl: "https://api.fitbit.com/oauth2/token",
            responseType:   "code"
        )
        oauthswift.accessTokenBasicAuthentification = true
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/fitbit2")!, scope: "profile weight", state: state, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            self.testFitbit2(oauthswift)
            }, failure: { error in
                print(error.localizedDescription)
        })
    }
    func testFitbit2(oauthswift: OAuth2Swift) {
        oauthswift.client.get("https://api.fitbit.com/1/user/-/profile.json", parameters: [:],
            success: {
                data, response in
                let jsonDict: AnyObject! = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                print(jsonDict)
            }, failure: { error in
                print(error.localizedDescription)
        })
    }

    func doOAuthWithings(serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://oauth.withings.com/account/request_token",
            authorizeUrl:    "https://oauth.withings.com/account/authorize",
            accessTokenUrl:  "https://oauth.withings.com/account/access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/withings")!, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            self.testWithings(oauthswift, userId: parameters["userid"]!)
            }, failure: { error in
                print(error.localizedDescription)
        })
    }
    func testWithings(oauthswift: OAuth1Swift, userId : NSString) {
        oauthswift.client.paramsLocation = .RequestURIQuery
        oauthswift.client.get("https://wbsapi.withings.net/v2/measure", parameters: ["action":"getactivity", "userid":userId, "date":"2016-02-15"],
            success: {
                data, response in
                let jsonDict: AnyObject! = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                print(jsonDict)
            }, failure: { error in
                print(error.localizedDescription)
        })
    }

    func doOAuthLinkedin(serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://api.linkedin.com/uas/oauth/requestToken",
            authorizeUrl:    "https://api.linkedin.com/uas/oauth/authenticate",
            accessTokenUrl:  "https://api.linkedin.com/uas/oauth/accessToken"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/linkedin")!, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            self.testLinkedin(oauthswift)
        }, failure: { error in
            print(error.localizedDescription)
        })
    }
    func testLinkedin(oauthswift: OAuth1Swift) {
        oauthswift.client.get("https://api.linkedin.com/v1/people/~", parameters: [:],
            success: {
                data, response in
                let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                print(dataString)
            }, failure: { error in
                print(error)
        })
    }

    func doOAuthLinkedin2(serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://www.linkedin.com/uas/oauth2/authorization",
            accessTokenUrl: "https://www.linkedin.com/uas/oauth2/accessToken",
            responseType:   "code"
        )
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "http://oauthswift.herokuapp.com/callback/linkedin2")!, scope: "r_fullprofile", state: state, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            self.testLinkedin2(oauthswift)

            }, failure: { error in
                print(error.localizedDescription)
        })
    }
    func testLinkedin2(oauthswift: OAuth2Swift) {
        oauthswift.client.get("https://api.linkedin.com/v1/people/~?format=json", parameters: [:],
            success: {
                data, response in
                let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                print(dataString)
            }, failure: { error in
                print(error)
        })
    }

    func doOAuthSmugmug(serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "http://api.smugmug.com/services/oauth/getRequestToken.mg",
            authorizeUrl:    "http://api.smugmug.com/services/oauth/authorize.mg",
            accessTokenUrl:  "http://api.smugmug.com/services/oauth/getAccessToken.mg"
        )
        oauthswift.allowMissingOauthVerifier = true
        // NOTE: Smugmug's callback URL is configured on their site and the one passed in is ignored.
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/smugmug")!, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
        }, failure: { error in
            print(error.localizedDescription)
        })
    }

    func doOAuthDropbox(serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://www.dropbox.com/1/oauth2/authorize",
            accessTokenUrl: "https://api.dropbox.com/1/oauth2/token",
            responseType:   "token"
        )
        oauthswift.authorize_url_handler = get_url_handler()
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/dropbox")!, scope: "", state: "", success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            // Get Dropbox Account Info
            let parameters =  Dictionary<String, AnyObject>()
            oauthswift.client.get("https://api.dropbox.com/1/account/info", parameters: parameters,
                success: {
                    data, response in
                    let jsonDict: AnyObject! = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                    print(jsonDict)
                }, failure: { error in
                    print(error)
                })
            }, failure: { error in
                print(error.localizedDescription)
        })
    }

    func doOAuthDribbble(serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://dribbble.com/oauth/authorize",
            accessTokenUrl: "https://dribbble.com/oauth/token",
            responseType:   "code"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/dribbble")!, scope: "", state: "", success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            // Get User
            let parameters =  Dictionary<String, AnyObject>()
            oauthswift.client.get("https://api.dribbble.com/v1/user?access_token=\(credential.oauth_token)", parameters: parameters,
                success: {
                    data, response in
                    let jsonDict: AnyObject! = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                    print(jsonDict)
                }, failure: { error in
                    print(error)
                })
            }, failure: { error in
                print(error.localizedDescription)
        })
    }

	func doOAuthBitBucket(serviceParameters: [String:String]){
		let oauthswift = OAuth1Swift(
			consumerKey:    serviceParameters["consumerKey"]!,
			consumerSecret: serviceParameters["consumerSecret"]!,
			requestTokenUrl: "https://bitbucket.org/api/1.0/oauth/request_token",
			authorizeUrl:    "https://bitbucket.org/api/1.0/oauth/authenticate",
			accessTokenUrl:  "https://bitbucket.org/api/1.0/oauth/access_token"
		)
		oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/bitbucket")!, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            self.testBitBucket(oauthswift)
			}, failure: { error in
				print(error.localizedDescription)
		})
	}
    func testBitBucket(oauthswift: OAuth1Swift) {
        oauthswift.client.get("https://bitbucket.org/api/1.0/user", parameters: [:],
            success: {
                data, response in
                let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                print(dataString)
            }, failure: { error in
                print(error)
        })
    }

    func doOAuthGoogle(serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://accounts.google.com/o/oauth2/auth",
            accessTokenUrl: "https://accounts.google.com/o/oauth2/token",
            responseType:   "code"
        )
        // For googgle the redirect_uri should match your this syntax: your.bundle.id:/oauth2Callback
        // in plist define a url schem with: your.bundle.id:
        oauthswift.authorizeWithCallbackURL( NSURL(string: "https://oauthswift.herokuapp.com/callback/google")!, scope: "https://www.googleapis.com/auth/drive", state: "", success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            let parameters =  Dictionary<String, AnyObject>()
            // Multi-part upload
            oauthswift.client.postImage("https://www.googleapis.com/upload/drive/v2/files", parameters: parameters, image: self.snapshot(),
                success: {
                    data, response in
                    let jsonDict: AnyObject! = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                    print("SUCCESS: \(jsonDict)")
                }, failure: { error in
                    print(error)
            })
            }, failure: { error in
                print("ERROR: \(error.localizedDescription)")
        })
    }

    func doOAuthIntuit(serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://oauth.intuit.com/oauth/v1/get_request_token",
            authorizeUrl:    "https://appcenter.intuit.com/Connect/Begin",
            accessTokenUrl:  "https://oauth.intuit.com/oauth/v1/get_access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/intuit")!, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            self.testIntuit(oauthswift, serviceParameters: serviceParameters)
            }, failure: { error in
                print(error.localizedDescription)
        })
    }
    func testIntuit(oauthswift: OAuth1Swift, serviceParameters: [String:String]){
        if let companyId = serviceParameters["companyId"]  {
            oauthswift.client.get("https://sandbox-quickbooks.api.intuit.com/v3/company/\(companyId)/account/1", headers: ["Accept":"application/json"],
                success: {
                    data, response in
                    if let jsonDict = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) , dico = jsonDict as? [String: AnyObject] {
                        print(dico)

                        // XXX to generate with good date etc...
                        let jsonUpdate = [
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
                        oauthswift.client.post("https://sandbox-quickbooks.api.intuit.com/v3/company/\(companyId)/account?operation=update", parameters: jsonUpdate,
                            headers: ["Accept": "application/json", "Content-Type":"application/json"],
                            success: {
                                data, response in
                                print(data)
                            }, failure: { error in
                                print(error)
                        })
                    }
                    else {
                        print("no json response")
                    }
                    
                }, failure: { error in
                    print(error)
            })
        }
    }

    func doOAuthZaim(serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://api.zaim.net/v2/auth/request",
            authorizeUrl:    "https://auth.zaim.net/users/auth",
            accessTokenUrl:  "https://api.zaim.net/v2/auth/access"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/zaim")!, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            }, failure: { error in
                print(error.localizedDescription)
        })
    }
    func doOAuthTumblr(serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "http://www.tumblr.com/oauth/request_token",
            authorizeUrl:    "http://www.tumblr.com/oauth/authorize",
            accessTokenUrl:  "http://www.tumblr.com/oauth/access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/tumblr")!, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            }, failure: { error in
                print(error.localizedDescription)
        })
    }
    func doOAuthSlack(serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://slack.com/oauth/authorize",
            accessTokenUrl: "https://slack.com/api/oauth.access",
            responseType:   "code"
        )
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/slack")!, scope: "", state: state, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            }, failure: { error in
                print(error.localizedDescription, terminator: "")
        })
    }

    func doOAuthUber(serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://login.uber.com/oauth/authorize",
            accessTokenUrl: "https://login.uber.com/oauth/token",
            responseType:   "code",
            contentType:    "multipart/form-data"
        )
        let state: String = generateStateWithLength(20) as String
        let redirectURL = "https://oauthswift.herokuapp.com/callback/uber".stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
        oauthswift.authorizeWithCallbackURL( NSURL(string: redirectURL!)!, scope: "profile", state: state, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            }, failure: { error in
                print(error.localizedDescription, terminator: "")
        })
    }
    
    func doOAuthGitter(serviceParameters: [String:String]){
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://gitter.im/login/oauth/authorize",
            accessTokenUrl: "https://gitter.im/login/oauth/token",
            responseType:   "code"
        )
        #if os(iOS)
            if #available(iOS 9.0, *) {
                oauthswift.authorize_url_handler = SafariURLHandler(viewController: self)
            }
        #endif
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/gitter")!, scope: "flow", state: state, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            }, failure: { error in
                print(error.localizedDescription, terminator: "")
        })
    }

    func doOAuthFacebook(serviceParameters: [String:String]) {
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://www.facebook.com/dialog/oauth",
            accessTokenUrl: "https://graph.facebook.com/oauth/access_token",
            responseType:   "code"
        )
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "https://oauthswift.herokuapp.com/callback/facebook")!, scope: "public_profile", state: state, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            self.testFacebook(oauthswift)
            }, failure: { error in
                print(error.localizedDescription, terminator: "")
        })
    }
    func testFacebook(oauthswift: OAuth2Swift) {
        oauthswift.client.get("https://graph.facebook.com/me?",
            success: {
                data, response in
                let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                print(dataString)
            }, failure: { error in
                print(error)
        })
    }

    func doOAuthHatena(serviceParameters: [String:String]){
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl: "https://www.hatena.com/oauth/initiate",
            authorizeUrl:    "https://www.hatena.ne.jp/oauth/authorize",
            accessTokenUrl:  "https://www.hatena.com/oauth/token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "https://oauthswift.herokuapp.com/callback/hatena")!, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            }, failure: { error in
                print(error.localizedDescription)
            }
        )
    }
   
    func doOAuthTrello(serviceParameters: [String:String]) {
        let oauthswift = OAuth1Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            requestTokenUrl:    "https://trello.com/1/OAuthGetRequestToken",
            authorizeUrl:       "https://trello.com/1/OAuthAuthorizeToken",
            accessTokenUrl:     "https://trello.com/1/OAuthGetAccessToken"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "https://oauthswift.herokuapp.com/callback/trello")!, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            self.testTrello(oauthswift)
            }, failure: { error in
                print(error.localizedDescription, terminator: "")
        })
    }
    
    func testTrello(oauthswift: OAuth1Swift) {
        oauthswift.client.get("https://trello.com/1/members/me/boards",
            success: {
                data, response in
                let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                print(dataString)
            }, failure: { error in
                print(error)
        })
    }

    func doOAuthBuffer(serviceParameters: [String:String]) {
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://bufferapp.com/oauth2/authorize",
            accessTokenUrl: "https://api.bufferapp.com/1/oauth2/token.json",
            responseType:   "code"
        )
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "https://oauthswift.herokuapp.com/callback/buffer")!, scope: "", state: state, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            self.testBuffer(oauthswift)
            }, failure: { error in
                print(error.localizedDescription, terminator: "")
        })
    }

    func testBuffer(oauthswift: OAuth2Swift) {
        oauthswift.client.get("https://api.bufferapp.com/1/user.json",
            success: {
                data, response in
                let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                print(dataString)
            }, failure: { error in
                print(error)
        })
    }

    func doOAuthGoodreads(serviceParameters: [String:String]) {
        let oauthswift = OAuth1Swift(
            consumerKey:        serviceParameters["consumerKey"]!,
            consumerSecret:     serviceParameters["consumerSecret"]!,
            requestTokenUrl:    "https://www.goodreads.com/oauth/request_token",
            authorizeUrl:       "https://www.goodreads.com/oauth/authorize?mobile=1",
            accessTokenUrl:     "https://www.goodreads.com/oauth/access_token"
        )
        oauthswift.allowMissingOauthVerifier = true
        oauthswift.authorizeWithCallbackURL(
            NSURL(string: "oauth-swift://oauth-callback/goodreads")!, success: {
                // The callback url you set here doesn't seem to make a differnce,
                // you have to set it up at the site when you get your developer key.
                credential, response, parameters in
                self.showTokenAlert(serviceParameters["name"], credential: credential)
                self.testGoodreads(oauthswift)
            }, failure: { error in
                print(error.localizedDescription, terminator: "")
        })

    }

    func testGoodreads(oauthswift: OAuth1Swift) {
        oauthswift.client.get("https://www.goodreads.com/api/auth_user",
            success: {
                data, response in
                // Most Goodreads methods return XML, you'll need a way to parse it.
                let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                print(dataString)
            }, failure: { error in
                print(error)
        })
    }

    func doOAuthTypetalk(serviceParameters: [String:String]) {
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://typetalk.in/oauth2/authorize",
            accessTokenUrl: "https://typetalk.in/oauth2/access_token",
            responseType:   "code"
        )
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "https://oauthswift.herokuapp.com/callback/typetalk")!, scope: "", state: state, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            self.testTypetalk(oauthswift)
            }, failure: { error in
                print(error.localizedDescription, terminator: "")
        })
    }

    func testTypetalk(oauthswift: OAuth2Swift) {
        oauthswift.client.get("https://typetalk.in/api/v1/profile",
            success: {
                data, response in
                let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                print(dataString)
            }, failure: { error in
                print(error)
        })
    }
    
    func doOAuthSoundCloud(serviceParameters: [String:String]) {
        let oauthswift = OAuth2Swift(
            consumerKey:    serviceParameters["consumerKey"]!,
            consumerSecret: serviceParameters["consumerSecret"]!,
            authorizeUrl:   "https://soundcloud.com/connect",
            accessTokenUrl: "https://api.soundcloud.com/oauth2/token",
            responseType:   "code"
        )
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL( NSURL(string: "https://oauthswift.herokuapp.com/callback/soundcloud")!, scope: "", state: state, success: {
            credential, response, parameters in
            self.showTokenAlert(serviceParameters["name"], credential: credential)
            self.testSoundCloud(oauthswift,credential.oauth_token)
            }, failure: { error in
                print(error.localizedDescription)
        })
    }
    
    func testSoundCloud(oauthswift: OAuth2Swift, _ oauthToken: String) {
        oauthswift.client.get("https://api.soundcloud.com/me?oauth_token=\(oauthToken)",
                              success: {
                                data, response in
                                let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                                print(dataString)
            }, failure: { error in
                print(error)
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
        
        // init now
        get_url_handler()
        
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

    func showTokenAlert(name: String?, credential: OAuthSwiftCredential) {
        var message = "oauth_token:\(credential.oauth_token)"
        if !credential.oauth_token_secret.isEmpty {
           message += "\n\noauth_toke_secret:\(credential.oauth_token_secret)"
        }
        self.showAlertView(name ?? "Service", message: message)
        
        if let service = name {
            services.updateService(service, dico: ["authentified":"1"])
            // TODO refresh graphic
        }
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
    
    
    #if os(OSX)
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == ConsumerSegue {
            if let consumerController = segue.destinationController as? ConsumerViewController {
                consumerController.consumerDelegate = self
            }
        }
        else {
            super.prepareForSegue(segue, sender: sender)
        }
    }
    
    #endif
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
            if let parameters = services[service], authentified = parameters["authentified"] where authentified == "1" {
                cell.textLabel?.textColor = UIColor.greenColor()
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
            if let parameters = services[service], authentified = parameters["authentified"] where authentified == "1" {
                 rowView.backgroundColor  = NSColor.greenColor()
            }
        }

        // MARK: NSTableViewDelegate

        func tableViewSelectionDidChange(notification: NSNotification) {
            if let tableView = notification.object as? NSTableView {
                let row = tableView.selectedRow
                if  row != -1 {
                    let service: String = services.keys[row]
                    
                   
                    dispatch_async( dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                        self.doAuthService(service)
                    }
                    tableView.deselectRow(row)
                }
            }
        }
    }
#endif


#if os(OSX)
    let ConsumerSegue = "consumer"

    extension ViewController: ConsumerViewControllerDelegate {
        func didKey(key: String, secret: String) {
            self.segueSemaphore.signal(key, secret: secret)
        }
        
        func didCancel() {
            self.segueSemaphore.signal()
        }
    }
    
    protocol ConsumerViewControllerDelegate {
        func didKey(key: String, secret: String)
        func didCancel()
    }

    class ConsumerViewController: ViewController {
        
        var consumerDelegate: ConsumerViewControllerDelegate?
       
        @IBOutlet var keyTextField: NSTextField!
        @IBOutlet var secretTextField: NSTextField!

        @IBAction func ok(sender: AnyObject?) {
            self.dismissController(sender)
            consumerDelegate?.didKey(keyTextField.stringValue, secret: secretTextField.stringValue)
        }
        
        @IBAction func cancel(sender: AnyObject?) {
            self.dismissController(sender)
            consumerDelegate?.didCancel()
        }

    }
    
    class Semaphore {
        let segueSemaphore = dispatch_semaphore_create(0)
        var key: String?
        var secret: String?
        
        func wait() {
            dispatch_semaphore_wait(segueSemaphore, DISPATCH_TIME_FOREVER) // wait user
        }
        
        func signal(key: String? = nil, secret: String? = nil) {
            self.key = key
            self.secret = secret
            dispatch_semaphore_signal(segueSemaphore)
        }
    }

#endif
