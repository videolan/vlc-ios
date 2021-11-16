<h3 align="center">
  <a href="https://www.videolan.org/images/vlc-ios/readme_banner.png">
  <img src="https://www.videolan.org/images/vlc-ios/readme_banner.png?raw=true" alt="VLC-iOS banner">
  </a>
</h3>

This is the official mirror repository of VLC for iOS and tvOS application.

_You can find the official repository [here](https://code.videolan.org/videolan/vlc-ios/)._

It's currently written in Objective-C / Swift and uses [VLCKit](https://code.videolan.org/videolan/VLCKit), a libvlc wrapper.

- [Requirements](#requirements)
- [Building](#building)
  - [VLC-iOS](#vlc-ios)
  - [Custom VLCKit](#custom-vlckit)
  - [Beginner's Guide](#beginners-guide)
- [Contribute](#contribute)
  - [Pull request](#pull-request)
  - [Commit](#commit)
  - [Gitlab issues](#gitlab-issues)
- [Communication](#communication)
  - [Forum](#forum)
  - [Issues](#issues)
  - [IRC](#irc)
- [Code of Conduct](#code-of-conduct)
- [License](#license)
- [More](#more)

## Requirements
* Xcode 11.0+
* macOS 10.12+
* Cocoapods 1.4+

## Building

### VLC-iOS

1. Clone VLC-iOS:

    `git clone https://code.videolan.org/videolan/vlc-ios.git`

2. Run the command `[sudo] gem install cocoapods` (and then `[sudo] arch -x86_64 gem install ffi` on Apple Silicon devices).    
3. Run `pod install` (or `arch -x86_64 pod install` on Apple Silicon devices).
4. Open `VLC.xcworkspace`.
5. Hit "Build and Run".


### Custom VLCKit

Mostly for debugging or advanced users, you might want to have a custom local VLCKit build.

1. Clone VLCKit:

    `git clone https://code.videolan.org/videolan/VLCKit.git`


2. Inside the VLCKit folder, run the following command:

    `./compileAndBuildVLCKit.sh -a ${MYARCH}`

    MYARCH can be `i386` `x86_64` `armv7` `armv7s` or `aarch64`.

    Add `-d` for a debug build (to have valid stack straces and asserts).

    Add `-n` if you want to use you own VLC repository for VLCKit (See [VLCKit README.md](https://code.videolan.org/videolan/VLCKit/blob/master/README.md)).

3. Replace the MobileVLCKit.framework with the one you just built.

    Inside your vlc-ios folder, after a `pod update`, do:

    `cd Pods/MobileVLCKit`

    `rm -rf MobileVLCKit.framework`

    `ln -s ${VLCKit}/build/MobileVLCKit.framework`

4. Hit "Build and Run".

### Beginner's Guide

Can't get your project to build or run? Head over to the [beginner's guide](https://code.videolan.org/videolan/vlc-ios/wikis/Beginner-Guide) for help on common issues beginners tend to run into.

If you can't find your problem on the guide, please feel free to [submit an issue](https://code.videolan.org/videolan/vlc-ios/issues).

## Contribute

### Pull request

Pull request are more than welcome! If you do submit one, please make sure to use a descriptive title and description.

### Commit

We try to follow a simple set of rules, outlined by this [guide](https://chris.beams.io/posts/git-commit/).

Additionally, commit messages should have all the information needed to understand the commit easily as the following:

```
    Subject: Brief description

    Description in detail if needed.

    ticket related action
```

For example:

```
    UPnP: Remove iOS 7 compatibility code

    Closes #166
```

### Gitlab issues

You can look through issues we currently have on the [VideoLAN GitLab](https://code.videolan.org/videolan/vlc-ios/issues).

A [beginner friendly](https://code.videolan.org/videolan/vlc-ios/issues?label_name%5B%5D=Beginner+friendly) tag is available if you don't know where to start.

## Communication

### Forum

If you have any question or if you're not sure it's actually an issue, please visit our [forum](https://forum.videolan.org/).

### Issues

You have encountered an issue and wish to report it to the VLC dev team?

You can create one on our [GitLab](https://code.videolan.org/videolan/vlc-ios/issues) or on our [bug tracker](https://trac.videolan.org/vlc/).

Before creating an issue or ticket, please double check for duplicates!

### IRC

Want to quickly get in touch with us for a question, or even just to talk?

You will always find someone from the VLC team on IRC, __#videolan__ channel on the freenode network.

For VLC-iOS specific questions, you can find us on __#vlc-ios__.

If you don't have an IRC client, you can always use the [freenode webchat](https://webchat.freenode.net/).

## Code of Conduct

Please read and follow the [VideoLAN CoC](https://wiki.videolan.org/Code_of_Conduct/).

## License

VLC-iOS is under the GPLv2 (or later) and the MPLv2 license.

See [COPYING](./COPYING) for more license info.

## More

For everything else, check our [wiki](https://wiki.videolan.org/) or our [support page](http://www.videolan.org/support/).

We're happy to help!
