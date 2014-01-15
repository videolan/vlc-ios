/*****************************************************************************
 * VLCAppDelegate.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *          Luis Fernandes <zipleen # gmail.com>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppDelegate.h"
#import "VLCMediaFileDiscoverer.h"
#import "NSString+SupportedMedia.h"
#import "UIDevice+SpeedCategory.h"

#import "VLCPlaylistViewController.h"
#import "VLCMovieViewController.h"
#import "PAPasscodeViewController.h"
#import "UINavigationController+Theme.h"
#import "VLCHTTPUploaderController.h"
#import "VLCMenuTableViewController.h"
#import "BWQuincyManager.h"

@interface VLCAppDelegate () <PAPasscodeViewControllerDelegate, VLCMediaFileDiscovererDelegate, BWQuincyManagerDelegate> {
    PAPasscodeViewController *_passcodeLockController;
    VLCDropboxTableViewController *_dropboxTableViewController;
    VLCGoogleDriveTableViewController *_googleDriveTableViewController;
    VLCDownloadViewController *_downloadViewController;
    int _idleCounter;
    VLCMovieViewController *_movieViewController;
}

@property (nonatomic) BOOL passcodeValidated;

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

    NSDictionary *appDefaults = @{kVLCSettingPasscodeKey : @"", kVLCSettingPasscodeOnKey : @(NO), kVLCSettingContinueAudioInBackgroundKey : @(YES), kVLCSettingStretchAudio : @(NO), kVLCSettingTextEncoding : kVLCSettingTextEncodingDefaultValue, kVLCSettingSkipLoopFilter : skipLoopFilterDefaultValue, kVLCSettingSubtitlesFont : kVLCSettingSubtitlesFontDefaultValue, kVLCSettingSubtitlesFontColor : kVLCSettingSubtitlesFontColorDefaultValue, kVLCSettingSubtitlesFontSize : kVLCSettingSubtitlesFontSizeDefaultValue, kVLCSettingDeinterlace : kVLCSettingDeinterlaceDefaultValue};

    [defaults registerDefaults:appDefaults];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BWQuincyManager *quincyManager = [BWQuincyManager sharedQuincyManager];
    [quincyManager setSubmissionURL:@"http://crash.videolan.org/crash_v200.php"];
    [quincyManager setDelegate:self];
    [quincyManager setShowAlwaysButton:YES];
    [quincyManager setFeedbackActivated:YES];

    /* clean caches on launch (since those are used for wifi upload only) */
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* uploadDirPath = [searchPaths[0] stringByAppendingPathComponent:@"Upload"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:uploadDirPath])
        [fileManager removeItemAtPath:uploadDirPath error:nil];

    // Init the HTTP Server
    self.uploadController = [[VLCHTTPUploaderController alloc] init];

    // enable crash preventer
    [[MLMediaLibrary sharedMediaLibrary] applicationWillStart];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

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
    _revealController.contentViewController.view.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];
    [self.window makeKeyAndVisible];

    VLCMediaFileDiscoverer *discoverer = [VLCMediaFileDiscoverer sharedInstance];
    [discoverer addObserver:self];
    [discoverer startDiscovering:[self directoryPath]];

    [self validatePasscode];

    return YES;
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
                APLog(@"saving the file failed (%li): %@", theError.code, theError.localizedDescription);

            [self updateMediaList];
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
                    } else
                        parsedString = [@"http://" stringByAppendingString:[receivedUrl substringFromIndex:6]];

                    url = [NSURL URLWithString:parsedString];
                }
            }
            [self.menuViewController selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self openMovieFromURL:url];
        }
        return YES;
    }
    return NO;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[MLMediaLibrary sharedMediaLibrary] applicationWillStart];
    [self validatePasscode];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    self.passcodeValidated = NO;
    [self validatePasscode];
    [[MLMediaLibrary sharedMediaLibrary] applicationWillExit];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self validatePasscode];
    [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
    [self updateMediaList];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    self.passcodeValidated = NO;
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - properties

- (VLCDropboxTableViewController *)dropboxTableViewController
{
    if (_dropboxTableViewController == nil)
        _dropboxTableViewController = [[VLCDropboxTableViewController alloc] initWithNibName:@"VLCCloudStorageTableViewController" bundle:nil];

    return _dropboxTableViewController;
}

- (VLCGoogleDriveTableViewController *)googleDriveTableViewController
{
    if (_googleDriveTableViewController == nil)
        _googleDriveTableViewController = [[VLCGoogleDriveTableViewController alloc] initWithNibName:@"VLCCloudStorageTableViewController" bundle:nil];

    return _googleDriveTableViewController;
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

- (void)mediaFileAdded:(NSString *)fileName loading:(BOOL)isLoading {
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

- (void)mediaFileDeleted:(NSString *)name {
    [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
    [_playlistViewController updateViewContents];
}

#pragma mark - media list methods

- (NSString *)directoryPath
{
#define LOCAL_PLAYBACK_HACK 0
#if LOCAL_PLAYBACK_HACK && TARGET_IPHONE_SIMULATOR
    NSString *directoryPath = @"/Users/fkuehne/Desktop/VideoLAN docs/Clips/sel/";
#else
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = searchPaths[0];
#endif

    return directoryPath;
}

- (void)updateMediaList
{
    NSString *directoryPath = [self directoryPath];
    NSArray *foundFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];
    NSMutableArray *filePaths = [NSMutableArray arrayWithCapacity:[foundFiles count]];
    NSURL *fileURL;
    for (NSString *fileName in foundFiles) {
        if ([fileName isSupportedMediaFormat] || [fileName isSupportedAudioMediaFormat]) {
            [filePaths addObject:[directoryPath stringByAppendingPathComponent:fileName]];

            /* exclude media files from backup (QA1719) */
            fileURL = [NSURL fileURLWithPath:[directoryPath stringByAppendingPathComponent:fileName]];
            [fileURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
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
        self.passcodeValidated = YES;
        return;
    }

    if (!self.passcodeValidated) {
        _passcodeLockController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionEnter];
        _passcodeLockController.delegate = self;
        _passcodeLockController.passcode = passcode;
        self.window.rootViewController = _passcodeLockController;
    }
}

- (void)PAPasscodeViewControllerDidEnterPasscode:(PAPasscodeViewController *)controller
{
    // TODO add transition animation, i.e. fade
    self.window.rootViewController = self.revealController;
}

- (void)PAPasscodeViewController:(PAPasscodeViewController *)controller didFailToEnterPasscode:(NSInteger)attempts
{
    // TODO handle error attempts
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

#pragma mark - playback view handling

- (void)openMediaFromManagedObject:(NSManagedObject *)mediaObject
{
    if (!_movieViewController)
        _movieViewController = [[VLCMovieViewController alloc] initWithNibName:nil bundle:nil];

    if ([mediaObject isKindOfClass:[MLFile class]])
        _movieViewController.mediaItem = (MLFile *)mediaObject;
    else if ([mediaObject isKindOfClass:[MLAlbumTrack class]])
        _movieViewController.mediaItem = [(MLAlbumTrack*)mediaObject files].anyObject;
    else if ([mediaObject isKindOfClass:[MLShowEpisode class]])
        _movieViewController.mediaItem = [(MLShowEpisode*)mediaObject files].anyObject;

    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:_movieViewController];
    navCon.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.window.rootViewController presentViewController:navCon animated:YES completion:nil];
}

- (void)openMovieFromURL:(NSURL *)url
{
    if (!_movieViewController)
        _movieViewController = [[VLCMovieViewController alloc] initWithNibName:nil bundle:nil];

    _movieViewController.url = url;

    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:_movieViewController];
    navCon.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.window.rootViewController presentViewController:navCon animated:YES completion:nil];
}

- (void)openMediaList:(VLCMediaList*)list atIndex:(int)index
{
    if (!_movieViewController)
        _movieViewController = [[VLCMovieViewController alloc] initWithNibName:nil bundle:nil];

    _movieViewController.mediaList = list;
    _movieViewController.itemInMediaListToBePlayedFirst = index;

    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:_movieViewController];
    navCon.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.window.rootViewController presentViewController:navCon animated:YES completion:nil];
}


@end
