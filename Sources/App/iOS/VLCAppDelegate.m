/*****************************************************************************
 * VLCAppDelegate.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2023 VideoLAN. All rights reserved.
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
#import "VLC-Swift.h"
#import "VLCAppSceneDelegate.h"

@interface VLCAppDelegate ()
{
    BOOL _isComingFromHandoff;
    VLCKeychainCoordinator *_keychainCoordinator;
    id<VLCURLHandler> _urlHandlerToExecute;
    NSURL *_urlToHandle;
}

@end

@implementation VLCAppDelegate

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUInteger appThemeIndex = kVLCSettingAppThemeBright;
    if (@available(iOS 13.0, *)) {
        appThemeIndex = kVLCSettingAppThemeSystem;
    }

    NSDictionary *appDefaults = @{kVLCSettingAppTheme : @(appThemeIndex),
                                  kVLCSettingPasscodeAllowFaceID : @(1),
                                  kVLCSettingPasscodeAllowTouchID : @(1),
                                  kVLCSettingContinueAudioInBackgroundKey : @(YES),
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
                                  kVLCSettingVolumeGesture : @(YES),
                                  kVLCSettingPlayPauseGesture : @(YES),
                                  kVLCSettingBrightnessGesture : @(YES),
                                  kVLCSettingSeekGesture : @(YES),
                                  kVLCSettingCloseGesture : @(YES),
                                  kVLCSettingVideoFullscreenPlayback : @(YES),
                                  kVLCSettingContinuePlayback : @(1),
                                  kVLCSettingContinueAudioPlayback : @(1),
                                  kVLCSettingWiFiSharingIPv6 : kVLCSettingWiFiSharingIPv6DefaultValue,
                                  kVLCSettingNetworkRTSPTCP : @(NO),
                                  kVLCSettingNetworkSatIPChannelListUrl : @"",
                                  kVLCSettingEqualizerProfile : kVLCSettingEqualizerProfileDefaultValue,
                                  kVLCSettingEqualizerProfileDisabled : @(YES),
                                  kVLCSettingPlaybackForwardBackwardEqual: @(YES),
                                  kVLCSettingPlaybackTapSwipeEqual:  @(YES),
                                  kVLCSettingPlaybackForwardSkipLength : kVLCSettingPlaybackForwardSkipLengthDefaultValue,
                                  kVLCSettingPlaybackBackwardSkipLength : kVLCSettingPlaybackBackwardSkipLengthDefaultValue,
                                  kVLCSettingPlaybackForwardSkipLengthSwipe : kVLCSettingPlaybackForwardSkipLengthSwipeDefaultValue,
                                  kVLCSettingPlaybackBackwardSkipLengthSwipe : kVLCSettingPlaybackBackwardSkipLengthSwipeDefaultValue,
                                  kVLCSettingOpenAppForPlayback : kVLCSettingOpenAppForPlaybackDefaultValue,
                                  kVLCAutomaticallyPlayNextItem : @(YES),
                                  kVLCSettingEnableMediaCellTextScrolling : @(NO),
                                  kVLCSettingShowThumbnails : kVLCSettingShowThumbnailsDefaultValue,
                                  kVLCSettingShowArtworks : kVLCSettingShowArtworksDefaultValue,
                                  kVLCSettingBackupMediaLibrary : kVLCSettingBackupMediaLibraryDefaultValue,
                                  kVLCSettingCastingAudioPassthrough : @(NO),
                                  kVLCSettingCastingConversionQuality : @(2),
                                  kVLCForceSMBV1 : @(YES),
                                  @"kVLCAudioLibraryGridLayoutALBUMS" : @(YES),
                                  @"kVLCAudioLibraryGridLayoutARTISTS" : @(YES),
                                  @"kVLCAudioLibraryGridLayoutGENRES" : @(YES),
                                  @"kVLCVideoLibraryGridLayoutALL_VIDEOS" : @(YES),
                                  @"kVLCVideoLibraryGridLayoutVIDEO_GROUPS" : @(YES),
                                  @"kVLCVideoLibraryGridLayoutVLCMLMediaGroupCollections" : @(YES),
                                  kVLCPlayerShouldRememberState: @(YES),
                                  kVLCPlayerIsShuffleEnabled: kVLCPlayerIsShuffleEnabledDefaultValue,
                                  kVLCPlayerIsRepeatEnabled: kVLCPlayerIsRepeatEnabledDefaultValue,
                                  kVLCSettingPlaybackSpeedDefaultValue: @(1.0),
                                  kVLCPlayerShowPlaybackSpeedShortcut: @(NO)
    };
    [defaults registerDefaults:appDefaults];
}

- (void)setupTabBarAppearance
{
    VLCAppCoordinator *appCoordinator = [VLCAppCoordinator sharedInstance];
    void (^setupAppCoordinator)(void) = ^{
        [appCoordinator setTabBarController:(UITabBarController *)self->_window.rootViewController];
    };
    [self validatePasscodeIfNeededWithCompletion:setupAppCoordinator];
}

- (void)configureShortCutItemsWithApplication:(UIApplication *)application
{
    /* add our static shortcut items the dynamic way to ease l10n and dynamic elements to be introduced later */
    if (application.shortcutItems == nil || application.shortcutItems.count < 4) {
        UIApplicationShortcutItem *localVideoItem = [[UIApplicationShortcutItem alloc] initWithType:kVLCApplicationShortcutLocalVideo
                                                                                     localizedTitle:NSLocalizedString(@"VIDEO",nil)
                                                                                  localizedSubtitle:nil
                                                                                               icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"Video"]
                                                                                           userInfo:nil];
        UIApplicationShortcutItem *localAudioItem = [[UIApplicationShortcutItem alloc] initWithType:kVLCApplicationShortcutLocalAudio
                                                                                     localizedTitle:NSLocalizedString(@"AUDIO",nil)
                                                                                  localizedSubtitle:nil
                                                                                               icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"Audio"]
                                                                                           userInfo:nil];
        UIApplicationShortcutItem *localplaylistItem = [[UIApplicationShortcutItem alloc] initWithType:kVLCApplicationShortcutPlaylist
                                                                                        localizedTitle:NSLocalizedString(@"PLAYLISTS",nil)
                                                                                     localizedSubtitle:nil
                                                                                                  icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"Playlist"]
                                                                                              userInfo:nil];
        UIApplicationShortcutItem *networkItem = [[UIApplicationShortcutItem alloc] initWithType:kVLCApplicationShortcutNetwork
                                                                                  localizedTitle:NSLocalizedString(@"NETWORK",nil)
                                                                               localizedSubtitle:nil
                                                                                            icon:[UIApplicationShortcutIcon iconWithTemplateImageName:@"Network"]
                                                                                        userInfo:nil];
        application.shortcutItems = @[localVideoItem, localAudioItem, localplaylistItem, networkItem];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if (@available(iOS 13.0, *)) {
        APLog(@"Using Scene flow");
    } else {
        APLog(@"Using Traditional flow");
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        self.window.rootViewController = [UITabBarController new];
        [self.window makeKeyAndVisible];
        [VLCAppearanceManager setupAppearanceWithTheme:PresentationTheme.current];
        [self setupTabBarAppearance];
    }
    self.orientationLock = UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape;

    [self configureShortCutItemsWithApplication:application];

    return YES;
}

#pragma mark - Handoff

- (BOOL)application:(UIApplication *)application willContinueUserActivityWithType:(NSString *)userActivityType
{
    return [userActivityType isEqualToString:kVLCUserActivityPlaying];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *))restorationHandler
{
    VLCMLMedia *media = [[VLCAppCoordinator sharedInstance] mediaForUserActivity:userActivity];
    if (!media) return NO;

    [self validatePasscodeIfNeededWithCompletion:^{
        [[VLCPlaybackService sharedInstance] playMedia:media];
    }];
    return YES;
}

- (void)application:(UIApplication *)application didFailToContinueUserActivityWithType:(NSString *)userActivityType
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
            /* if no passcode is set, immediately execute the handler
             * otherwise, store it for later use by the passcode controller's completion function */
            if (![VLCKeychainCoordinator passcodeLockEnabled]) {
                return [handler performOpenWithUrl:url options:options];
            } else {
                _urlHandlerToExecute = handler;
                _urlToHandle = url;
                return YES;
            }
        }
    }
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    //Touch ID is shown
    if ([_window.rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]){
        UINavigationController *navCon = (UINavigationController *)_window.rootViewController.presentedViewController;
        if ([navCon.topViewController isKindOfClass:[PasscodeLockController class]]){
            return;
        }
    }
    [self validatePasscodeIfNeededWithCompletion:^{
        //TODO: handle updating the videoview and
        if ([VLCPlaybackService sharedInstance].isPlaying){
            //TODO: push playback
        }

        /* execute a potential URL handler that was set when the app was moved into foreground */
        if (self->_urlHandlerToExecute) {
            if (![self->_urlHandlerToExecute performOpenWithUrl:self->_urlToHandle options:@{}]) {
                APLog(@"Failed to execute %@", self->_urlToHandle);
            }
            self->_urlHandlerToExecute = nil;
            self->_urlToHandle = nil;
        }
    }];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (!_isComingFromHandoff) {
        [[VLCPlaybackService sharedInstance] recoverDisplayedMetadata];
    } else if(_isComingFromHandoff) {
        _isComingFromHandoff = NO;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /* save the playback position before the user kills the app */
    VLCPlaybackService *vps = [VLCPlaybackService sharedInstance];
    if (vps.isPlaying || vps.playerIsSetup) {
        VLCAppCoordinator *appCoordinator = [VLCAppCoordinator sharedInstance];
        [appCoordinator.mediaLibraryService savePlaybackStateFrom:vps];
    }
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
    [[VLCAppCoordinator sharedInstance] handleShortcutItem:shortcutItem];
}

- (id)application:(UIApplication *)application handlerForIntent:(INIntent *)intent
{
    if (@available(iOS 14.0, *)) {
        if ([intent isKindOfClass:[INPlayMediaIntent class]] || [intent isKindOfClass:[INAddMediaIntent class]] || [intent isKindOfClass:[INSearchForMediaIntent class]]) {
            return [[SirikitIntentCoordinator alloc] initWithMediaLibraryService: [[VLCAppCoordinator sharedInstance] mediaLibraryService]];;
        }
    }
    return NULL;
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
        //TODO: Dismiss playback
        [self.keychainCoordinator validatePasscodeWithCompletion:completion];
    } else {
        completion();
    }
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return self.orientationLock;
}

#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                              options:(UISceneConnectionOptions *)options  API_AVAILABLE(ios(13.0))
{
    UISceneSessionRole role = connectingSceneSession.role;
    if ([role isEqualToString:@"CPTemplateApplicationSceneSessionRoleApplication"]) {
        return [[UISceneConfiguration alloc] initWithName:@"VLCCarPlayScene" sessionRole:role];
    }
    if ([role isEqualToString:@"UIWindowSceneSessionRoleExternalDisplayNonInteractive"] ||
        [role isEqualToString:@"UIWindowSceneSessionRoleExternalDisplay"]) {
        return [[UISceneConfiguration alloc] initWithName:@"VLCNonInteractiveWindowScene" sessionRole:role];
    }
    return [[UISceneConfiguration alloc] initWithName:@"VLCDefaultAppScene" sessionRole:role];
}

- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions  API_AVAILABLE(ios(13.0))
{
}

@end
