Pod::Spec.new do |s|
  s.name = 'OAuthSwift'
  s.version = '2.1.0'
  s.license = 'MIT'
  s.summary = 'Swift based OAuth library for iOS and macOS.'
  s.homepage = 'https://github.com/OAuthSwift/OAuthSwift'
  s.social_media_url = 'http://twitter.com/dongrify'
  s.authors = {
    'Dongri Jin' => 'dongrify@gmail.com',
    'Eric Marchand' => 'eric.marchand.n7@gmail.com'
  }
  s.source = { git: 'https://github.com/OAuthSwift/OAuthSwift.git', tag: s.version }
  s.source_files = 'Sources/**/*.swift'
  s.swift_versions = ['5.0', '5.1']
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '3.0'
  s.requires_arc = false
end
