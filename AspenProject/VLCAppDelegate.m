//
//  VLCAppDelegate.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCAppDelegate.h"

#import "VLCPlaylistViewController.h"
#import "VLCMovieViewController.h"
#import "PAPasscodeViewController.h"

@interface VLCAppDelegate () <PAPasscodeViewControllerDelegate>

@property (nonatomic) BOOL passcodeValidated;

@end

@implementation VLCAppDelegate

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *appDefaults = @{kVLCSettingPasscodeKey : @"", kVLCSettingPasscodeOnKey : @(NO), kVLCSettingContinueAudioInBackgroundKey : @(YES), kVLCSettingStretchAudio : @(NO), kVLCSettingTextEncoding : kVLCSettingTextEncodingDefaultValue};

    [defaults registerDefaults:appDefaults];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    _playlistViewController = [[VLCPlaylistViewController alloc] init];

    self.navigationController = [[UINavigationController alloc] initWithRootViewController:_playlistViewController];
    UINavigationBar *navBar = self.navigationController.navigationBar;
    [navBar setBackgroundImage:[UIImage imageNamed:@"navBarBackground"] forBarMetrics:UIBarMetricsDefault];
    navBar.barStyle = UIBarStyleBlack;

    self.window.rootViewController = self.navigationController;

    [self.window makeKeyAndVisible];

    _dropboxTableViewController = [[VLCDropboxTableViewController alloc] initWithNibName:@"VLCDropboxTableViewController" bundle:nil];

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

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    APLog(@"applicationWillEnterForeground: %i", self.passcodeValidated);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self updateMediaList];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self validatePasscode]; // Lock library when going to background
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)updateMediaList
{
#define LOCAL_PLAYBACK_HACK 1
#if LOCAL_PLAYBACK_HACK && TARGET_IPHONE_SIMULATOR
    NSString *directoryPath = @"/Users/fkuehne/Desktop/VideoLAN docs/Clips/sel/";
#else
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = searchPaths[0];
#endif
    NSArray *foundFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];
    NSMutableArray *filePaths = [NSMutableArray arrayWithCapacity:[foundFiles count]];
    NSURL *fileURL;
    for (NSString *fileName in foundFiles) {
        if ([fileName rangeOfString:kSupportedFileExtensions options:NSRegularExpressionSearch|NSCaseInsensitiveSearch].length != 0) {
            [filePaths addObject:[directoryPath stringByAppendingPathComponent:fileName]];

            /* exclude media files from backup (QA1719) */
            fileURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@/%@", directoryPath, fileName]];
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
