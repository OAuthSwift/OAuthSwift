Pod::Spec.new do |s|
  s.name = 'SGOAuthSwift'
  s.version = '0.5.2'
  s.license = 'MIT'
  s.summary = 'Swift based OAuth library for iOS and OSX.'
  s.homepage = 'https://github.com/skedgo/OAuthSwift'
  s.social_media_url = 'http://twitter.com/dongrify'
  s.authors = { 'Dongri Jin' => 'dongrify@gmail.com' }
  s.source = { git: 'https://github.com/skedgo/OAuthSwift.git', branch: 'master' }
  s.source_files = 'OAuthSwift/*.swift'
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  s.requires_arc = false
end
