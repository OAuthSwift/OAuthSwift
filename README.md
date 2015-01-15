![Image](Assets/OAuthSwift-icon.png "Image")

## OAuthSwift

Swift based OAuth library for iOS

### Support OAuth1.0, OAuth2.0

Twitter, Flickr, Github, Instagram, Foursquare. Fitbit, Withings, Linkedin, Dropbox, Dribbble etc

### Installation

OAuthSwift is packaged as a Swift framework. Currently this is the simplest way to add it to your app:

1. Drag OAuthSwift.xcodeproj to your project in the Project Navigator.
2. Select your project and then your app target. Open the Build Phases panel.
3. Expand the Target Dependencies group, and add OAuthSwift framework.
4. Create a CommonCrypto directory inside the project directory. create a module.map file. The module map will allow us to use the CommonCrypto library as a module within Swift. Its contents are:
```
module CommonCrypto [system] {
    header "/usr/include/CommonCrypto/CommonCrypto.h"
    link "CommonCrypto"
    export *
}
```
5. import OAuthSwift whenever you want to use OAuthSwift.

### Support Carthage

1. Install Carthage (https://github.com/Carthage/Carthage)
2. Create Carhfile file
```
github "dongri/OAuthSwift" ~> 0.1.7
```
3. Run `carthage update`.
4. On your application targets’ “General” settings tab, in the “Embedded Binaries” section, drag and drop OAuthSwift.framework from the Carthage/Build/iOS folder on disk.

### Setting Import Paths

![Image](Assets/ImportPaths.png "Image")

### Setting URL Schemes

![Image](Assets/URLSchemes.png "Image")

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

### OAuth pages

* [Twitter](https://dev.twitter.com/docs/auth/oauth)  
* [Flickr](https://www.flickr.com/services/api/auth.oauth.html)  
* [Github](https://developer.github.com/v3/oauth)  
* [Instagram](http://instagram.com/developer/authentication)  
* [Foursquare](https://developer.foursquare.com/overview/auth)  
* [Fitbit](https://wiki.fitbit.com/display/API/OAuth+Authentication+in+the+Fitbit+API)  
* [Withings](http://oauth.withings.com/api)  
* [Linkedin](https://developer.linkedin.com/documents/authentication)  
* [Dropbox](https://www.dropbox.com/developers/core/docs)  
* [Dribbble](http://developer.dribbble.com/v1/oauth/)


### Images

![Image](Assets/Services.png "Image")
![Image](Assets/TwitterOAuth.png "Image")
![Image](Assets/TwitterOAuthTokens.png "Image")

## License

OAuthSwift is available under the MIT license. See the LICENSE file for more info.

