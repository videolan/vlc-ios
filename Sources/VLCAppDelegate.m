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
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppDelegate.h"
#import "VLCMediaFileDiscoverer.h"
#import "NSString+SupportedMedia.h"
#import "UIDevice+VLC.h"

#import "VLCPlaylistViewController.h"
#import "VLCMovieViewController.h"
#import "VLCPlaybackNavigationController.h"
#import "PAPasscodeViewController.h"
#import "UINavigationController+Theme.h"
#import "VLCHTTPUploaderController.h"
#import "VLCMenuTableViewController.h"
#import "VLCMigrationViewController.h"
#import "BWQuincyManager.h"
#import "VLCAlertView.h"
#import <BoxSDK/BoxSDK.h>

@interface VLCAppDelegate () <PAPasscodeViewControllerDelegate, VLCMediaFileDiscovererDelegate, BWQuincyManagerDelegate> {
    PAPasscodeViewController *_passcodeLockController;
    VLCDownloadViewController *_downloadViewController;
    VLCDropboxTableViewController *_dropboxTableViewController;
    int _idleCounter;
    int _networkActivityCounter;
    VLCMovieViewController *_movieViewController;
    BOOL _passcodeValidated;
    BOOL _isRunningMigration;
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

    NSDictionary *appDefaults = @{kVLCSettingPasscodeKey : @"", kVLCSettingPasscodeOnKey : @(NO), kVLCSettingContinueAudioInBackgroundKey : @(YES), kVLCSettingStretchAudio : @(NO), kVLCSettingTextEncoding : kVLCSettingTextEncodingDefaultValue, kVLCSettingSkipLoopFilter : skipLoopFilterDefaultValue, kVLCSettingSubtitlesFont : kVLCSettingSubtitlesFontDefaultValue, kVLCSettingSubtitlesFontColor : kVLCSettingSubtitlesFontColorDefaultValue, kVLCSettingSubtitlesFontSize : kVLCSettingSubtitlesFontSizeDefaultValue, kVLCSettingSubtitlesBoldFont: kVLCSettingSubtitlesBoldFontDefaulValue, kVLCSettingDeinterlace : kVLCSettingDeinterlaceDefaultValue, kVLCSettingNetworkCaching : kVLCSettingNetworkCachingDefaultValue, kVLCSettingPlaybackGestures : [NSNumber numberWithBool:YES], kVLCSettingFTPTextEncoding : kVLCSettingFTPTextEncodingDefaultValue, kVLCSettingWiFiSharingIPv6 : kVLCSettingWiFiSharingIPv6DefaultValue, kVLCSettingEqualizerProfile : kVLCSettingEqualizerProfileDefaultValue};

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

    BWQuincyManager *quincyManager = [BWQuincyManager sharedQuincyManager];
    [quincyManager setSubmissionURL:@"http://crash.videolan.org/crash_v200.php"];
    [quincyManager setDelegate:self];
    [quincyManager setShowAlwaysButton:YES];
    [quincyManager startManager];

    /* clean caches on launch (since those are used for wifi upload only) */
    [self cleanCache];

    // Init the HTTP Server
    self.uploadController = [[VLCHTTPUploaderController alloc] init];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // enable crash preventer
     void (^setupBlock)() = ^ {
        [[MLMediaLibrary sharedMediaLibrary] applicationWillStart];

        _playlistViewController = [[VLCPlaylistViewController alloc] init];
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:_playlistViewController];
        [navCon loadTheme];

        _revealController = [[GHRevealViewController alloc] initWithNibName:nil bundle:nil];
        _revealController.wantsFullScreenLayout = YES;
        _menuViewController = [[VLCMenuTableViewController alloc] initWithNibName:nil bundle:nil];
        _revealController.sidebarViewController = _menuViewController;
        _revealController.contentViewController = navCon;

        self.window.rootViewController = self.revealController;
        // necessary to avoid navbar blinking in VLCOpenNetworkStreamViewController & VLCDownloadViewController
        _revealController.contentViewController.view.backgroundColor = [UIColor VLCDarkBackgroundColor];
        [self.window makeKeyAndVisible];

        VLCMediaFileDiscoverer *discoverer = [VLCMediaFileDiscoverer sharedInstance];
        [discoverer addObserver:self];
        [discoverer startDiscovering:[self directoryPath]];

        [self validatePasscode];
    };

    NSError *error = nil;
    if ([self migrationNeeded:&error]){
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
            NSLog(@"removed persistentStore since it was corrupt");
            NSURL *storeURL = ((MLMediaLibrary *)[MLMediaLibrary sharedMediaLibrary]).persistentStoreURL;
            [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
        }
        setupBlock();
    }
    return YES;
}

- (BOOL)migrationNeeded:(NSError **) migrationCheckError {

    BOOL migrationNeeded = NO;

    if ([[NSFileManager defaultManager] fileExistsAtPath:((MLMediaLibrary *)[MLMediaLibrary sharedMediaLibrary]).persistentStoreURL.path]) {
        NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                                                                  URL:((MLMediaLibrary *)[MLMediaLibrary sharedMediaLibrary]).persistentStoreURL
                                                                                                error:migrationCheckError];
        if (*migrationCheckError) {
            return NO;
        }
        NSManagedObjectModel *destinationModel = [[MLMediaLibrary sharedMediaLibrary] managedObjectModel];
        migrationNeeded = ![destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
    }

    return migrationNeeded;
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
            NSURL *movieURL = nil;
            NSURL *successCallback = nil;
            NSString *fileName = nil;
            for (NSString *entry in [url.query componentsSeparatedByString:@"&"]) {
                NSArray *keyvalue = [entry componentsSeparatedByString:@"="];
                if (keyvalue.count < 2) continue;
                NSString *key = keyvalue[0];
                NSString *value = [keyvalue[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                if ([key isEqualToString:@"url"]) {
                    movieURL = [NSURL URLWithString:value];
                }
                else if ([key isEqualToString:@"filename"]) {
                    fileName = value;
                }
                else if ([key isEqualToString:@"x-success"]) {
                    successCallback = [NSURL URLWithString:value];
                }
            }
            if ([action isEqualToString:@"stream"] && movieURL) {
                [self openMovieFromURL:movieURL successCallback:successCallback];
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
                VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"OPEN_STREAM_OR_DOWNLOAD", nil) message:url.absoluteString cancelButtonTitle:NSLocalizedString(@"BUTTON_DOWNLOAD", nil) otherButtonTitles:@[NSLocalizedString(@"BUTTON_PLAY", nil)]];
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
    if (!_isRunningMigration) {
        [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
        [self updateMediaList];
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
    if (!_movieViewController)
        _movieViewController = [[VLCMovieViewController alloc] initWithNibName:nil bundle:nil];

    if ([mediaObject isKindOfClass:[MLFile class]])
        _movieViewController.fileFromMediaLibrary = (MLFile *)mediaObject;
    else if ([mediaObject isKindOfClass:[MLAlbumTrack class]])
        _movieViewController.fileFromMediaLibrary = [(MLAlbumTrack*)mediaObject files].anyObject;
    else if ([mediaObject isKindOfClass:[MLShowEpisode class]])
        _movieViewController.fileFromMediaLibrary = [(MLShowEpisode*)mediaObject files].anyObject;
    [(MLFile *)_movieViewController.fileFromMediaLibrary setUnread:@(NO)];

    UINavigationController *navCon = [[VLCPlaybackNavigationController alloc] initWithRootViewController:_movieViewController];
    navCon.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.window.rootViewController presentViewController:navCon animated:YES completion:nil];
}

- (void)openMovieFromURL:(NSURL *)url
         successCallback:(NSURL *)successCallback
{
    if (!_movieViewController)
        _movieViewController = [[VLCMovieViewController alloc] initWithNibName:nil bundle:nil];

    _movieViewController.url = url;
    _movieViewController.successCallback = successCallback;

    UINavigationController *navCon = [[VLCPlaybackNavigationController alloc] initWithRootViewController:_movieViewController];
    navCon.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.window.rootViewController presentViewController:navCon animated:YES completion:nil];
}

- (void)openMovieFromURL:(NSURL *)url
{
    [self openMovieFromURL:url successCallback:nil];
}

- (void)openMediaList:(VLCMediaList *)list atIndex:(int)index
{
    if (!_movieViewController)
        _movieViewController = [[VLCMovieViewController alloc] initWithNibName:nil bundle:nil];

    _movieViewController.mediaList = list;
    _movieViewController.itemInMediaListToBePlayedFirst = index;
    _movieViewController.pathToExternalSubtitlesFile = nil;

    UINavigationController *navCon = [[VLCPlaybackNavigationController alloc] initWithRootViewController:_movieViewController];
    navCon.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.window.rootViewController presentViewController:navCon animated:YES completion:nil];
}

- (void)openMovieWithExternalSubtitleFromURL:(NSURL *)url externalSubURL:(NSString *)SubtitlePath
{
    if (!_movieViewController)
        _movieViewController = [[VLCMovieViewController alloc] initWithNibName:nil bundle:nil];

    _movieViewController.url = url;
    _movieViewController.pathToExternalSubtitlesFile = SubtitlePath;

    UINavigationController *navCon = [[VLCPlaybackNavigationController alloc] initWithRootViewController:_movieViewController];
    navCon.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.window.rootViewController presentViewController:navCon animated:YES completion:nil];
}

@end
