
def set_version_number_in_plist(plistPath, version)
  versionNumber = `xcrun /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "#{plistPath}"`
  puts "Next version: #{version}"
  puts "Current version: #{versionNumber}"
  `/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString #{version}" "#{plistPath}"`
end

def increment_build_number_in_plist(plistPath)
  buildNumber = `xcrun /usr/libexec/PlistBuddy -c "Print CFBundleVersion" "#{plistPath}"`
  `/usr/libexec/PlistBuddy -c "Set :CFBundleVersion #{buildNumber.next}" "#{plistPath}"`
end

