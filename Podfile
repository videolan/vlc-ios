source 'https://cdn.cocoapods.org'
install! 'cocoapods', :deterministic_uuids => false
inhibit_all_warnings!

def ios_specific_pods
  use_modular_headers!
  pod 'GoogleAPIClientForREST/Drive', '~> 1.2.1'
  pod 'GoogleSignIn', '6.2.0'
  pod 'GTMAppAuth', '~> 1.0'
  pod 'ADAL', :git => 'https://code.videolan.org/fkuehne/azure-activedirectory-library-for-objc.git', :commit => '348e94df'
  pod 'OneDriveSDK', :git => 'https://code.videolan.org/fkuehne/onedrive-sdk-ios.git', :commit => '810f82da'
  pod 'ObjectiveDropboxOfficial'
  pod 'box-ios-sdk-v2', :git => 'https://github.com/fkuehne/box-ios-sdk-v2.git', :commit => '08161e74' #has a our fixes
end

target 'VLC-iOS' do
  platform :ios, '12.0'
  ios_specific_pods

  target 'VLC-iOSTests' do
      inherit! :search_paths
  end
end

target 'VLC-iOS-no-watch' do
  platform :ios, '12.0'
  ios_specific_pods
end

post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Read platform of target
      platform = target.platform_name

      # Apply per-platform Build Settings
      case platform
      when :ios
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
        config.build_settings['ARCHS'] = 'arm64 x86_64'
        config.build_settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator'
        config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2' # iPhone and iPad
      end

      # Always set SKIP_INSTALL and other global settings
      config.build_settings['SKIP_INSTALL'] = 'YES'
      config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
    end
  end
end
