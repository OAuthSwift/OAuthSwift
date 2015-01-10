# OAuthSwift

[![CI Status](http://img.shields.io/travis/Dongri Jin/OAuthSwift.svg?style=flat)](https://travis-ci.org/Dongri Jin/OAuthSwift)
[![Version](https://img.shields.io/cocoapods/v/OAuthSwift.svg?style=flat)](http://cocoadocs.org/docsets/OAuthSwift)
[![License](https://img.shields.io/cocoapods/l/OAuthSwift.svg?style=flat)](http://cocoadocs.org/docsets/OAuthSwift)
[![Platform](https://img.shields.io/cocoapods/p/OAuthSwift.svg?style=flat)](http://cocoadocs.org/docsets/OAuthSwift)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Installation

OAuthSwift is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```
pod "OAuthSwift"
```

## Author

Dongri Jin, dongriat@gmail.com

## License

OAuthSwift is available under the MIT license. See the LICENSE file for more info.


OAuthSwift
==========

Swift based OAuth library for iOS

### Support OAuth1.0, OAuth2.0

Twitter, Flickr, Github, Instagram, Foursquare. Fitbit, Withings, Linkedin, Dropbox etc

### OAuth pages

[Twitter](https://dev.twitter.com/docs/auth/oauth)  
[Flickr](https://www.flickr.com/services/api/auth.oauth.html)  
[Github](https://developer.github.com/v3/oauth)  
[Instagram](http://instagram.com/developer/authentication)  
[Foursquare](https://developer.foursquare.com/overview/auth)  
[Fitbit](https://wiki.fitbit.com/display/API/OAuth+Authentication+in+the+Fitbit+API)  
[Withings](http://oauth.withings.com/api)  
[Linkedin](https://developer.linkedin.com/documents/authentication)  
[Dropbox](https://www.dropbox.com/developers/core/docs)  

### Examples

```swift
// AppDelegate
func application(application: UIApplication!, openURL url: NSURL!, sourceApplication: String!, annotation: AnyObject!) -> Bool {
  if (url.host == "oauth-callback") {
    if (url.path!.hasPrefix("/twitter")){
      OAuth1Swift.handleOpenURL(url)
    }
    if ( url.path!.hasPrefix("/github" )){
      OAuth2Swift.handleOpenURL(url)
    }
  }
  return true
}

// OAuth1.0
let oauthswift = OAuth1Swift(
    consumerKey:    "********",
    consumerSecret: "********",
    requestTokenUrl: "https://api.twitter.com/oauth/request_token",
    authorizeUrl:    "https://api.twitter.com/oauth/authorize",
    accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
)
oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/twitter"), success: {
    credential, response in
    println(credential.oauth_token)
    println(credential.oauth_token_secret)
}, failure: failureHandler)

// OAuth2.0
let oauthswift = OAuth2Swift(
    consumerKey:    "********",
    consumerSecret: "********",
    authorizeUrl:   "https://api.instagram.com/oauth/authorize",
    responseType:   "token"
)
oauthswift.authorizeWithCallbackURL( NSURL(string: "oauth-swift://oauth-callback/instagram"), scope: "likes+comments", state:"INSTAGRAM", success: {
    credential, response in
    println(credential.oauth_token)
}, failure: failureHandler)

```

### Setting Swift Compiler

![Image](OAuthSwiftDemo/Images/SwiftCompiler.png "Image")

### Setting URL Schemes

![Image](OAuthSwiftDemo/Images/URLSchemes.png "Image")

### Images

![Image](OAuthSwiftDemo/Images/Services.png "Image")
![Image](OAuthSwiftDemo/Images/TwitterOAuth.png "Image")
![Image](OAuthSwiftDemo/Images/TwitterOAuthTokens.png "Image")
