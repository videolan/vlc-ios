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
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppDelegate.h"
#import "VLCMediaFileDiscoverer.h"
#import "NSString+SupportedMedia.h"
#import "UIDevice+VLC.h"
#import "VLCPlaylistViewController.h"
#import "VLCPlaybackNavigationController.h"
#import "PAPasscodeViewController.h"
#import "VLCHTTPUploaderController.h"
#import "VLCMenuTableViewController.h"
#import "VLCMigrationViewController.h"
#import <BoxSDK/BoxSDK.h>
#import "VLCNotificationRelay.h"
#import "VLCPlaybackController.h"
#import "VLCNavigationController.h"
#import "VLCWatchMessage.h"
#import "VLCPlaybackController+MediaLibrary.h"
#import "VLCPlayerDisplayController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface VLCAppDelegate () <PAPasscodeViewControllerDelegate, VLCMediaFileDiscovererDelegate> {
    PAPasscodeViewController *_passcodeLockController;
    VLCDownloadViewController *_downloadViewController;
    VLCDropboxTableViewController *_dropboxTableViewController;
    int _idleCounter;
    int _networkActivityCounter;
    BOOL _passcodeValidated;
    BOOL _isRunningMigration;
    BOOL _isComingFromHandoff;
}

@end

@implementation VLCAppDelegate

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSNumber *skipLoopFilterDefaultValue;
    int deviceSpeedCategory = [[UIDevice currentDevice] speedCategory];
    if (deviceSpeedCategory < 3)
        skipLoopFilterDefaultValue = kVLCSettingSkipLoopFilterNonKey;
    else
        skipLoopFilterDefaultValue = kVLCSettingSkipLoopFilterNonRef;

    NSDictionary *appDefaults = @{kVLCSettingPasscodeKey : @"",
                                  kVLCSettingPasscodeOnKey : @(NO),
                                  kVLCSettingContinueAudioInBackgroundKey : @(YES),
                                  kVLCSettingStretchAudio : @(NO),
                                  kVLCSettingTextEncoding : kVLCSettingTextEncodingDefaultValue,
                                  kVLCSettingSkipLoopFilter : skipLoopFilterDefaultValue,
                                  kVLCSettingSubtitlesFont : kVLCSettingSubtitlesFontDefaultValue,
                                  kVLCSettingSubtitlesFontColor : kVLCSettingSubtitlesFontColorDefaultValue,
                                  kVLCSettingSubtitlesFontSize : kVLCSettingSubtitlesFontSizeDefaultValue,
                                  kVLCSettingSubtitlesBoldFont: kVLCSettingSubtitlesBoldFontDefaultValue,
                                  kVLCSettingDeinterlace : kVLCSettingDeinterlaceDefaultValue,
                                  kVLCSettingNetworkCaching : kVLCSettingNetworkCachingDefaultValue,
                                  kVLCSettingPlaybackGestures : [NSNumber numberWithBool:YES],
                                  kVLCSettingFTPTextEncoding : kVLCSettingFTPTextEncodingDefaultValue,
                                  kVLCSettingWiFiSharingIPv6 : kVLCSettingWiFiSharingIPv6DefaultValue,
                                  kVLCSettingEqualizerProfile : kVLCSettingEqualizerProfileDefaultValue,
                                  kVLCSettingPlaybackForwardSkipLength : kVLCSettingPlaybackForwardSkipLengthDefaultValue,
                                  kVLCSettingPlaybackBackwardSkipLength : kVLCSettingPlaybackBackwardSkipLengthDefaultValue,
                                  kVLCSettingOpenAppForPlayback : kVLCSettingOpenAppForPlaybackDefaultValue};
    [defaults registerDefaults:appDefaults];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        // Change the keyboard for UISearchBar
        [[UITextField appearance] setKeyboardAppearance:UIKeyboardAppearanceDark];
        // For the cursor
        [[UITextField appearance] setTintColor:[UIColor VLCOrangeTintColor]];
        // Don't override the 'Cancel' button color in the search bar with the previous UITextField call. Use the default blue color
        [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]} forState:UIControlStateNormal];
        // For the edit selection indicators
        [[UITableView appearance] setTintColor:[UIColor VLCOrangeTintColor]];
    }

    [[UISwitch appearance] setOnTintColor:[UIColor VLCOrangeTintColor]];

    /* clean caches on launch (since those are used for wifi upload only) */
    [self cleanCache];

    // Init the HTTP Server
    self.uploadController = [[VLCHTTPUploaderController alloc] init];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // enable crash preventer
     void (^setupBlock)() = ^{
         _playlistViewController = [[VLCPlaylistViewController alloc] init];
        UINavigationController *navCon = [[VLCNavigationController alloc] initWithRootViewController:_playlistViewController];

        _revealController = [[GHRevealViewController alloc] initWithNibName:nil bundle:nil];
        _revealController.wantsFullScreenLayout = YES;
        _menuViewController = [[VLCMenuTableViewController alloc] initWithNibName:nil bundle:nil];
        _revealController.sidebarViewController = _menuViewController;
        _revealController.contentViewController = navCon;

         _playerDisplayController = [[VLCPlayerDisplayController alloc] init];
         _playerDisplayController.childViewController = self.revealController;

        self.window.rootViewController = _playerDisplayController;
        // necessary to avoid navbar blinking in VLCOpenNetworkStreamViewController & VLCDownloadViewController
        _revealController.contentViewController.view.backgroundColor = [UIColor VLCDarkBackgroundColor];
        [self.window makeKeyAndVisible];

        [self validatePasscode];

        [[MLMediaLibrary sharedMediaLibrary] applicationWillStart];

        VLCMediaFileDiscoverer *discoverer = [VLCMediaFileDiscoverer sharedInstance];
        [discoverer addObserver:self];
        [discoverer startDiscovering:[self directoryPath]];
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
            [self updateMediaList];
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

    [[VLCNotificationRelay sharedRelay] addRelayLocalName:NSManagedObjectContextDidSaveNotification toRemoteName:@"org.videolan.ios-app.dbupdate"];

    [[VLCNotificationRelay sharedRelay] addRelayLocalName:VLCPlaybackControllerPlaybackMetadataDidChange toRemoteName:kVLCDarwinNotificationNowPlayingInfoUpdate];

    return YES;
}

#pragma mark - Handoff

- (BOOL)application:(UIApplication *)application willContinueUserActivityWithType:(NSString *)userActivityType
{
    if ([userActivityType isEqualToString:@"org.videolan.vlc-ios.librarymode"] ||
        [userActivityType isEqualToString:@"org.videolan.vlc-ios.playing"] ||
        [userActivityType isEqualToString:@"org.videolan.vlc-ios.libraryselection"])
        return YES;

    return NO;
}

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray *))restorationHandler
{
    NSString *userActivityType = userActivity.activityType;

    if([userActivityType isEqualToString:@"org.videolan.vlc-ios.librarymode"] ||
       [userActivityType isEqualToString:@"org.videolan.vlc-ios.libraryselection"]) {
        NSDictionary *dict = userActivity.userInfo;
        VLCLibraryMode libraryMode = (VLCLibraryMode)[(NSNumber *)dict[@"state"] integerValue];

        if (libraryMode <= VLCLibraryModeAllSeries) {
            [self.menuViewController selectRowAtIndexPath:[NSIndexPath indexPathForRow:libraryMode inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
            [self.playlistViewController setLibraryMode:(VLCLibraryMode)libraryMode];
        }

        [self.playlistViewController restoreUserActivityState:userActivity];
        _isComingFromHandoff = YES;
        return YES;
    }
    return NO;
}

- (void)application:(UIApplication *)application didFailToContinueUserActivityWithType:(NSString *)userActivityType error:(NSError *)error
{
    if (error.code != NSUserCancelledError){
        //TODO: present alert
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        [self.dropboxTableViewController updateViewAfterSessionChange];
        return YES;
    }

    if (_playlistViewController && url != nil) {
        APLog(@"%@ requested %@ to be opened", sourceApplication, url);

        if (url.isFileURL) {
            NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *directoryPath = searchPaths[0];
            NSURL *destinationURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", directoryPath, url.lastPathComponent]];
            NSError *theError;
            [[NSFileManager defaultManager] moveItemAtURL:url toURL:destinationURL error:&theError];
            if (theError.code != noErr)
                APLog(@"saving the file failed (%li): %@", (long)theError.code, theError.localizedDescription);

            [self updateMediaList];
        } else if ([url.scheme isEqualToString:@"vlc-x-callback"] || [url.host isEqualToString:@"x-callback-url"]) {
            // URL confirmes to the x-callback-url specification
            // vlc-x-callback://x-callback-url/action?param=value&x-success=callback
            APLog(@"x-callback-url with host '%@' path '%@' parameters '%@'", url.host, url.path, url.query);
            NSString *action = [url.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
            NSURL *movieURL;
            NSURL *successCallback;
            NSURL *errorCallback;
            NSString *fileName;
            for (NSString *entry in [url.query componentsSeparatedByString:@"&"]) {
                NSArray *keyvalue = [entry componentsSeparatedByString:@"="];
                if (keyvalue.count < 2) continue;
                NSString *key = keyvalue[0];
                NSString *value = [keyvalue[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

                if ([key isEqualToString:@"url"])
                    movieURL = [NSURL URLWithString:value];
                else if ([key isEqualToString:@"filename"])
                    fileName = value;
                else if ([key isEqualToString:@"x-success"])
                    successCallback = [NSURL URLWithString:value];
                else if ([key isEqualToString:@"x-error"])
                    errorCallback = [NSURL URLWithString:value];
            }
            if ([action isEqualToString:@"stream"] && movieURL) {
                [self openMovieFromURL:movieURL successCallback:successCallback errorCallback:errorCallback];
            }
            else if ([action isEqualToString:@"download"] && movieURL) {
                [self downloadMovieFromURL:movieURL fileNameOfMedia:fileName];
            }
        } else {
            NSString *receivedUrl = [url absoluteString];
            if ([receivedUrl length] > 6) {
                NSString *verifyVlcUrl = [receivedUrl substringToIndex:6];
                if ([verifyVlcUrl isEqualToString:@"vlc://"]) {
                    NSString *parsedString = [receivedUrl substringFromIndex:6];
                    NSUInteger location = [parsedString rangeOfString:@"//"].location;

                    /* Safari & al mangle vlc://http:// so fix this */
                    if (location != NSNotFound && [parsedString characterAtIndex:location - 1] != 0x3a) { // :
                            parsedString = [NSString stringWithFormat:@"%@://%@", [parsedString substringToIndex:location], [parsedString substringFromIndex:location+2]];
                    } else {
                        parsedString = [receivedUrl substringFromIndex:6];
                        if (![parsedString hasPrefix:@"http://"] && ![parsedString hasPrefix:@"https://"] && ![parsedString hasPrefix:@"ftp://"]) {
                            parsedString = [@"http://" stringByAppendingString:[receivedUrl substringFromIndex:6]];
                        }
                    }
                    url = [NSURL URLWithString:parsedString];
                }
            }
            [self.menuViewController selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];

            NSString *scheme = url.scheme;
            if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"] || [scheme isEqualToString:@"ftp"]) {
                VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"OPEN_STREAM_OR_DOWNLOAD", nil) message:url.absoluteString cancelButtonTitle:NSLocalizedString(@"BUTTON_DOWNLOAD", nil) otherButtonTitles:@[NSLocalizedString(@"PLAY_BUTTON", nil)]];
                alert.completion = ^(BOOL cancelled, NSInteger buttonIndex) {
                    if (cancelled)
                        [self downloadMovieFromURL:url fileNameOfMedia:nil];
                    else
                        [self openMovieFromURL:url];
                };
                [alert show];
            } else
                [self openMovieFromURL:url];
        }
        return YES;
    }
    return NO;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[MLMediaLibrary sharedMediaLibrary] applicationWillStart];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    _passcodeValidated = NO;
    [self validatePasscode];
    [[MLMediaLibrary sharedMediaLibrary] applicationWillExit];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (!_isRunningMigration && !_isComingFromHandoff) {
        [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
        [self updateMediaList];
    } else if(_isComingFromHandoff) {
        _isComingFromHandoff = NO;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    _passcodeValidated = NO;
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - properties
- (VLCDropboxTableViewController *)dropboxTableViewController
{
    if (_dropboxTableViewController == nil)
        _dropboxTableViewController = [[VLCDropboxTableViewController alloc] initWithNibName:@"VLCCloudStorageTableViewController" bundle:nil];

    return _dropboxTableViewController;
}

- (VLCDownloadViewController *)downloadViewController
{
    if (_downloadViewController == nil) {
        if (SYSTEM_RUNS_IOS7_OR_LATER)
            _downloadViewController = [[VLCDownloadViewController alloc] initWithNibName:@"VLCFutureDownloadViewController" bundle:nil];
        else
            _downloadViewController = [[VLCDownloadViewController alloc] initWithNibName:@"VLCDownloadViewController" bundle:nil];
    }

    return _downloadViewController;
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
        [_playlistViewController updateViewContents];
    }
}

- (void)mediaFileDeleted:(NSString *)name
{
    [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
    [_playlistViewController updateViewContents];
}

- (void)cleanCache
{
    if ([self haveNetworkActivity])
        return;

    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* uploadDirPath = [searchPaths[0] stringByAppendingPathComponent:@"Upload"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:uploadDirPath])
        [fileManager removeItemAtPath:uploadDirPath error:nil];
}

#pragma mark - media list methods

- (NSString *)directoryPath
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = searchPaths[0];
    return directoryPath;
}

- (void)updateMediaList
{
    NSString *directoryPath = [self directoryPath];
    NSMutableArray *foundFiles = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil]];
    NSMutableArray *filePaths = [NSMutableArray array];
    NSURL *fileURL;
    while (foundFiles.count) {
        NSString *fileName = foundFiles.firstObject;
        NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
        [foundFiles removeObject:fileName];

        if ([fileName isSupportedMediaFormat] || [fileName isSupportedAudioMediaFormat]) {
            [filePaths addObject:filePath];

            /* exclude media files from backup (QA1719) */
            fileURL = [NSURL fileURLWithPath:filePath];
            [fileURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
        } else {
            BOOL isDirectory = NO;
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];

            // add folders
            if (exists && isDirectory) {
                NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
                for (NSString* file in files) {
                    NSString *fullFilePath = [directoryPath stringByAppendingPathComponent:file];
                    isDirectory = NO;
                    exists = [[NSFileManager defaultManager] fileExistsAtPath:fullFilePath isDirectory:&isDirectory];
                    //only add folders or files in folders
                    if ((exists && isDirectory) || ![filePath.lastPathComponent isEqualToString:@"Documents"]) {
                        NSString *folderpath = [filePath stringByReplacingOccurrencesOfString:directoryPath withString:@""];
                        if (![folderpath isEqualToString:@""]) {
                            folderpath = [folderpath stringByAppendingString:@"/"];
                        }
                        NSString *path = [folderpath stringByAppendingString:file];
                        [foundFiles addObject:path];
                    }
                }
            }
        }
    }
    [[MLMediaLibrary sharedMediaLibrary] addFilePaths:filePaths];
    [_playlistViewController updateViewContents];
}

#pragma mark - pass code validation

- (BOOL)passcodeValidated
{
    return _passcodeValidated;
}

- (void)validatePasscode
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *passcode = [defaults objectForKey:kVLCSettingPasscodeKey];
    if ([passcode isEqualToString:@""] || ![[defaults objectForKey:kVLCSettingPasscodeOnKey] boolValue]) {
        _passcodeValidated = YES;
        return;
    }

    if (!_passcodeValidated) {
        _passcodeLockController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionEnter];
        _passcodeLockController.delegate = self;
        _passcodeLockController.passcode = passcode;

        if (self.window.rootViewController.presentedViewController)
            [self.window.rootViewController dismissViewControllerAnimated:NO completion:nil];

        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:_passcodeLockController];
        navCon.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.window.rootViewController presentViewController:navCon animated:NO completion:nil];
    }
}

- (void)PAPasscodeViewControllerDidEnterPasscode:(PAPasscodeViewController *)controller
{
    _passcodeValidated = YES;
    [self.playlistViewController updateViewContents];
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)PAPasscodeViewController:(PAPasscodeViewController *)controller didFailToEnterPasscode:(NSInteger)attempts
{
    // FIXME: handle countless failed passcode attempts
}

#pragma mark - idle timer preventer
- (void)disableIdleTimer
{
    _idleCounter++;
    if ([UIApplication sharedApplication].idleTimerDisabled == NO)
        [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)activateIdleTimer
{
    _idleCounter--;
    if (_idleCounter < 1)
        [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)networkActivityStarted
{
    _networkActivityCounter++;
    if ([UIApplication sharedApplication].networkActivityIndicatorVisible == NO)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (BOOL)haveNetworkActivity
{
    return _networkActivityCounter >= 1;
}

- (void)networkActivityStopped
{
    _networkActivityCounter--;
    if (_networkActivityCounter < 1)
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - download handling

- (void)downloadMovieFromURL:(NSURL *)url
             fileNameOfMedia:(NSString *)fileName
{
    [self.downloadViewController addURLToDownloadList:url fileNameOfMedia:fileName];

    // select Downloads menu item and reveal corresponding viewcontroller
    [self.menuViewController selectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionNone];
}

#pragma mark - playback view handling

- (void)openMediaFromManagedObject:(NSManagedObject *)mediaObject
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    [vpc playMediaLibraryObject:mediaObject];
}

- (void)openMovieFromURL:(NSURL *)url
         successCallback:(NSURL *)successCallback
           errorCallback:(NSURL *)errorCallback
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];

    vpc.url = url;
    vpc.successCallback = successCallback;
    vpc.errorCallback = errorCallback;

    [vpc startPlayback];
}

- (void)openMovieFromURL:(NSURL *)url
{
    [self openMovieFromURL:url successCallback:nil errorCallback:nil];
}

- (void)openMovieWithExternalSubtitleFromURL:(NSURL *)url externalSubURL:(NSString *)SubtitlePath
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];

    vpc.url = url;
    vpc.pathToExternalSubtitlesFile = SubtitlePath;

    [vpc startPlayback];
}

#pragma mark - watch struff
- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply
{
    /* dispatch background task */
    __block UIBackgroundTaskIdentifier taskIdentifier = [application beginBackgroundTaskWithName:nil
                                                                               expirationHandler:^{
                                                                                   [application endBackgroundTask:taskIdentifier];
                                                                                   taskIdentifier = UIBackgroundTaskInvalid;
    }];

    VLCWatchMessage *message = [[VLCWatchMessage alloc] initWithDictionary:userInfo];
    NSString *name = message.name;
    NSDictionary *responseDict = nil;
    if ([name isEqualToString:VLCWatchMessageNameGetNowPlayingInfo]) {
        responseDict = [self nowPlayingResponseDict];
    } else if ([name isEqualToString:VLCWatchMessageNamePlayPause]) {
        [[VLCPlaybackController sharedInstance] playPause];
        responseDict = @{@"playing": @([VLCPlaybackController sharedInstance].isPlaying)};
    } else if ([name isEqualToString:VLCWatchMessageNameSkipForward]) {
        [[VLCPlaybackController sharedInstance] forward];
    } else if ([name isEqualToString:VLCWatchMessageNameSkipBackward]) {
        [[VLCPlaybackController sharedInstance] backward];
    } else if ([name isEqualToString:VLCWatchMessageNamePlayFile]) {
        [self playFileFromWatch:message];
    } else if ([name isEqualToString:VLCWatchMessageNameSetVolume]) {
        [self setVolumeFromWatch:message];
    } else {
        APLog(@"Did not handle request from WatchKit Extension: %@",userInfo);
    }
    reply(responseDict);
}

- (void)playFileFromWatch:(VLCWatchMessage *)message
{
    NSManagedObject *managedObject = nil;
    NSString *uriString = (id)message.payload;
    if ([uriString isKindOfClass:[NSString class]]) {
        NSURL *uriRepresentation = [NSURL URLWithString:uriString];
        managedObject = [[MLMediaLibrary sharedMediaLibrary] objectForURIRepresentation:uriRepresentation];
    }
    if (managedObject == nil) {
        APLog(@"%s file not found: %@",__PRETTY_FUNCTION__,message);
        return;
    }

    [self openMediaFromManagedObject:managedObject];
}

- (void)setVolumeFromWatch:(VLCWatchMessage *)message
{
    NSNumber *volume = (id)message.payload;
    if ([volume isKindOfClass:[NSNumber class]]) {
        /*
         * Since WatchKit doen't provide something like MPVolumeView we use deprecated API.
         * rdar://20783803 Feature Request: WatchKit equivalent for MPVolumeView
         */
        [MPMusicPlayerController applicationMusicPlayer].volume = volume.floatValue;
    }
}

- (NSDictionary *)nowPlayingResponseDict {
    NSMutableDictionary *response = [NSMutableDictionary new];
    NSMutableDictionary *nowPlayingInfo = [[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo mutableCopy];
    NSNumber *playbackTime = [VLCPlaybackController sharedInstance].mediaPlayer.time.numberValue;
    if (playbackTime) {
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(playbackTime.floatValue/1000);
    }
    if (nowPlayingInfo) {
        response[@"nowPlayingInfo"] = nowPlayingInfo;
    }
    MLFile *currentFile = [VLCPlaybackController sharedInstance].currentlyPlayingMediaFile;
    NSString *URIString = currentFile.objectID.URIRepresentation.absoluteString;
    if (URIString) {
        response[@"URIRepresentation"] = URIString;
    }

    response[@"volume"] = @([MPMusicPlayerController applicationMusicPlayer].volume);

    return response;
}

@end
