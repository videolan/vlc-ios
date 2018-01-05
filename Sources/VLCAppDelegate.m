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
#import "VLCMigrationViewController.h"
#import <BoxSDK/BoxSDK.h>
#import "VLCPlaybackController.h"
#import "VLCPlaybackController+MediaLibrary.h"
#import <MediaPlayer/MediaPlayer.h>
#import <HockeySDK/HockeySDK.h>
#import "VLCActivityManager.h"
#import "VLCDropboxConstants.h"
#import "VLCDownloadViewController.h"
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>
#import "VLCPlaybackNavigationController.h"
#import "PAPasscodeViewController.h"
#import "VLC_iOS-Swift.h"

NSString *const VLCDropboxSessionWasAuthorized = @"VLCDropboxSessionWasAuthorized";

#define BETA_DISTRIBUTION 1

@interface VLCAppDelegate () <VLCMediaFileDiscovererDelegate>
{
    BOOL _isRunningMigration;
    BOOL _isComingFromHandoff;
    VLCWatchCommunication *_watchCommunication;
    VLCKeychainCoordinator *_keychainCoordinator;
    AppCoordinator *appCoordinator;
    UITabBarController *rootViewController;
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

    // Init the HTTP Server and clean its cache
    [[VLCHTTPUploaderController sharedInstance] cleanCache];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    rootViewController = [UITabBarController new];
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
    // enable crash preventer
    void (^setupBlock)() = ^{
        void (^setupLibraryBlock)() = ^{
            appCoordinator = [[AppCoordinator alloc] initWithTabBarController:rootViewController];
            [appCoordinator start];
        };
        [self validatePasscodeIfNeededWithCompletion:setupLibraryBlock];

        BOOL spotlightEnabled = ![VLCKeychainCoordinator passcodeLockEnabled];
        [[MLMediaLibrary sharedMediaLibrary] setSpotlightIndexingEnabled:spotlightEnabled];
        [[MLMediaLibrary sharedMediaLibrary] applicationWillStart];

        VLCMediaFileDiscoverer *discoverer = [VLCMediaFileDiscoverer sharedInstance];
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        discoverer.directoryPath = [searchPaths firstObject];
        [discoverer addObserver:self];
        [discoverer startDiscovering];
    };

    NSError *error = nil;

    if ([[MLMediaLibrary sharedMediaLibrary] libraryMigrationNeeded]){
        _isRunningMigration = YES;

        VLCMigrationViewController *migrationController = [[VLCMigrationViewController alloc] initWithNibName:@"VLCMigrationViewController" bundle:nil];
        migrationController.completionHandler = ^{

            //migrate
            setupBlock();
            _isRunningMigration = NO;
            [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
            [[VLCMediaFileDiscoverer sharedInstance] updateMediaList];
        };

        self.window.rootViewController = migrationController;
        [self.window makeKeyAndVisible];

    } else {
        if (error != nil) {
            APLog(@"removed persistentStore since it was corrupt");
            NSURL *storeURL = ((MLMediaLibrary *)[MLMediaLibrary sharedMediaLibrary]).persistentStoreURL;
            [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
        }
        setupBlock();
    }

    if ([VLCWatchCommunication isSupported]) {
        _watchCommunication = [VLCWatchCommunication sharedInstance];
        // TODO: push DB changes instead
        //    [_watchCommunication startRelayingNotificationName:NSManagedObjectContextDidSaveNotification object:nil];
        [_watchCommunication startRelayingNotificationName:VLCPlaybackControllerPlaybackMetadataDidChange object:nil];
    }

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
 restorationHandler:(void (^)(NSArray *))restorationHandler
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
        [[VLCPlaybackController sharedInstance] openMediaLibraryObject:managedObject];
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
    //Handles Dropbox Authorization flow.
    DBOAuthResult *authResult = [DBClientsManager handleRedirectURL:url];
    if (authResult != nil) {
        if ([authResult isSuccess]) {
            return YES;
        }
    }

    //Handles Google Authorization flow.
    if ([_currentGoogleAuthorizationFlow resumeAuthorizationFlowWithURL:url]) {
        _currentGoogleAuthorizationFlow = nil;
        return YES;
    }

    //TODO: we need a model of URLHandlers that registers with the VLCAppdelegate
    // then we can go through the list of handlers ask if they can handle the url and the first to say yes handles the call.
    // that way internal if elses get encapsulated
    /*
    protocol VLCURLHandler {
        func canHandleOpen(url: URL, options:[UIApplicationOpenURLOptionsKey:AnyObject]=[:]()) -> bool
        func performOpen(url: URL, options:[UIApplicationOpenURLOptionsKey:AnyObject]=[:]()) -> bool
    } */
//    if (_libraryViewController && url != nil) {
//        APLog(@"%@ requested %@ to be opened", sourceApplication, url);
//
//        if (url.isFileURL) {
//            NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//            NSString *directoryPath = searchPaths[0];
//            NSURL *destinationURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", directoryPath, url.lastPathComponent]];
//            NSError *theError;
//            [[NSFileManager defaultManager] moveItemAtURL:url toURL:destinationURL error:&theError];
//            if (theError.code != noErr)
//                APLog(@"saving the file failed (%li): %@", (long)theError.code, theError.localizedDescription);
//
//            [[VLCMediaFileDiscoverer sharedInstance] updateMediaList];
//        } else if ([url.scheme isEqualToString:@"vlc-x-callback"] || [url.host isEqualToString:@"x-callback-url"]) {
//            // URL confirmes to the x-callback-url specification
//            // vlc-x-callback://x-callback-url/action?param=value&x-success=callback
//            APLog(@"x-callback-url with host '%@' path '%@' parameters '%@'", url.host, url.path, url.query);
//            NSString *action = [url.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
//            NSURL *movieURL;
//            NSURL *successCallback;
//            NSURL *errorCallback;
//            NSString *fileName;
//            for (NSString *entry in [url.query componentsSeparatedByString:@"&"]) {
//                NSArray *keyvalue = [entry componentsSeparatedByString:@"="];
//                if (keyvalue.count < 2) continue;
//                NSString *key = keyvalue[0];
//                NSString *value = [keyvalue[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//
//                if ([key isEqualToString:@"url"])
//                    movieURL = [NSURL URLWithString:value];
//                else if ([key isEqualToString:@"filename"])
//                    fileName = value;
//                else if ([key isEqualToString:@"x-success"])
//                    successCallback = [NSURL URLWithString:value];
//                else if ([key isEqualToString:@"x-error"])
//                    errorCallback = [NSURL URLWithString:value];
//            }
//            if ([action isEqualToString:@"stream"] && movieURL) {
//                VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
//                vpc.fullscreenSessionRequested = YES;
//
//                VLCMediaList *medialist = [[VLCMediaList alloc] init];
//                [medialist addMedia:[VLCMedia mediaWithURL:movieURL]];
//                vpc.successCallback = successCallback;
//                vpc.errorCallback = errorCallback;
//                [vpc playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
//
//            }
//            else if ([action isEqualToString:@"download"] && movieURL) {
//                [self downloadMovieFromURL:movieURL fileNameOfMedia:fileName];
//            }
//        } else {
//            NSString *receivedUrl = [url absoluteString];
//            if ([receivedUrl length] > 6) {
//                NSString *verifyVlcUrl = [receivedUrl substringToIndex:6];
//                if ([verifyVlcUrl isEqualToString:@"vlc://"]) {
//                    NSString *parsedString = [receivedUrl substringFromIndex:6];
//                    NSUInteger location = [parsedString rangeOfString:@"//"].location;
//
//                    /* Safari & al mangle vlc://http:// so fix this */
//                    if (location != NSNotFound && [parsedString characterAtIndex:location - 1] != 0x3a) { // :
//                            parsedString = [NSString stringWithFormat:@"%@://%@", [parsedString substringToIndex:location], [parsedString substringFromIndex:location+2]];
//                    } else {
//                        parsedString = [receivedUrl substringFromIndex:6];
//                        if (![parsedString hasPrefix:@"http://"] && ![parsedString hasPrefix:@"https://"] && ![parsedString hasPrefix:@"ftp://"]) {
//                            parsedString = [@"http://" stringByAppendingString:[receivedUrl substringFromIndex:6]];
//                        }
//                    }
//                    url = [NSURL URLWithString:parsedString];
//                }
//            }
//            [[VLCSidebarController sharedInstance] selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
//                                                         scrollPosition:UITableViewScrollPositionNone];
//
//            NSString *scheme = url.scheme;
//            if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"] || [scheme isEqualToString:@"ftp"]) {
//                VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"OPEN_STREAM_OR_DOWNLOAD", nil) message:url.absoluteString cancelButtonTitle:NSLocalizedString(@"BUTTON_DOWNLOAD", nil) otherButtonTitles:@[NSLocalizedString(@"PLAY_BUTTON", nil)]];
//                alert.completion = ^(BOOL cancelled, NSInteger buttonIndex) {
//                    if (cancelled)
//                        [self downloadMovieFromURL:url fileNameOfMedia:nil];
//                    else {
//                        VLCMedia *media = [VLCMedia mediaWithURL:url];
//                        VLCMediaList *medialist = [[VLCMediaList alloc] init];
//                        [medialist addMedia:media];
//                        [[VLCPlaybackController sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
//                    }
//                };
//                [alert show];
//            } else {
//                VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
//                vpc.fullscreenSessionRequested = YES;
//                VLCMediaList *medialist = [[VLCMediaList alloc] init];
//                [medialist addMedia:[VLCMedia mediaWithURL:url]];
//                [vpc playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
//            }
//        }
//        return YES;
//    }
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
    if (!_isRunningMigration && !_isComingFromHandoff) {
        [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
      //  [[VLCMediaFileDiscoverer sharedInstance] updateMediaList];
        [[VLCPlaybackController sharedInstance] recoverDisplayedMetadata];
    } else if(_isComingFromHandoff) {
        _isComingFromHandoff = NO;
    }
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
    [[VLCSidebarController sharedInstance] performActionForShortcutItem:shortcutItem];
}

#pragma mark - media discovering

- (void)mediaFileAdded:(NSString *)fileName loading:(BOOL)isLoading
{
    if (!isLoading) {
        MLMediaLibrary *sharedLibrary = [MLMediaLibrary sharedMediaLibrary];
        [sharedLibrary addFilePaths:@[fileName]];

        /* exclude media files from backup (QA1719) */
        NSURL *excludeURL = [NSURL fileURLWithPath:fileName];
        [excludeURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];

        // TODO Should we update media db after adding new files?
        [sharedLibrary updateMediaDatabase];
        // TODO: update the VideoViewController
    }
}

- (void)mediaFileDeleted:(NSString *)name
{
    [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
   // TODO: update the VideoViewController
}

- (void)mediaFilesFoundRequiringAdditionToStorageBackend:(NSArray<NSString *> *)foundFiles
{
    [[MLMediaLibrary sharedMediaLibrary] addFilePaths:foundFiles];
  // TODO: update the VideoViewController
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

#pragma mark - download handling

- (void)downloadMovieFromURL:(NSURL *)url
             fileNameOfMedia:(NSString *)fileName
{
    [[VLCDownloadViewController sharedInstance] addURLToDownloadList:url fileNameOfMedia:fileName];
    [[VLCSidebarController sharedInstance] selectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]
                                                 scrollPosition:UITableViewScrollPositionNone];
}

#pragma mark - playback
- (void)playWithURL:(NSURL *)url successCallback:(NSURL *)successCallback errorCallback:(NSURL *)errorCallback
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    vpc.fullscreenSessionRequested = YES;
    vpc.successCallback = successCallback;
    vpc.errorCallback = errorCallback;
    VLCMediaList *mediaList = [[VLCMediaList alloc] initWithArray:@[[VLCMedia mediaWithURL:url]]];
    [vpc playMediaList:mediaList firstIndex:0 subtitlesFilePath:nil];
}

#pragma mark - watch stuff
- (void)application:(UIApplication *)application
handleWatchKitExtensionRequest:(NSDictionary *)userInfo
              reply:(void (^)(NSDictionary *))reply
{
    if ([VLCWatchCommunication isSupported]) {
        [self.watchCommunication session:[WCSession defaultSession] didReceiveMessage:userInfo replyHandler:reply];
    }
}

@end
