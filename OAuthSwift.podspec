#
# Be sure to run `pod lib lint cocoa.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "OAuthSwift"
  s.version          = "0.1.0"
  s.summary          = "Swift based OAuth library for iOS."
  s.description      = <<-DESC
                       * Swift based OAuth library for iOS.
                       DESC
  s.homepage         = "https://github.com/dongri/OAuthSwift"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Dongri Jin" => "dongriat@gmail.com" }
  s.source           = { :git => "https://github.com/dongri/OAuthSwift.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/dongriat'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'OAuthSwift' => ['Pod/Assets/*.png']
  }

  s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
