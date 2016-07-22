source 'https://github.com/CocoaPods/Specs.git'

install! 'cocoapods', :deterministic_uuids => false

inhibit_all_warnings!

target 'VLC-iOS' do
platform :ios, '7.0'

pod 'OBSlider', '1.1.0'
pod 'InAppSettingsKit', :git => 'git://github.com/fkuehne/InAppSettingsKit.git', :commit => '415ea6bb' #tvOS fix
pod 'upnpx', '~>1.4.0a2'
pod 'HockeySDK', '~>3.6.4'
pod 'XKKeychain', '~>1.0'
pod 'box-ios-sdk-v2', :git => 'git://github.com/fkuehne/box-ios-sdk-v2.git' #has a logout function added
pod 'CocoaHTTPServer', :git => 'git://github.com/fkuehne/CocoaHTTPServer.git' # has our fixes
pod 'RESideMenu', '~>4.0.7'
pod 'GoogleAPIClient/Drive'
pod 'GTMOAuth2'
pod 'VLC-LXReorderableCollectionViewFlowLayout', '0.1.3v'
pod 'VLC-WhiteRaccoon'
pod 'VLC-LiveSDK', '5.7.0x'
pod 'VLC-Dropbox-v1-SDK', '1.3.14w'
pod 'MediaLibraryKit-unstable'
pod 'MobileVLCKit-unstable', '3.0.0a8'

end
post_install do |installer_representation|
  installer_representation.pods_project.build_configurations.each do |config|
            config.build_settings['SKIP_INSTALL'] = 'YES'
            config.build_settings['VALID_ARCHS'] = 'armv7 armv7s arm64'
            config.build_settings['ARCHS'] = 'armv7 armv7s arm64'
            config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
  end
end

target 'VLC-iOS-no-watch' do
platform :ios, '7.0'

pod 'OBSlider', '1.1.0'
pod 'InAppSettingsKit', :git => 'git://github.com/fkuehne/InAppSettingsKit.git', :commit => '415ea6bb' #tvOS fix
pod 'upnpx', '~>1.4.0a2'
pod 'HockeySDK', '~>3.6.4'
pod 'XKKeychain', '~>1.0'
pod 'box-ios-sdk-v2', :git => 'git://github.com/fkuehne/box-ios-sdk-v2.git' #has a logout function added
pod 'CocoaHTTPServer', :git => 'git://github.com/fkuehne/CocoaHTTPServer.git' # has our fixes
pod 'RESideMenu', '~>4.0.7'
pod 'GoogleAPIClient/Drive'
pod 'GTMOAuth2'
pod 'VLC-LXReorderableCollectionViewFlowLayout', '0.1.3v'
pod 'VLC-WhiteRaccoon'
pod 'VLC-LiveSDK', '5.7.0x'
pod 'VLC-Dropbox-v1-SDK', '1.3.14w'
pod 'MediaLibraryKit-unstable'
pod 'MobileVLCKit-unstable', '3.0.0a8'

end
post_install do |installer_representation|
  installer_representation.pods_project.build_configurations.each do |config|
            config.build_settings['SKIP_INSTALL'] = 'YES'
            config.build_settings['VALID_ARCHS'] = 'armv7 armv7s arm64'
            config.build_settings['ARCHS'] = 'armv7 armv7s arm64'
            config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
  end
end

target 'VLC-iOS-no-watch-Debug' do
platform :ios, '7.0'

pod 'OBSlider', '1.1.0'
pod 'InAppSettingsKit', :git => 'git://github.com/fkuehne/InAppSettingsKit.git', :commit => '415ea6bb' #tvOS fix
pod 'upnpx', '~>1.4.0a2'
pod 'HockeySDK', '~>3.6.4'
pod 'XKKeychain', '~>1.0'
pod 'box-ios-sdk-v2', :git => 'git://github.com/fkuehne/box-ios-sdk-v2.git' #has a logout function added
pod 'CocoaHTTPServer', :git => 'git://github.com/fkuehne/CocoaHTTPServer.git' # has our fixes
pod 'RESideMenu', '~>4.0.7'
pod 'GoogleAPIClient/Drive'
pod 'GTMOAuth2'
pod 'VLC-LXReorderableCollectionViewFlowLayout', '0.1.3v'
pod 'VLC-WhiteRaccoon'
pod 'VLC-LiveSDK', '5.7.0x'
pod 'VLC-Dropbox-v1-SDK', '1.3.14w'

end
post_install do |installer_representation|
  installer_representation.pods_project.build_configurations.each do |config|
            config.build_settings['SKIP_INSTALL'] = 'YES'
            config.build_settings['VALID_ARCHS'] = 'armv7 armv7s arm64'
            config.build_settings['ARCHS'] = 'armv7 armv7s arm64'
            config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
  end
end

target 'VLC-tvOS' do
platform :tvos, '9.0'
pod 'XKKeychain', '~>1.0'
pod 'box-ios-sdk-v2', :git => 'git://github.com/fkuehne/box-ios-sdk-v2.git' #has tvOS support added
pod 'upnpx', '~>1.4.0a2'
pod 'CocoaHTTPServer', :git => 'git://github.com/fkuehne/CocoaHTTPServer.git' # has our fixes
pod 'MetaDataFetcherKit', '~>0.1.8'
pod "OROpenSubtitleDownloader", :git => 'https://github.com/orta/OROpenSubtitleDownloader.git', :commit => '0509eac2'
pod 'GRKArrayDiff', '~> 2.1'
pod 'VLC-WhiteRaccoon'
pod 'VLC-LiveSDK', '5.7.0x'
pod 'VLC-Dropbox-v1-SDK', '1.3.14w'
pod 'HockeySDK-tvOS', '4.1.0-beta.1'
pod 'TVVLCKit-unstable', '3.0.0a10'

end

target 'VLC-tvOS-Debug' do
platform :tvos, '9.0'
pod 'XKKeychain', '~>1.0'
pod 'box-ios-sdk-v2', :git => 'git://github.com/fkuehne/box-ios-sdk-v2.git' #has tvOS support added
pod 'upnpx', '~>1.4.0a2'
pod 'CocoaHTTPServer', :git => 'git://github.com/fkuehne/CocoaHTTPServer.git' # has our fixes
pod 'MetaDataFetcherKit', '~>0.1.8'
pod "OROpenSubtitleDownloader", :git => 'https://github.com/orta/OROpenSubtitleDownloader.git', :commit => '0509eac2'
pod 'GRKArrayDiff', '~> 2.1'
pod 'VLC-WhiteRaccoon'
pod 'VLC-LiveSDK', '5.7.0x'
pod 'VLC-Dropbox-v1-SDK', '1.3.14w'
pod 'HockeySDK-tvOS', '4.1.0-beta.1'

end

target 'VLC-watchOS-Extension' do
platform :watchos, '2.0'

pod 'MediaLibraryKit-unstable'

end
post_install do |installer_representation|
  installer_representation.pods_project.build_configurations.each do |config|
            config.build_settings['SKIP_INSTALL'] = 'YES'
            config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
  end
end
