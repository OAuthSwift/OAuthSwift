use_frameworks!

target 'OAuthSwiftTests' do
    platform :osx, '10.10'
    pod 'Swifter'
    pod 'Erik'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '2.3'
        end
    end
end
