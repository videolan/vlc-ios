# VLC for iOS & tvOS

This repository has the source code of VLC for iOS and tvOS application.

It's currently written in Objective-C / Swift and uses VLCKit a libvlc wrapper.

- [Requirements](#requirements)
- [Building](#building)
    - [VLC-iOS](#vlc-ios)
    - [Custom VLCKit](#custom-vlckit)
- [Contribute](#contribute)
- [Communication](#communication)
    - [Forum](#forum)
    - [Issues](#issues)
    - [IRC](#irc)
- [License](#license)
- [More](#more)

## Requirements
* Xcode 9.0+
* macOS 10.12+
* Cocoapods 1.4+

## Building

### VLC-iOS

1. Run `pod update`
2. Open `VLC.xcworkspace`.
3. Hit "Build and Run".

### Custom VLCkit

Mostly for debugging or advanced users, you might want to have a custom local VLCKit build.

1. Clone VLCKit:

    `git clone https://code.videolan.org/videolan/VLCKit.git`

2. Inside the VLCKit folder, run the following command:

    `./buildMobileVLCKit.sh -a ${MYARCH}`

    MYARCH can be `i386` `x86_64` `armv7` `armv7s` or `aarch64`.

    Add `-d` for a debug build (to have valid stack straces and asserts).

    Add `-n` if you want to use you own VLC repository for VLCKit (See VLCKit README.md).

3. Replace the MobileVLCKit.framework with the one you just build.

    Inside your vlc-ios folder, after a `podate update`, do:

    `cd Pods/MobileVLCKit-unstable/MobileVLCKit-binary`

    `rm -rf MobileVLCKit.framework`

    `ln -s ${VLCKit}/build/MobileVLCKit.framework`

4. Hit "Build and Run.

## Contribute

### Pull request

If you want to submit a pull request, please make sure to use a descriptive title and description.

### Gitlab issues

You can look through issues we currently have on the [VideoLAN Gitlab](https://code.videolan.org/videolan/vlc-ios/issues).

We even have a [Beginner friendly](https://code.videolan.org/videolan/vlc-ios/issues?label_name%5B%5D=Beginner+friendly) tag if you don't know were to start!

## Communication

### Forum

If you have any question or you're not sure it's an issue please visit our [forum](https://forum.videolan.org/).

### Issues

You have encountered an issue and wish to report it to the VLC dev team?

You can create an issue on our [Gitlab](https://code.videolan.org/videolan/vlc-ios/issues) or on our [bug tracker](https://trac.videolan.org/vlc/).

Before creating an issue or ticket, please double check of duplicates!

### IRC

Want to quickly get in touch with us for a question, or even just to talk?

You will alawys find someone of the VLC team on IRC, __#videolan__ channel on the freenode network.
If you don't have an IRC client, you can always use the [freenode webchat](https://webchat.freenode.net/).

## License

VLC-iOS is under the GPLv2 (or later) and the MPLv2 license.

See [COPYING](./COPYING) for more license info.

## More

For everything else, check: https://wiki.videolan.org/
or look here: http://www.videolan.org/support/

We're happy to help!

