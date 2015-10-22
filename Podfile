source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!

target 'vlc-ios' do
platform :ios, '7.0'

pod 'OBSlider', '1.1.0'
pod 'InAppSettingsKit', '2.2.2'
pod 'upnpx', '~>1.3.4'
pod 'HockeySDK', '~>3.6.4'
pod 'SSKeychain', '~>1.2.2'
pod 'box-ios-sdk-v2', :git => 'git://github.com/carolanitz/box-ios-sdk-v2.git', :commit => 'd2df30aa5f76d30910e06f3ef5aff49025de3cf1' #has a logout function added
pod 'RESideMenu', '~>4.0.7'

end
post_install do |installer_representation|
  installer_representation.pods_project.build_configurations.each do |config|
            config.build_settings['SKIP_INSTALL'] = 'YES'
            config.build_settings['VALID_ARCHS'] = 'armv7 armv7s arm64'
            config.build_settings['ARCHS'] = 'armv7 armv7s arm64'
            config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
  end
end

target 'VLC-TV' do
platform :tvos, '9.0'
pod 'SSKeychain', '~>1.2.2'

end
