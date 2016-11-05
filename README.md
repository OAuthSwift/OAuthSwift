<p align="center">
  <img src="Assets/OAuthSwift-icon.png?raw=true" alt="OAuthSwift"/>
</p>

# OAuthSwift

Swift based OAuth library for iOS and OSX.

## Support OAuth1.0, OAuth2.0

Twitter, Flickr, Github, Instagram, Foursquare. Fitbit, Withings, Linkedin, Dropbox, Dribbble, Salesforce, BitBucket, GoogleDrive, Smugmug, Intuit, Zaim, Tumblr, Slack, Uber, Gitter, Facebook, Spotify, Typetalk, SoundCloud, etc

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
github "OAuthSwift/OAuthSwift" ~> 1.1.0
```
* Run `carthage update`.
* On your application targets’ “General” settings tab, in the “Embedded Binaries” section, drag and drop OAuthSwift.framework from the Carthage/Build/iOS folder on disk.

### Support CocoaPods

* Podfile

```
platform :ios, '8.0'
use_frameworks!

pod 'OAuthSwift', '~> 1.1.0'
```
## How to
### Setting URL Schemes
In info tab of your target
![Image](Assets/URLSchemes.png "Image")
Replace oauth-swift by your application name

### Handle URL in AppDelegate
- On iOS9 implement `UIApplicationDelegate` method
```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
  if (url.host == "oauth-callback") {
    OAuthSwift.handle(url: url)
  }
  return true
}
```
:warning: Any other application may try to open a URL with your url scheme. So you can check the source application, for instance for safari controller :
```
if (options["UIApplicationOpenURLOptionsSourceApplicationKey"] as? String == "com.apple.SafariViewService") {
```

- On previous iOS version
```swift
func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
```
- On OSX you must register an handler on `NSAppleEventManager` for event type `kAEGetURL` (see demo code)
```swift
func applicationDidFinishLaunching(_ aNotification: NSNotification) {
    NSAppleEventManager.shared().setEventHandler(self, andSelector:#selector(AppDelegate.handleGetURL(event:withReplyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
}
func handleGetURL(event: NSAppleEventDescriptor!, withReplyEvent: NSAppleEventDescriptor!) {
    if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue, let url = URL(string: urlString) {
        OAuthSwift.handle(url: url)
    }
}
```

### Authorize with OAuth1.0
```swift
// create an instance and retain it
oauthswift = OAuth1Swift(
    consumerKey:    "********",
    consumerSecret: "********",
    requestTokenUrl: "https://api.twitter.com/oauth/request_token",
    authorizeUrl:    "https://api.twitter.com/oauth/authorize",
    accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
)
let handle = oauthswift.authorize(
    withCallbackURL: URL(string: "oauth-swift://oauth-callback/twitter")!,
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
### Authorize with OAuth2.0
```swift
oauthswift = OAuth2Swift(
    consumerKey:    "********",
    consumerSecret: "********",
    authorizeUrl:   "https://api.instagram.com/oauth/authorize",
    responseType:   "token"
)
let handle = oauthswift.authorize(
    withCallbackURL: URL(string: "oauth-swift://oauth-callback/instagram")!,
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
The authorize URL allows the user to connect to a provider and give access to your application.

By default this URL is opened into the external web browser (ie. safari), but apple does not allow it for app-store iOS applications.

To change this behavior you must set an `OAuthSwiftURLHandlerType`, simple protocol to handle an `URL`
```swift
oauthswift.authorizeURLHandler = ..
```
For instance you can embed a web view into your application by providing a controller that displays a web view (`UIWebView`, `WKWebView`).
Then this controller must implement `OAuthSwiftURLHandlerType` to load the URL into the web view
```swift
func handle(_ url: NSURL) {
  let req = URLRequest(URL: targetURL)
  self.webView.loadRequest(req)
  ...
```
and present the view (`present(viewController`, `performSegue(withIdentifier: `, ...)
*You can extends `OAuthWebViewController` for a default implementation of view presentation and dismiss*

#### Use the SFSafariViewController (iOS9)
A default implementation of `OAuthSwiftURLHandlerType` is provided using the `SFSafariViewController`, with automatic view dismiss.
```swift
oauthswift.authorizeURLHandler = SafariURLHandler(viewController: self, oauthSwift: oauthswift)
```
Of course you can create your own class or customize the controller by setting the variable `SafariURLHandler#factory`.

### Make signed request

```swift
oauthswift.client.get("https://api.linkedin.com/v1/people/~",
      success: { response in
        let dataString = response.string
        print(dataString)
      },
      failure: { error in
        print(error)
      }
)
// same with request method
oauthswift.client.request("https://api.linkedin.com/v1/people/~", .GET,
      parameters: [:], headers: [:],
      success: { ...
```

See more examples in the demo application: [ViewController.swift](/Demo/Common/ViewController.swift)

## OAuth provider pages

* [Twitter](https://dev.twitter.com/oauth)  
* [Flickr](https://www.flickr.com/services/api/auth.oauth.html)  
* [Github](https://developer.github.com/v3/oauth/)  
* [Instagram](http://instagram.com/developer/authentication)  
* [Foursquare](https://developer.foursquare.com/overview/auth)  
* [Fitbit](https://wiki.fitbit.com/display/API/OAuth+Authentication+in+the+Fitbit+API)  
* [Withings](http://oauth.withings.com/api)  
* [Linkedin](https://developer.linkedin.com/docs/oauth2)  
* [Dropbox](https://www.dropbox.com/developers/core/docs)  
* [Dribbble](http://developer.dribbble.com/v1/oauth/)
* [Salesforce](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/)
* [BitBucket](https://confluence.atlassian.com/display/BITBUCKET/OAuth+on+Bitbucket)
* [GoogleDrive](https://developers.google.com/drive/v2/reference/)
* [Smugmug](https://smugmug.atlassian.net/wiki/display/API/OAuth)
* [Intuit](https://developer.intuit.com/docs/0100_accounting/0060_authentication_and_authorization/oauth_management_api)
* [Zaim](https://dev.zaim.net/home/api/authorize)
* [Tumblr](https://www.tumblr.com/docs/en/api/v2#auth)
* [Slack](https://api.slack.com/docs/oauth)
* [Uber](https://developer.uber.com/docs/ride-requests/guides/authentication/introduction#oauth-20)
* [Gitter](https://developer.gitter.im/docs/authentication)
* [Facebook](https://developers.facebook.com/docs/facebook-login)
* [Spotify](https://developer.spotify.com/web-api/authorization-guide/)
* [Trello](https://developers.trello.com/authorize)
* [Buffer](https://buffer.com/developers/api/oauth)
* [Goodreads](https://www.goodreads.com/api/documentation#oauth)
* [Typetalk](http://developer.nulab-inc.com/docs/typetalk/auth)
* [SoundCloud](https://developers.soundcloud.com/docs/api/guide#authentication)

## Images

![Image](Assets/Services.png "Image")
![Image](Assets/TwitterOAuth.png "Image")
![Image](Assets/TwitterOAuthTokens.png "Image")

## Contributing
 See [CONTRIBUTING.md](.github/CONTRIBUTING.md)

[Add a new service in demo app](https://github.com/OAuthSwift/OAuthSwift/wiki/Demo-application#add-a-new-service-in-demo-app)


## Integration
OAuthSwift could be used with others frameworks

You can sign [Alamofire](https://github.com/Alamofire/Alamofire) request with [OAuthSwiftAlamofire](https://github.com/OAuthSwift/OAuthSwiftAlamofire)

To achieve great asynchronous code you can use one of this integration frameworks
- [OAuthSwiftFutures](https://github.com/OAuthSwift/OAuthSwiftFutures) - [BrightFutures](https://github.com/Thomvis/BrightFutures)
- [OAuthRxSwift](https://github.com/OAuthSwift/OAuthRxSwift) - [RxSwift](https://github.com/ReactiveX/RxSwift)
- [OAuthReactiveSwift](https://github.com/OAuthSwift/OAuthReactiveSwift) - [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift)

## License

OAuthSwift is available under the MIT license. See the LICENSE file for more info.

[![Join the chat at https://gitter.im/OAuthSwift/OAuthSwift](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/OAuthSwift/OAuthSwift?utm_campaign=pr-badge&utm_content=badge&utm_medium=badge&utm_source=badge)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat
            )](http://mit-license.org) [![Platform](https://img.shields.io/badge/platform-iOS_OSX_TVOS-lightgrey.svg?style=flat
             )](https://developer.apple.com/resources/) [![Language](https://img.shields.io/badge/language-swift-orange.svg?style=flat
             )](https://developer.apple.com/swift) [![Cocoapod](https://img.shields.io/cocoapods/v/OAuthSwift.svg?style=flat)](http://cocoadocs.org/docsets/OAuthSwift/)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
