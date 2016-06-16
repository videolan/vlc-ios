source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!

target 'vlc-ios' do
platform :ios, '7.0'

pod 'OBSlider', '1.1.0'
pod 'InAppSettingsKit', :git => 'git://github.com/fkuehne/InAppSettingsKit.git', :commit => '415ea6bb' #tvOS fix
pod 'upnpx', '~>1.3.6'
pod 'HockeySDK', '~>3.6.4'
pod 'SSKeychain', :git => 'git://github.com/fkuehne/sskeychain.git' #iCloud Keychain sync
pod 'box-ios-sdk-v2', :git => 'git://github.com/fkuehne/box-ios-sdk-v2.git' #has a logout function added
pod 'CocoaHTTPServer', :git => 'git://github.com/fkuehne/CocoaHTTPServer.git' # has our fixes
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

target 'vlc-ios-no-watch' do
platform :ios, '7.0'

pod 'OBSlider', '1.1.0'
pod 'InAppSettingsKit', :git => 'git://github.com/fkuehne/InAppSettingsKit.git', :commit => '415ea6bb' #tvOS fix
pod 'upnpx', '~>1.3.6'
pod 'HockeySDK', '~>3.6.4'
pod 'SSKeychain', :git => 'git://github.com/fkuehne/sskeychain.git' #iCloud Keychain sync
pod 'box-ios-sdk-v2', :git => 'git://github.com/fkuehne/box-ios-sdk-v2.git' #has a logout function added
pod 'CocoaHTTPServer', :git => 'git://github.com/fkuehne/CocoaHTTPServer.git' # has our fixes
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
pod 'SSKeychain', :git => 'git://github.com/fkuehne/sskeychain.git' #iCloud Keychain Sync
pod 'box-ios-sdk-v2', :git => 'git://github.com/fkuehne/box-ios-sdk-v2.git' #has tvOS support added
pod 'upnpx', '~>1.3.6'
pod 'CocoaHTTPServer', :git => 'git://github.com/fkuehne/CocoaHTTPServer.git' # has our fixes
pod 'MetaDataFetcherKit', :git => 'https://code.videolan.org/fkuehne/MetaDataFetcherKit.git', :commit => '81c45087'
pod "OROpenSubtitleDownloader", :git => 'https://github.com/orta/OROpenSubtitleDownloader.git', :commit => '0509eac2'
end
