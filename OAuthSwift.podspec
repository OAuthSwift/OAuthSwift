Pod::Spec.new do |s|
  s.name = 'OAuthSwift'
  s.version = '0.5.1'
  s.license = 'MIT'
  s.summary = 'Swift based OAuth library for iOS and OSX.'
  s.homepage = 'https://github.com/OAuthSwift/OAuthSwift'
  s.social_media_url = 'http://twitter.com/dongriat'
  s.authors = { 'Dongri Jin' => 'dongriat@gmail.com' }
  s.source = { :git => 'https://github.com/OAuthSwift/OAuthSwift.git', :tag => s.version }
  s.source_files = 'OAuthSwift/*.swift'
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  s.requires_arc = false
end
