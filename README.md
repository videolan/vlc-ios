# VLC iOS

The best open source player ported to iOS!

This repository has the source code of the iOS/AppleTV application and mostly the interface.

It's currently written in Obj-C and uses libVLC for the playback.

It's completely open source.

# How to start development for VLC for iOS:

## Requirements
* Xcode 7.0 or later
* OS X 10.10 or later
* Command Line Tools package: https://developer.apple.com/downloads/
* Cocoapods 1.0 or later

## Let's compile!
1. Run ```pod update```
2. Open `VLC.xcworkspace`.
3. Change `BUNDLE_IDENTIFIER_PREFIX` in `SharedConfig.xcconfig` to your domain name in reverse DNS style.
4. Hit "Build and Run".

## Compile with your own VLCKit build
1. Clone a VLCKit repository: `git clone https://code.videolan.org/videolan/VLCKit.git`
2. Inside the VLCKit folder, run the following command: `./buildMobileVLCKit.sh -a ${MYARCH}`

    MYARCH can be `i386` `x86_64` `armv7` `armv7s` or `aarch64`.

    Add `-d` for a debug build (to have valid stack straces and asserts).

    Add `-n` if you want to use you own VLC repository for VLCKit (See VLCKit README.md).

3. Replace the MobileVLCKit.framework with the one you just build.

    Inside your vlc-ios folder, after a `podate update`, do:

    `cd Pods/MobileVLCKit-unstable/MobileVLCKit-binary`

    `rm -rf MobileVLCKit.framework`

    `ln -s ${VLCKit}/build/MobileVLCKit.framework`

4. Hit "Build and Run".

## Errors you might encounter on the way

### Build errors in Xcode

Are you sure you opened the workspace? 
We use cocoapods and it creates a workspace with all the integrated libraries. 
Chances are you opened the project file. 

If you have opened the workspace and still get errors you should check out the Notes section

## Submitting A Patch

So you added some code and are ready to contribute your commits but you don't see a way to make a pull request?
Soo *cough* we work with patches and Mailinglists like any good open source project! 

You should take a look at this: https://wiki.videolan.org/Sending_Patches_VLC/ but finally send the patch to ios@videolan.org.

Also, if you haven't yet, you might want to subscribe to this mailinglist: https://mailman.videolan.org/listinfo/ios

## Release

The process of releasing new builds of VLC to iTunes Connect is automated with fastlane.

To release a new version of VLC for iOS, run the following command:
```
bundle exec fastlane release platform:iOS version:3.1.0
```

To release a new version of VLC for tvOS, run the following command:
```
bundle exec fastlane release platform:tvOS version:3.1.0
```

Please find further information about this process in [fastlane/README.md](./fastlane/README.md)

## Notes

For everything else, check: https://wiki.videolan.org/IOSCompile/
or look here: http://www.videolan.org/support/
For fast replies, IRC is probably the best way. We hang out in the #videolan channel on the freenode network. There is also a web interface: http://webchat.freenode.net/

We're happy to help!

