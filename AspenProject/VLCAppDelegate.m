//
//  VLCAppDelegate.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCAppDelegate.h"
#import "VLCMediaFileDiscoverer.h"
#import "NSString+SupportedMedia.h"
#import "UIDevice+SpeedCategory.h"

#import "VLCPlaylistViewController.h"
#import "VLCMenuViewController.h"
#import "VLCMovieViewController.h"
#import "PAPasscodeViewController.h"
#import "UINavigationController+Theme.h"
#import "VLCHTTPUploaderController.h"

@interface VLCAppDelegate () <PAPasscodeViewControllerDelegate, VLCMediaFileDiscovererDelegate> {
    PAPasscodeViewController *_passcodeLockController;
    VLCDropboxTableViewController *_dropboxTableViewController;
    int _idleCounter;
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
    // Init the HTTP Server
    self.uploadController = [[VLCHTTPUploaderController alloc] init];

    // enable crash preventer
    [[MLMediaLibrary sharedMediaLibrary] applicationWillStart];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    _playlistViewController = [[VLCPlaylistViewController alloc] init];
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:_playlistViewController];
    [navCon loadTheme];

    _revealController = [[GHRevealViewController alloc] initWithNibName:nil bundle:nil];
    _revealController.sidebarViewController = [[VLCMenuViewController alloc] initWithNibName:nil bundle:nil];
    _revealController.contentViewController = navCon;

    self.window.rootViewController = self.revealController;
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
                APLog(@"saving the file failed (%i): %@", theError.code, theError.localizedDescription);

            [self updateMediaList];
        } else {
            NSURL *parsedUrl = [self parseOpenURL:url];

            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.playlistViewController];
            [navController loadTheme];

            self.revealController.contentViewController = navController;
            [self.revealController toggleSidebar:NO duration:kGHRevealSidebarDefaultAnimationDuration];
            [self.playlistViewController performSelector:@selector(openMovieFromURL:) withObject:parsedUrl afterDelay:kGHRevealSidebarDefaultAnimationDuration];
        }
        return YES;
    }
    return NO;
}

- (NSURL *)parseOpenURL:(NSURL *)url
{
    NSString *receivedUrl = [url absoluteString];
    if ([receivedUrl length] > 6) {
        NSString *verifyVlcUrl = [receivedUrl substringToIndex:6];
        if ([verifyVlcUrl isEqualToString:@"vlc://"]) {
            NSString *parsedString = [receivedUrl substringFromIndex:6];

            // "url decode" so we can parse http:// links
            parsedString = [parsedString stringByReplacingOccurrencesOfString:@"+"withString:@" "];
            parsedString = [parsedString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

            // add http:// if nothing is there
            NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeLink error:nil];
            NSUInteger parsedStringLength = [parsedString length];
            NSUInteger numberOfUrlMatches = [detector numberOfMatchesInString:parsedString options:0 range:NSMakeRange(0, parsedStringLength)];
            if (numberOfUrlMatches == 0) {
                parsedString = [@"http://" stringByAppendingString:parsedString];
            }

            NSURL *targetUrl = [NSURL URLWithString:parsedString];
            return targetUrl;
        }
    }
    return url;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[MLMediaLibrary sharedMediaLibrary] applicationWillStart];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[MLMediaLibrary sharedMediaLibrary] applicationWillExit];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
    [self updateMediaList];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self validatePasscode]; // Lock library when going to background
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - properties

- (VLCDropboxTableViewController *)dropboxTableViewController
{
    if (_dropboxTableViewController == nil) {
        _dropboxTableViewController = [[VLCDropboxTableViewController alloc] initWithNibName:nil bundle:nil];
    }

    return _dropboxTableViewController;
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
        if ([self.nextPasscodeCheckDate earlierDate:[NSDate date]] == self.nextPasscodeCheckDate) {
            _passcodeLockController = [[PAPasscodeViewController alloc] initForAction:PasscodeActionEnter];
            _passcodeLockController.delegate = self;
            _passcodeLockController.passcode = passcode;
            self.window.rootViewController = _passcodeLockController;
        } else
            self.passcodeValidated = YES;
    }
}

- (void)PAPasscodeViewControllerDidEnterPasscode:(PAPasscodeViewController *)controller
{
    // TODO add transition animation, i.e. fade
    self.nextPasscodeCheckDate = [NSDate dateWithTimeIntervalSinceNow:300];
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

@end
