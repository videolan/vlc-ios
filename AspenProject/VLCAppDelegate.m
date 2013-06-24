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
#import "DirectoryWatcher.h"
#import "NSString+SupportedMedia.h"
#import "UIDevice+SpeedCategory.h"

#import "VLCPlaylistViewController.h"
#import "VLCMovieViewController.h"
#import "PAPasscodeViewController.h"
#import "UINavigationController+Theme.h"

@interface VLCAppDelegate () <PAPasscodeViewControllerDelegate, DirectoryWatcherDelegate> {
    NSURL *_tempURL;
    PAPasscodeViewController *_passcodeLockController;
    VLCDropboxTableViewController *_dropboxTableViewController;

    DirectoryWatcher *_directoryWatcher;
    NSTimer *_addMediaTimer;
    NSMutableDictionary *_addedFiles;
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

    NSDictionary *appDefaults = @{kVLCSettingPasscodeKey : @"", kVLCSettingPasscodeOnKey : @(NO), kVLCSettingContinueAudioInBackgroundKey : @(YES), kVLCSettingStretchAudio : @(NO), kVLCSettingTextEncoding : kVLCSettingTextEncodingDefaultValue, kVLCSettingSkipLoopFilter : skipLoopFilterDefaultValue};

    [defaults registerDefaults:appDefaults];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    _playlistViewController = [[VLCPlaylistViewController alloc] init];

    self.navigationController = [[UINavigationController alloc] initWithRootViewController:_playlistViewController];
    [self.navigationController loadTheme];

    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];

    _directoryWatcher = [DirectoryWatcher watchFolderWithPath:[self directoryPath] delegate:self];

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
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SAVE_FILE", @"") message:[NSString stringWithFormat:NSLocalizedString(@"SAVE_FILE_LONG", @""), url.lastPathComponent] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"") otherButtonTitles:NSLocalizedString(@"BUTTON_SAVE", @""), nil];
            _tempURL = url;
            [alert show];
        } else
            [_playlistViewController openMovieFromURL:url];
        return YES;
    }
    return NO;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *directoryPath = searchPaths[0];
        NSURL *destinationURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", directoryPath, _tempURL.lastPathComponent]];
        NSError *theError;
        [[NSFileManager defaultManager] copyItemAtURL:_tempURL toURL:destinationURL error:&theError];
        if (theError.code != noErr)
            APLog(@"saving the file failed (%i): %@", theError.code, theError.localizedDescription);

        [self updateMediaList];
    } else
        [_playlistViewController openMovieFromURL:_tempURL];
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

#pragma mark - properties

- (VLCDropboxTableViewController *)dropboxTableViewController
{
    if (_dropboxTableViewController == nil) {
        _dropboxTableViewController = [[VLCDropboxTableViewController alloc] initWithNibName:nil bundle:nil];
    }

    return _dropboxTableViewController;
}

#pragma mark - directory watcher delegate

- (void)addFileTimerFired
{
    NSArray *allKeys = [_addedFiles allKeys];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    MLMediaLibrary *sharedLibrary = [MLMediaLibrary sharedMediaLibrary];
    for (NSString *fileURL in allKeys) {
        if (![fileManager fileExistsAtPath:fileURL])
            continue;

        NSDictionary *attribs = [fileManager attributesOfItemAtPath:fileURL error:nil];

        NSNumber *prevFetchedSize = [_addedFiles objectForKey:fileURL];
        NSNumber *updatedSize = [attribs objectForKey:NSFileSize];
        if (!updatedSize)
            continue;

        if ([prevFetchedSize compare:updatedSize] == NSOrderedSame) {
            [_addedFiles removeObjectForKey:fileURL];
            [sharedLibrary addFilePaths:@[fileURL]];

            /* exclude media files from backup (QA1719) */
            NSURL *excludeURL = [NSURL fileURLWithPath:fileURL];
            [excludeURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];

            // TODO Should we update media db after adding new files?
            [sharedLibrary updateMediaDatabase];
            [_playlistViewController updateViewContents];
        } else
            [_addedFiles setObject:updatedSize forKey:fileURL];
    }

    if (_addedFiles.count == 0) {
        [_addMediaTimer invalidate];
        _addMediaTimer = nil;
    }
}

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher
{
    NSArray *foundFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self directoryPath] error:nil];
    NSMutableArray *matchedFiles = [NSMutableArray arrayWithCapacity:foundFiles.count];
    for (NSString *fileName in foundFiles) {
        if ([fileName isSupportedMediaFormat])
            [matchedFiles addObject:[[self directoryPath] stringByAppendingPathComponent:fileName]];
    }

    NSArray *mediaFiles = [MLFile allFiles];
    if (mediaFiles.count > matchedFiles.count) { // File was deleted
        [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
        [_playlistViewController updateViewContents];

    } else if (mediaFiles.count < matchedFiles.count) { // File was added
        NSMutableArray *addedFiles = [NSMutableArray array];
        for (NSString *fileName in matchedFiles) {
            NSURL *fileURL = [NSURL fileURLWithPath:fileName];

            BOOL found = NO;
            for (MLFile *mediaFile in mediaFiles) {
                if ([mediaFile.url isEqualToString:fileURL.absoluteString])
                    found = YES;
            }

            if (!found)
                [addedFiles addObject:fileName];
        }

        _addedFiles = [NSMutableDictionary dictionaryWithCapacity:[addedFiles count]];
        for (NSString *fileURL in addedFiles)
            [_addedFiles setObject:@(0) forKey:fileURL];

        _addMediaTimer = [NSTimer scheduledTimerWithTimeInterval:2. target:self
                                                        selector:@selector(addFileTimerFired)
                                                        userInfo:nil repeats:YES];
    }
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
        if ([fileName isSupportedMediaFormat]) {
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
    self.window.rootViewController = self.navigationController;
}

- (void)PAPasscodeViewController:(PAPasscodeViewController *)controller didFailToEnterPasscode:(NSInteger)attempts
{
    // TODO handle error attempts
}

@end
