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

@implementation VLCAppDelegate

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *appDefaults = @{@"Passcode" : @"", @"PasscodeProtection" : @0};

    [defaults registerDefaults:appDefaults];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    _playlistViewController = [[VLCPlaylistViewController alloc] initWithNibName:@"VLCPlaylistViewController" bundle:nil];

    self.navigationController = [[UINavigationController alloc] initWithRootViewController:_playlistViewController];
    self.window.rootViewController = self.navigationController;

    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    [self.window makeKeyAndVisible];

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
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
        NSString *directoryPath = [searchPaths objectAtIndex:0];
        NSURL *destinationURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@/%@", directoryPath, _tempURL.lastPathComponent]];
        NSError *theError;
        [[NSFileManager defaultManager] copyItemAtURL:_tempURL toURL:destinationURL error:&theError];

        [self updateMediaList];
    }

    [_playlistViewController openMovieFromURL:_tempURL];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[MLMediaLibrary sharedMediaLibrary] applicationWillExit];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![[defaults objectForKey:@"Passcode"] isEqualToString:@""])
        self.playlistViewController.passcodeValidated = NO;
    else
        self.playlistViewController.passcodeValidated = YES;

    NSLog(@"applicationWillEnterForeground: %i", self.playlistViewController.passcodeValidated);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self updateMediaList];
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
    NSString *directoryPath = [searchPaths objectAtIndex:0];
#endif
    NSArray *foundFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];
    NSMutableArray *filePaths = [NSMutableArray arrayWithCapacity:[foundFiles count]];
    NSURL *fileURL;
    for (NSString *fileName in foundFiles) {
        if ([fileName rangeOfString:@"\\.(3gp|3gp|3gp2|3gpp|amv|asf|avi|axv|divx|dv|flv|f4v|gvi|gxf|m1v|m2p|m2t|m2ts|m2v|m4v|mks|mkv|moov|mov|mp2v|mp4|mpeg|mpeg1|mpeg2|mpeg4|mpg|mpv|mt2s|mts|mxf|nsv|nuv|oga|ogg|ogm|ogv|ogx|spx|ps|qt|rar|rec|rm|rmvb|tod|ts|tts|vob|vro|webm|wm|wmv|wtv|xesc)$" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch].length != 0) {
            [filePaths addObject:[directoryPath stringByAppendingPathComponent:fileName]];

            /* exclude media files from backup (QA1719) */
            fileURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@/%@", directoryPath, fileName]];
            [fileURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
        }
    }
    [[MLMediaLibrary sharedMediaLibrary] addFilePaths:filePaths];
    [_playlistViewController updateViewContents];
}

@end
