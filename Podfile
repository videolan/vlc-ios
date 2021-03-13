source 'https://cdn.cocoapods.org'
install! 'cocoapods', :deterministic_uuids => false
inhibit_all_warnings!

def shared_pods
  pod 'XKKeychain', '~>1.0'
  pod 'box-ios-sdk-v2', :git => 'git://github.com/fkuehne/box-ios-sdk-v2.git', :commit => 'fe0fbb20' #has a our fixes
  pod 'CocoaHTTPServer', :git => 'git://github.com/fkuehne/CocoaHTTPServer.git' # has our fixes
  pod 'ObjectiveDropboxOfficial', :git => 'git://github.com/Mikanbu/dropbox-sdk-obj-c.git' #update ios platform version
  pod 'xmlrpc', :git => 'git://github.com/fkuehne/xmlrpc.git', :commit => '3f8ce3a8' #fix case-sensitive FS
  pod 'AFNetworking', '~>4.0'

  pod 'AppCenter', '2.3.0'
  # debug
  pod 'SwiftLint', '~> 0.25.0', :configurations => ['Debug']
end

target 'VLC-iOS' do
  platform :ios, '9.0'
  shared_pods
  pod 'OBSlider', '1.1.0'
  pod 'InAppSettingsKit', :git => 'git://github.com/Mikanbu/InAppSettingsKit.git', :commit => 'a429840' #tvOS fix
  pod 'GoogleAPIClientForREST/Drive'
  pod 'MobileVLCKit', '3.3.16.3'
  pod 'VLCMediaLibraryKit', '0.7.3'
  pod 'MediaLibraryKit-prod'
  pod 'GTMAppAuth', '0.7.1'
  pod 'ADAL', :git => 'https://code.videolan.org/fkuehne/azure-activedirectory-library-for-objc.git', :commit => '348e94df'
  pod 'OneDriveSDK', :git => 'https://code.videolan.org/fkuehne/onedrive-sdk-ios.git', :commit => '810f82da'
  pod 'MarqueeLabel', '4.0.2'

  target 'VLC-iOS-Screenshots' do
    inherit! :search_paths
    pod 'SimulatorStatusMagic'
  end
  target 'VLC-iOSTests' do
      inherit! :search_paths
  end
end

target 'VLC-tvOS' do
  platform :tvos, '11.0'
  shared_pods
  pod 'GRKArrayDiff', '~> 2.1'
  pod 'TVVLCKit', '3.3.16'
  pod 'MetaDataFetcherKit', '~>0.5.0'
end

post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
     installer_representation.pods_project.build_configurations.each do |config|
       config.build_settings['SKIP_INSTALL'] = 'YES'
       config.build_settings['ARCHS'] = 'armv7 armv7s arm64 i386 x86_64'
       config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
     end
    target.build_configurations.each do |config|
        xcconfig_path = config.base_configuration_reference.real_path
        xcconfig = File.read(xcconfig_path)
        new_xcconfig = xcconfig.sub('-l"sqlite3"', '')
        File.open(xcconfig_path, "w") { |file| file << new_xcconfig }
    end
  end
end
