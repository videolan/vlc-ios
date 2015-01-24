# Uncomment this line to define a global platform for your project
# platform :ios, '6.0'

source 'https://github.com/CocoaPods/Specs.git'

target 'vlc-ios' do

pod 'OBSlider', '1.1.0'
pod 'QuincyKit', :git => 'https://github.com/carolanitz/QuincyKit.git'
pod 'PLCrashReporter', '1.2-rc5'
pod 'GHSidebarNav', '1.0.0'
pod 'InAppSettingsKit', '2.2.2'
pod 'upnpx', '1.3.1'

end
post_install do |installer_representation|
  installer_representation.project.build_configurations.each do |config|
            config.build_settings['SKIP_INSTALL'] = 'YES'
  end
end
