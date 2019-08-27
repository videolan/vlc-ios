/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "AppleTVAppDelegate.h"
#import "VLCServerListTVViewController.h"
#import "VLCOpenNetworkStreamTVViewController.h"
#import "VLCSettingsViewController.h"
#import "VLCCloudServicesTVViewController.h"
#import "VLCHTTPUploaderController.h"
#import "VLCRemotePlaybackViewController.h"

#import <AppCenter/AppCenter.h>
#import <AppCenterAnalytics/AppCenterAnalytics.h>
#import <AppCenterCrashes/AppCenterCrashes.h>

@interface AppleTVAppDelegate ()
{
    UITabBarController *_mainViewController;

    VLCServerListTVViewController *_localNetworkVC;
    VLCCloudServicesTVViewController *_cloudServicesVC;
    VLCRemotePlaybackViewController *_remotePlaybackVC;
    VLCOpenNetworkStreamTVViewController *_openNetworkVC;
    VLCSettingsViewController *_settingsVC;
}

@end

@implementation AppleTVAppDelegate

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *appDefaults = @{kVLCSettingContinueAudioInBackgroundKey : @(YES),
                                  kVLCSettingStretchAudio : @(YES),
                                  kVLCSettingTextEncoding : kVLCSettingTextEncodingDefaultValue,
                                  kVLCSettingSkipLoopFilter : kVLCSettingSkipLoopFilterNonRef,
                                  kVLCSettingSubtitlesFont : kVLCSettingSubtitlesFontDefaultValue,
                                  kVLCSettingSubtitlesFontColor : kVLCSettingSubtitlesFontColorDefaultValue,
                                  kVLCSettingSubtitlesFontSize : kVLCSettingSubtitlesFontSizeDefaultValue,
                                  kVLCSettingSubtitlesBoldFont: kVLCSettingSubtitlesBoldFontDefaultValue,
                                  kVLCSettingDeinterlace : kVLCSettingDeinterlaceDefaultValue,
                                  kVLCSettingHardwareDecoding : kVLCSettingHardwareDecodingDefault,
                                  kVLCSettingNetworkCaching : kVLCSettingNetworkCachingDefaultValue,
                                  kVLCSettingEqualizerProfileDisabled : @(YES),
                                  kVLCSettingEqualizerProfile : kVLCSettingEqualizerProfileDefaultValue,
                                  kVLCSettingPlaybackForwardSkipLength : kVLCSettingPlaybackForwardSkipLengthDefaultValue,
                                  kVLCSettingPlaybackBackwardSkipLength : kVLCSettingPlaybackBackwardSkipLengthDefaultValue,
                                  kVLCSettingFTPTextEncoding : kVLCSettingFTPTextEncodingDefaultValue,
                                  kVLCSettingWiFiSharingIPv6 : kVLCSettingWiFiSharingIPv6DefaultValue,
                                  kVLCAutomaticallyPlayNextItem : @(YES),
                                  kVLCSettingDownloadArtwork : @(YES)};
    [defaults registerDefaults:appDefaults];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [MSAppCenter start:@"f8697706-993b-44bb-a1c0-3cb7016cc325" withServices:@[
                                                                              [MSAnalytics class],
                                                                              [MSCrashes class]
                                                                              ]];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _localNetworkVC = [[VLCServerListTVViewController alloc] initWithNibName:nil bundle:nil];
    _remotePlaybackVC = [[VLCRemotePlaybackViewController alloc] initWithNibName:nil bundle:nil];
    _openNetworkVC = [[VLCOpenNetworkStreamTVViewController alloc] initWithNibName:nil bundle:nil];
    _settingsVC = [[VLCSettingsViewController alloc] initWithNibName:nil bundle:nil];

    _mainViewController = [[UITabBarController alloc] init];
    _mainViewController.tabBar.barTintColor = [UIColor VLCOrangeTintColor];

    _mainViewController.viewControllers = @[[[UINavigationController alloc] initWithRootViewController:_localNetworkVC],
                                            [[UINavigationController alloc] initWithRootViewController:_remotePlaybackVC],
                                            [[UINavigationController alloc] initWithRootViewController:_openNetworkVC],
                                            [[UINavigationController alloc] initWithRootViewController:_settingsVC]];

    self.window.rootViewController = _mainViewController;

    // Init the HTTP Server
    [VLCHTTPUploaderController sharedInstance];

    [self.window makeKeyAndVisible];
    return YES;
}

@end
