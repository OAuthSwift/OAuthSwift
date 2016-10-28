Pod::Spec.new do |s|
  s.name = 'OAuthSwift'
  s.version = '1.0.0p1'
  s.license = 'MIT'
  s.summary = 'Swift based OAuth library for iOS and OSX.'
  s.homepage = 'https://github.com/p7s1-ctf/OAuthSwift'
  s.social_media_url = 'http://twitter.com/dongrify'
  s.authors = {
    'Dongri Jin' => 'dongrify@gmail.com',
    'Eric Marchand' => 'eric.marchand.n7@gmail.com'
  }
  s.source = { git: 'https://github.com/p7s1-ctf/OAuthSwift.git', tag: s.version }
  s.source_files = 'Sources/*.swift'
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  s.requires_arc = false
end
