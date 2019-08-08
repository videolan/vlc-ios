source 'https://github.com/CocoaPods/Specs.git'
install! 'cocoapods', :deterministic_uuids => false
inhibit_all_warnings!

def shared_pods
  pod 'XKKeychain', '~>1.0'
  pod 'box-ios-sdk-v2', :git => 'git://github.com/fkuehne/box-ios-sdk-v2.git' #has a logout function added
  pod 'upnpx', '~>1.4.0'
  pod 'CocoaHTTPServer', :git => 'git://github.com/fkuehne/CocoaHTTPServer.git' # has our fixes
  pod 'VLC-WhiteRaccoon'
  pod 'ObjectiveDropboxOfficial', :git => 'git://github.com/Mikanbu/dropbox-sdk-obj-c.git' #update ios platform version

  # debug
  pod 'SwiftLint', '~> 0.25.0', :configurations => ['Debug']
end

target 'VLC-iOS' do
  platform :ios, '9.0'
  shared_pods
  pod 'OBSlider', '1.1.0'
  pod 'InAppSettingsKit', :git => 'git://github.com/fkuehne/InAppSettingsKit.git', :commit => '415ea6bb' #tvOS fix
  pod 'HockeySDK', '~>5.1.4', :subspecs => ['CrashOnlyLib']
  pod 'PAPasscode', '~>1.0'
  pod 'GoogleAPIClientForREST/Drive'
  pod 'MobileVLCKit', '3.3.3'
  pod 'VLCMediaLibraryKit', '0.4.0'
  pod 'MediaLibraryKit-prod'
  pod 'GTMAppAuth', '0.7.1'
  pod 'OneDriveSDK'

  target 'VLC-iOS-Screenshots' do
    inherit! :search_paths
    pod 'SimulatorStatusMagic'
  end
  target 'VLC-iOSTests' do
      inherit! :search_paths
  end
end

target 'VLC-tvOS' do
  platform :tvos, '10.2'
  shared_pods
  pod 'MetaDataFetcherKit', '~>0.3.1'
  pod "OROpenSubtitleDownloader", :git => 'https://github.com/orta/OROpenSubtitleDownloader.git', :commit => '0509eac2'
  pod 'GRKArrayDiff', '~> 2.1'
  pod 'HockeySDK-tvOS', '~>5.1.0'
  pod 'TVVLCKit', '3.3.3'
end

post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
     installer_representation.pods_project.build_configurations.each do |config|
       config.build_settings['SKIP_INSTALL'] = 'YES'
       config.build_settings['VALID_ARCHS'] = 'armv7 armv7s arm64 i386 x86_64'
       config.build_settings['ARCHS'] = 'armv7 armv7s arm64 i386 x86_64'
       config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
     end
  end
end
