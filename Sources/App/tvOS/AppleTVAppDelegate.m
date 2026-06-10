/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015, 2021, 2023 VideoLAN. All rights reserved.
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
#import "VLCHTTPUploaderController.h"
#import "VLCRemotePlaybackViewController.h"
#import "VLCAppCoordinator.h"
#import "VLCRemoteControlService.h"
#import "VLCTransferStatusBannerController.h"

@interface AppleTVAppDelegate ()
{
    UITabBarController *_mainViewController;
    // ViewControllers
    VLCServerListTVViewController *_localNetworkVC;
    VLCRemotePlaybackViewController *_remotePlaybackVC;
    VLCOpenNetworkStreamTVViewController *_openNetworkVC;
    VLCOpenManagedServersViewController *_openManagedServersVC;
    VLCSettingsViewController *_settingsVC;
    PlaylistViewController *_playlistVC;
    VLCRemoteControlService *_remoteControlService;
    VLCTransferStatusBannerController *_transferBannerController;
}
@end

@implementation AppleTVAppDelegate

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *appDefaults = @{kVLCSettingAppTheme : @(kVLCSettingAppThemeSystem),
                                  kVLCSettingContinueAudioInBackgroundKey : @(YES),
                                  kVLCSettingStretchAudio : @(YES),
                                  kVLCSettingDefaultPreampLevel : @(6),
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
                                  kVLCSettingNetworkRTSPHTTP : @(NO),
                                  kVLCSettingNetworkSatIPChannelListUrl : @"",
                                  kVLCSettingEqualizerProfileDisabled : @(YES),
                                  kVLCSettingEqualizerProfile : kVLCSettingEqualizerProfileDefaultValue,
                                  kVLCSettingPlaybackForwardSkipLength : kVLCSettingPlaybackForwardSkipLengthDefaultValue,
                                  kVLCSettingPlaybackBackwardSkipLength : kVLCSettingPlaybackBackwardSkipLengthDefaultValue,
                                  kVLCSettingPlaybackLockscreenSkip : @(NO),
                                  kVLCSettingPlaybackRemoteControlSkip : @(NO),
                                  kVLCSettingWiFiSharingIPv6 : kVLCSettingWiFiSharingIPv6DefaultValue,
                                  kVLCSettingPlayUploadsWhileReceiving : kVLCSettingPlayUploadsWhileReceivingDefaultValue,
                                  kVLCAutomaticallyPlayNextItem : @(YES),
                                  kVLCSettingShowThumbnails : kVLCSettingShowThumbnailsDefaultValue,
                                  kVLCSettingShowArtworks : kVLCSettingShowArtworksDefaultValue,
                                  kVLCPlayerShouldRememberState: @(YES),
                                  kVLCPlayerUIShouldHide : @(NO),
                                  kVLCSettingDownloadArtwork : @(YES),
                                  kVLCForceSMBV1 : @(YES),
                                  kVLCSettingBackupMediaLibrary : kVLCSettingBackupMediaLibraryDefaultValue,
                                  kVLCSettingPlaybackSpeedDefaultValue: @(1.0),
                                  kVLCSettingsAudioOffsetDelay : kVLCSettingsOffsetDefaultValue,
                                  kVLCSettingsSubtitlesOffsetDelay : kVLCSettingsOffsetDefaultValue};
    [defaults registerDefaults:appDefaults];
}

- (UIViewController *)setupMainViewController
{
    _localNetworkVC = [[VLCServerListTVViewController alloc] initWithNibName:nil bundle:nil];
    _remotePlaybackVC = [[VLCRemotePlaybackViewController alloc] initWithNibName:nil bundle:nil];
    _openNetworkVC = [[VLCOpenNetworkStreamTVViewController alloc] initWithNibName:nil bundle:nil];
    _openManagedServersVC = [[VLCOpenManagedServersViewController alloc] initWithNibName:nil bundle:nil];
    _settingsVC = [[VLCSettingsViewController alloc] initWithNibName:nil bundle:nil];
    _playlistVC = [[PlaylistViewController alloc] init];
    _mainViewController = [[UITabBarController alloc] init];
    _mainViewController.tabBar.barTintColor = [UIColor VLCOrangeTintColor];

    NSMutableArray *viewControllers = [[NSMutableArray alloc] init];
    [viewControllers addObject:[[UINavigationController alloc] initWithRootViewController:_localNetworkVC]];
    [viewControllers addObject:[[UINavigationController alloc] initWithRootViewController:_remotePlaybackVC]];
    [viewControllers addObject:[[UINavigationController alloc] initWithRootViewController:_openNetworkVC]];
    [viewControllers addObject:[[UINavigationController alloc] initWithRootViewController:_playlistVC]];

    if(_openManagedServersVC.hasManagedServers) {
        [viewControllers addObject:[[UINavigationController alloc] initWithRootViewController:_openManagedServersVC]];
    }

    [viewControllers addObject:[[UINavigationController alloc] initWithRootViewController:_settingsVC]];
    [_mainViewController setViewControllers:viewControllers];

    _transferBannerController = [[VLCTransferStatusBannerController alloc] initWithContainerView:_mainViewController.view delegate:nil];

    [VLCAppCoordinator sharedInstance];
    _remoteControlService = [[VLCRemoteControlService alloc] init];

    [self.window makeKeyAndVisible];

    return _mainViewController;
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

- (void)applicationWillTerminate:(UIApplication *)application
{
    VLCFavoriteService *fs = [[VLCAppCoordinator sharedInstance] favoriteService];
    [fs storeContentSynchronously];
}

#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                              options:(UISceneConnectionOptions *)options
{
    return [[UISceneConfiguration alloc] initWithName:@"VLCTVDefaultScene" sessionRole:connectingSceneSession.role];
}

- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions
{
}

@end
