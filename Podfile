use_frameworks!

target 'OAuthSwiftTests' do
    platform :osx, '10.10'
    
    # TODO: Switch these back to just the (main) pod, once they are using Swift 3.0 by default
    
    # TODO: PR: https://github.com/httpswift/swifter/pull/186
    pod 'Swifter',  branch: 'swift3',   git: 'https://github.com/mhmiles/swifter.git'
    
    pod 'Erik',     branch: 'swift3.0', git: 'https://github.com/phimage/Erik.git'
    
    # Swift 3.0 versions of Erik's dependencies. TODO: Remove once the latest pod is using Swift 3.0
    pod 'Kanna',    branch: 'swift3.0', git: 'https://github.com/tid-kijyun/Kanna.git'
end

# Temporary fix for Xcode 8 beta
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.10'
    end
  end
end
