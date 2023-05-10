/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLC-Swift.h"

#import "AppleTVAppDelegate.h"
#import "VLCServerListTVViewController.h"
#import "VLCOpenNetworkStreamTVViewController.h"
#import "VLCOpenManagedServersViewController.h"
#import "VLCSettingsViewController.h"
#import "VLCCloudServicesTVViewController.h"
#import "VLCHTTPUploaderController.h"
#import "VLCRemotePlaybackViewController.h"
#import "VLCMicroMediaLibraryService.h"
#import "VLCRemoteControlService.h"

@interface AppleTVAppDelegate ()
{
    UITabBarController *_mainViewController;

    VLCServerListTVViewController *_localNetworkVC;
    VLCCloudServicesTVViewController *_cloudServicesVC;
    VLCRemotePlaybackViewController *_remotePlaybackVC;
    VLCOpenNetworkStreamTVViewController *_openNetworkVC;
    VLCOpenManagedServersViewController *_openManagedServersVC;
    VLCSettingsViewController *_settingsVC;
    VLCRemoteControlService *_remoteControlService;
}

@end

@implementation AppleTVAppDelegate

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *appDefaults = @{kVLCSettingContinueAudioInBackgroundKey : @(YES),
                                  kVLCSettingStretchAudio : @(YES),
                                  kVLCSettingDefaultPreampLevel : @(0),
                                  kVLCSettingTextEncoding : kVLCSettingTextEncodingDefaultValue,
                                  kVLCSettingSkipLoopFilter : kVLCSettingSkipLoopFilterNonRef,
                                  kVLCSettingSubtitlesFont : kVLCSettingSubtitlesFontDefaultValue,
                                  kVLCSettingSubtitlesFontColor : kVLCSettingSubtitlesFontColorDefaultValue,
                                  kVLCSettingSubtitlesFontSize : kVLCSettingSubtitlesFontSizeDefaultValue,
                                  kVLCSettingSubtitlesBoldFont: kVLCSettingSubtitlesBoldFontDefaultValue,
                                  kVLCSettingDeinterlace : kVLCSettingDeinterlaceDefaultValue,
                                  kVLCSettingHardwareDecoding : kVLCSettingHardwareDecodingDefault,
                                  kVLCSettingNetworkCaching : kVLCSettingNetworkCachingDefaultValue,
                                  kVLCSettingNetworkRTSPTCP : @(NO),
                                  kVLCSettingNetworkSatIPChannelListUrl : @"",
                                  kVLCSettingEqualizerProfileDisabled : @(YES),
                                  kVLCSettingEqualizerProfile : kVLCSettingEqualizerProfileDefaultValue,
                                  kVLCSettingPlaybackForwardSkipLength : kVLCSettingPlaybackForwardSkipLengthDefaultValue,
                                  kVLCSettingPlaybackBackwardSkipLength : kVLCSettingPlaybackBackwardSkipLengthDefaultValue,
                                  kVLCSettingWiFiSharingIPv6 : kVLCSettingWiFiSharingIPv6DefaultValue,
                                  kVLCAutomaticallyPlayNextItem : @(YES),
                                  kVLCSettingDownloadArtwork : @(YES),
                                  kVLCForceSMBV1 : @(YES),
                                  kVLCSettingBackupMediaLibrary : kVLCSettingBackupMediaLibraryDefaultValue};
    [defaults registerDefaults:appDefaults];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _localNetworkVC = [[VLCServerListTVViewController alloc] initWithNibName:nil bundle:nil];
    _remotePlaybackVC = [[VLCRemotePlaybackViewController alloc] initWithNibName:nil bundle:nil];
    _openNetworkVC = [[VLCOpenNetworkStreamTVViewController alloc] initWithNibName:nil bundle:nil];
    _openManagedServersVC = [[VLCOpenManagedServersViewController alloc] initWithNibName:nil bundle:nil];
    _settingsVC = [[VLCSettingsViewController alloc] initWithNibName:nil bundle:nil];

    _mainViewController = [[UITabBarController alloc] init];
    _mainViewController.tabBar.barTintColor = [UIColor VLCOrangeTintColor];
    
    NSMutableArray *viewControllers = [[NSMutableArray alloc] init];
    [viewControllers addObject:[[UINavigationController alloc] initWithRootViewController:_localNetworkVC]];
    [viewControllers addObject:[[UINavigationController alloc] initWithRootViewController:_remotePlaybackVC]];
    [viewControllers addObject:[[UINavigationController alloc] initWithRootViewController:_openNetworkVC]];

    if(_openManagedServersVC.hasManagedServers) {
        [viewControllers addObject:[[UINavigationController alloc] initWithRootViewController:_openManagedServersVC]];
    }
    
    [viewControllers addObject:[[UINavigationController alloc] initWithRootViewController:_settingsVC]];
    
    [_mainViewController setViewControllers:viewControllers];

    self.window.rootViewController = _mainViewController;

    // Init the HTTP Server and the micro media library
    [VLCHTTPUploaderController sharedInstance];
    [[VLCMicroMediaLibraryService sharedInstance] updateMediaList];;
    _remoteControlService = [[VLCRemoteControlService alloc] init];

    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    for (id<VLCURLHandler> handler in URLHandlers.handlers) {
        if ([handler canHandleOpenWithUrl:url options:options]) {
            if ([handler performOpenWithUrl:url options:options]) {
                return YES;
            }
        }
    }
    return NO;
}

@end
