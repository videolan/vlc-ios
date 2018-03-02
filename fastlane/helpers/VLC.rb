#!/usr/bin/ruby

class VLC
  def self.infoPlistPath
    return {
      iOS: '../Sources/VLC for iOS-Info.plist',
      tvOS: '../Apple-TV/Info.plist',
      watchKitExtension: '../VLC WatchKit Native Extension/Info.plist',
      watchOS: '../VLC WatchKit Native/Info.plist'
    }
  end
end
