#!/usr/bin/ruby

class VLC
  def self.info_plist_path
    {
      iOS: '../Sources/VLC for iOS-Info.plist',
      tvOS: '../Apple-TV/Info.plist',
      watchKitExtension: '../VLC WatchKit Native Extension/Info.plist',
      watchOS: '../VLC WatchKit Native/Info.plist'
    }
  end
end
