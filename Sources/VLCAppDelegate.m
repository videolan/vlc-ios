/*****************************************************************************
 * VLCAppDelegate.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *          Luis Fernandes <zipleen # gmail.com>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *          Tamas Timar <ttimar.vlc # gmail.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *          Soomin Lee <TheHungryBu # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppDelegate.h"
#import "VLCMediaFileDiscoverer.h"
#import "NSString+SupportedMedia.h"
#import "UIDevice+VLC.h"
#import "VLCHTTPUploaderController.h"
#import "VLCPlaybackController.h"
#import "VLCPlaybackController+MediaLibrary.h"
#import <MediaPlayer/MediaPlayer.h>
#import <HockeySDK/HockeySDK.h>
#import "VLCActivityManager.h"
#import "VLCDropboxConstants.h"
#import "VLCPlaybackNavigationController.h"
#import "PAPasscodeViewController.h"
#import "VLC-Swift.h"

#define BETA_DISTRIBUTION 1

@interface VLCAppDelegate ()
{
    BOOL _isComingFromHandoff;
    VLCKeychainCoordinator *_keychainCoordinator;
    AppCoordinator *appCoordinator;
    UIViewController *rootViewController;
}

@end

@implementation VLCAppDelegate

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *appDefaults = @{kVLCSettingPasscodeAllowFaceID : @(1),
                                  kVLCSettingPasscodeAllowTouchID : @(1),
                                  kVLCSettingContinueAudioInBackgroundKey : @(YES),
                                  kVLCSettingStretchAudio : @(NO),
                                  kVLCSettingTextEncoding : kVLCSettingTextEncodingDefaultValue,
                                  kVLCSettingSkipLoopFilter : kVLCSettingSkipLoopFilterNonRef,
                                  kVLCSettingSubtitlesFont : kVLCSettingSubtitlesFontDefaultValue,
                                  kVLCSettingSubtitlesFontColor : kVLCSettingSubtitlesFontColorDefaultValue,
                                  kVLCSettingSubtitlesFontSize : kVLCSettingSubtitlesFontSizeDefaultValue,
                                  kVLCSettingSubtitlesBoldFont: kVLCSettingSubtitlesBoldFontDefaultValue,
                                  kVLCSettingDeinterlace : kVLCSettingDeinterlaceDefaultValue,
                                  kVLCSettingHardwareDecoding : kVLCSettingHardwareDecodingDefault,
                                  kVLCSettingNetworkCaching : kVLCSettingNetworkCachingDefaultValue,
                                  kVLCSettingVolumeGesture : @(YES),
                                  kVLCSettingPlayPauseGesture : @(YES),
                                  kVLCSettingBrightnessGesture : @(YES),
                                  kVLCSettingSeekGesture : @(YES),
                                  kVLCSettingCloseGesture : @(YES),
                                  kVLCSettingVariableJumpDuration : @(NO),
                                  kVLCSettingVideoFullscreenPlayback : @(YES),
                                  kVLCSettingContinuePlayback : @(1),
                                  kVLCSettingContinueAudioPlayback : @(1),
                                  kVLCSettingFTPTextEncoding : kVLCSettingFTPTextEncodingDefaultValue,
                                  kVLCSettingWiFiSharingIPv6 : kVLCSettingWiFiSharingIPv6DefaultValue,
                                  kVLCSettingEqualizerProfile : kVLCSettingEqualizerProfileDefaultValue,
                                  kVLCSettingPlaybackForwardSkipLength : kVLCSettingPlaybackForwardSkipLengthDefaultValue,
                                  kVLCSettingPlaybackBackwardSkipLength : kVLCSettingPlaybackBackwardSkipLengthDefaultValue,
                                  kVLCSettingOpenAppForPlayback : kVLCSettingOpenAppForPlaybackDefaultValue,
                                  kVLCAutomaticallyPlayNextItem : @(YES)};
    [defaults registerDefaults:appDefaults];
}

- (void)setup
{
    void (^setupAppCoordinator)(void) = ^{
        self->appCoordinator = [[AppCoordinator alloc] initWithViewController:self->rootViewController];
        [self->appCoordinator start];
    };
    [self validatePasscodeIfNeededWithCompletion:setupAppCoordinator];

    BOOL spotlightEnabled = ![VLCKeychainCoordinator passcodeLockEnabled];
    [[MLMediaLibrary sharedMediaLibrary] setSpotlightIndexingEnabled:spotlightEnabled];
    [[MLMediaLibrary sharedMediaLibrary] applicationWillStart];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BITHockeyManager *hockeyManager = [BITHockeyManager sharedHockeyManager];
    [hockeyManager configureWithBetaIdentifier:@"0114ca8e265244ce588d2ebd035c3577"
                                liveIdentifier:@"c95f4227dff96c61f8b3a46a25edc584"
                                      delegate:nil];
    [hockeyManager startManager];

    // Configure Dropbox
    [DBClientsManager setupWithAppKey:kVLCDropboxAppKey];

    [VLCApperanceManager setupAppearanceWithTheme:PresentationTheme.current];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    rootViewController = [UIViewController new];
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
    [self setup];

    /* add our static shortcut items the dynamic way to ease l10n and dynamic elements to be introduced later */
    if (@available(iOS 9, *)) {
        if (application.shortcutItems == nil || application.shortcutItems.count < 4) {
            UIApplicationShortcutItem *localLibraryItem = [[UIApplicationShortcutItem alloc] initWithType:kVLCApplicationShortcutLocalLibrary
                                                                                           localizedTitle:NSLocalizedString(@"SECTION_HEADER_LIBRARY",nil)
                                                                                        localizedSubtitle:nil
                                                                                                     icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"AllFiles"]
                                                                                                 userInfo:nil];
            UIApplicationShortcutItem *localServerItem = [[UIApplicationShortcutItem alloc] initWithType:kVLCApplicationShortcutLocalServers
                                                                                           localizedTitle:NSLocalizedString(@"LOCAL_NETWORK",nil)
                                                                                        localizedSubtitle:nil
                                                                                                     icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"Local"]
                                                                                                 userInfo:nil];
            UIApplicationShortcutItem *openNetworkStreamItem = [[UIApplicationShortcutItem alloc] initWithType:kVLCApplicationShortcutOpenNetworkStream
                                                                                           localizedTitle:NSLocalizedString(@"OPEN_NETWORK",nil)
                                                                                        localizedSubtitle:nil
                                                                                                     icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"OpenNetStream"]
                                                                                                 userInfo:nil];
            UIApplicationShortcutItem *cloudsItem = [[UIApplicationShortcutItem alloc] initWithType:kVLCApplicationShortcutClouds
                                                                                           localizedTitle:NSLocalizedString(@"CLOUD_SERVICES",nil)
                                                                                        localizedSubtitle:nil
                                                                                                     icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"iCloudIcon"]
                                                                                                 userInfo:nil];
            application.shortcutItems = @[localLibraryItem, localServerItem, openNetworkStreamItem, cloudsItem];
        }
    }

    return YES;
}

#pragma mark - Handoff

- (BOOL)application:(UIApplication *)application willContinueUserActivityWithType:(NSString *)userActivityType
{
    if ([userActivityType isEqualToString:kVLCUserActivityLibraryMode] ||
        [userActivityType isEqualToString:kVLCUserActivityPlaying] ||
        [userActivityType isEqualToString:kVLCUserActivityLibrarySelection])
        return YES;

    return NO;
}

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *))restorationHandler
{
    NSString *userActivityType = userActivity.activityType;
    NSDictionary *dict = userActivity.userInfo;
    if([userActivityType isEqualToString:kVLCUserActivityLibraryMode] ||
       [userActivityType isEqualToString:kVLCUserActivityLibrarySelection]) {
        //TODO: Add restoreUserActivityState to the mediaviewcontroller
        _isComingFromHandoff = YES;
        return YES;
    } else {
        NSURL *uriRepresentation = nil;
        if ([userActivityType isEqualToString:CSSearchableItemActionType]) {
            uriRepresentation = [NSURL URLWithString:dict[CSSearchableItemActivityIdentifier]];
        } else {
            uriRepresentation = dict[@"playingmedia"];
        }

        if (!uriRepresentation) {
            return NO;
        }

        NSManagedObject *managedObject = [[MLMediaLibrary sharedMediaLibrary] objectForURIRepresentation:uriRepresentation];
        if (managedObject == nil) {
            APLog(@"%s file not found: %@",__PRETTY_FUNCTION__,userActivity);
            return NO;
        }
        [self validatePasscodeIfNeededWithCompletion:^{
            [[VLCPlaybackController sharedInstance] openMediaLibraryObject:managedObject];
        }];
        return YES;
    }
    return NO;
}

- (void)application:(UIApplication *)application
didFailToContinueUserActivityWithType:(NSString *)userActivityType
              error:(NSError *)error
{
    if (error.code != NSUserCancelledError){
        //TODO: present alert
    }
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    for (id<VLCURLHandler> handler in URLHandlers.handlers) {
        if ([handler canHandleOpenWithUrl:url options:options]) {
            if ([handler performOpenWithUrl:url options:options]) {
                break;
            }
        }
    }
    return NO;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[MLMediaLibrary sharedMediaLibrary] applicationWillStart];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    //Touch ID is shown 
    if ([_window.rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]){
        UINavigationController *navCon = (UINavigationController *)_window.rootViewController.presentedViewController;
        if ([navCon.topViewController isKindOfClass:[PAPasscodeViewController class]]){
            return;
        }
    }
    [self validatePasscodeIfNeededWithCompletion:^{
        //TODO: handle updating the videoview and
        if ([VLCPlaybackController sharedInstance].isPlaying){
            //TODO: push playback
        }
    }];
    [[MLMediaLibrary sharedMediaLibrary] applicationWillExit];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (!_isComingFromHandoff) {
        [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
      //  [[VLCMediaFileDiscoverer sharedInstance] updateMediaList];
        [[VLCPlaybackController sharedInstance] recoverDisplayedMetadata];
    } else if(_isComingFromHandoff) {
        _isComingFromHandoff = NO;
    }
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
    //TODO: shortcutItem should be implemented
}

#pragma mark - pass code validation
- (VLCKeychainCoordinator *)keychainCoordinator
{
    if (!_keychainCoordinator) {
        _keychainCoordinator = [[VLCKeychainCoordinator alloc] init];
    }
    return _keychainCoordinator;
}

- (void)validatePasscodeIfNeededWithCompletion:(void(^)(void))completion
{
    if ([VLCKeychainCoordinator passcodeLockEnabled]) {
        //TODO: Dimiss playback
        [self.keychainCoordinator validatePasscodeWithCompletion:completion];
    } else {
        completion();
    }
}

@end
