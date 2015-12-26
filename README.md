<p align="center">
  <img src="Assets/OAuthSwift-icon.png?raw=true" alt="OAuthSwift"/>
</p>

# OAuthSwift

Swift based OAuth library for iOS and OSX.

## Support OAuth1.0, OAuth2.0

Twitter, Flickr, Github, Instagram, Foursquare. Fitbit, Withings, Linkedin, Dropbox, Dribbble, Salesforce, BitBucket, GoogleDrive, Smugmug, Intuit, Zaim, Tumblr, Slack, Uber, Gitter, Facebook, Spotify etc

## Installation

OAuthSwift is packaged as a Swift framework. Currently this is the simplest way to add it to your app:

* Drag OAuthSwift.xcodeproj to your project in the Project Navigator.
* Select your project and then your app target. Open the Build Phases panel.
* Expand the Target Dependencies group, and add OAuthSwift framework.
* import OAuthSwift whenever you want to use OAuthSwift.

### Support Carthage

* Install Carthage (https://github.com/Carthage/Carthage)
* Create Cartfile file
```
github "OAuthSwift/OAuthSwift" ~> 0.5.0
```
* Run `carthage update`.
* On your application targets’ “General” settings tab, in the “Embedded Binaries” section, drag and drop OAuthSwift.framework from the Carthage/Build/iOS folder on disk.

### Support CocoaPods

* Podfile

```
platform :ios, '8.0'
use_frameworks!

pod "OAuthSwift", "~> 0.5.0"
```
## How to
### Setting URL Schemes
![Image](Assets/URLSchemes.png "Image")
Replace oauth-swift by your application name
### Examples

#### Handle URL in AppDelegate
```swift
func application(application: UIApplication!, openURL url: NSURL!, sourceApplication: String!, annotation: AnyObject!) -> Bool {
  if (url.host == "oauth-callback") {
    OAuthSwift.handleOpenURL(url)
  }
  return true
}
```
#### OAuth1.0
```swift
let oauthswift = OAuth1Swift(
    consumerKey:    "********",
    consumerSecret: "********",
    requestTokenUrl: "https://api.twitter.com/oauth/request_token",
    authorizeUrl:    "https://api.twitter.com/oauth/authorize",
    accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
)
oauthswift.authorizeWithCallbackURL(
    NSURL(string: "oauth-swift://oauth-callback/twitter")!,
    success: { credential, response, parameters in
      print(credential.oauth_token)
      print(credential.oauth_token_secret)
      print(parameters["user_id"])
    },
    failure: { error in
      print(error.localizedDescription)
    }             
)
```
#### OAuth2.0
```swift
let oauthswift = OAuth2Swift(
    consumerKey:    "********",
    consumerSecret: "********",
    authorizeUrl:   "https://api.instagram.com/oauth/authorize",
    responseType:   "token"
)
oauthswift.authorizeWithCallbackURL(
    NSURL(string: "oauth-swift://oauth-callback/instagram")!,
    scope: "likes+comments", state:"INSTAGRAM",
    success: { credential, response, parameters in
      print(credential.oauth_token)
    },
    failure: { error in
      print(error.localizedDescription)
    }
)

```

See demo for more examples

### Handle authorize URL
The authorize URL allow user to connect to a provider and give access to your application.

By default this URL is opened into the external web browser (ie. safari), but apple don't allow it for app-store iOS application.

To change this behavior you must set an `OAuthSwiftURLHandlerType`, simple protocol to handle an `NSURL`
```swift
oauthswift.authorize_url_handler = ..
```
For instance you can embed a web view into your application by providing a controller that display a web view (`UIWebView`, `WKWebView`).
Then this controller must implement `OAuthSwiftURLHandlerType` to load the URL into the web view
```swift
func handle(url: NSURL) {
  let req = NSURLRequest(URL: targetURL)
  self.webView.loadRequest(req)
  ...
```
and present the view (`presentViewController`, `performSegueWithIdentifier`, ...)
*You can extends `OAuthWebViewController` for a default implementation of view presentation and dismiss*

#### Use the SFSafariViewController (iOS9)
A default implementation of `OAuthSwiftURLHandlerType` is provided using the `SFSafariViewController`, with automatic view dismiss.
```swift
oauthswift.authorize_url_handler = SafariURLHandler(viewController: self)
```
Of course you can create your own class or customize the controller by setting the variable `SafariURLHandler#factory`.

## Make signed request

```swift
oauthswift.client.get("https://api.linkedin.com/v1/people/~",
      success: {
        data, response in
        let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
        print(dataString)
      }
      , failure: { error in
        print(error)
      }
)
// same with request method
oauthswift.client.request("https://api.linkedin.com/v1/people/~", .GET,
      parameters: [:], headers: [:],
      success: { ...
```

More examples into demo application: [ViewController.swift](/OAuthSwiftDemo/ViewController.swift)

## OAuth provider pages

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
* [Salesforce](https://www.salesforce.com/us/developer/docs/api_rest/)
* [BitBucket](https://confluence.atlassian.com/display/BITBUCKET/OAuth+on+Bitbucket)
* [GoogleDrive](https://developers.google.com/drive/v2/reference/)
* [Smugmug](https://smugmug.atlassian.net/wiki/display/API/OAuth)
* [Intuit](https://developer.intuit.com/docs/0100_accounting/0060_authentication_and_authorization/oauth_management_api)
* [Zaim](https://dev.zaim.net/home/api/authorize)
* [Tumblr](https://www.tumblr.com/docs/en/api/v2#auth)
* [Slack](https://api.slack.com/docs/oauth)
* [Uber](https://developer.uber.com/v1/auth/)
* [Gitter](https://developer.gitter.im/docs/authentication)
* [Facebook](https://developers.facebook.com/docs/facebook-login)
* [Spotify](https://developer.spotify.com/web-api/authorization-guide/)

## Images

![Image](Assets/Services.png "Image")
![Image](Assets/TwitterOAuth.png "Image")
![Image](Assets/TwitterOAuthTokens.png "Image")

## Contributing
 See [CONTRIBUTING.md](CONTRIBUTING.md)
 
[Add a new service in demo app](https://github.com/dongri/OAuthSwift/wiki/Demo-application#add-a-new-service-in-demo-app)

## License

OAuthSwift is available under the MIT license. See the LICENSE file for more info.

[![Join the chat at https://gitter.im/dongri/OAuthSwift](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/dongri/OAuthSwift?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat
            )](http://mit-license.org) [![Platform](http://img.shields.io/badge/platform-iOS_OSX_TVOS-lightgrey.svg?style=flat
             )](https://developer.apple.com/resources/) [![Language](http://img.shields.io/badge/language-swift-orange.svg?style=flat
             )](https://developer.apple.com/swift) [![Cocoapod](http://img.shields.io/cocoapods/v/OAuthSwift.svg?style=flat)](http://cocoadocs.org/docsets/OAuthSwift/)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
