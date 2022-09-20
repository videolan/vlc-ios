
def set_version_number_in_plist(plist_path, version)
  version_number = `xcrun /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "#{plist_path}"`
  puts "Next version: #{version}"
  puts "Current version: #{version_number}"
  `/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString #{version}" "#{plist_path}"`
end

def increment_build_number_in_plist(plist_path)
  build_number = `xcrun /usr/libexec/PlistBuddy -c "Print CFBundleVersion" "#{plist_path}"`
  `/usr/libexec/PlistBuddy -c "Set :CFBundleVersion #{build_number.next.strip}" "#{plist_path}"`
end
