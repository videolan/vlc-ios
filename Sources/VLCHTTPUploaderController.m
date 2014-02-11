/*****************************************************************************
 * VLCHTTPUploaderViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Jean-Baptiste Kempf <jb # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCAppDelegate.h"
#import "VLCHTTPUploaderController.h"
#import "VLCHTTPConnection.h"

#import "HTTPServer.h"

#import <ifaddrs.h>
#import <arpa/inet.h>

@implementation VLCHTTPUploaderController
{
    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
}

- (id)init
{
    if (self = [super init]) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(applicationDidBecomeActive:)
            name:UIApplicationDidBecomeActiveNotification object:nil];
        [center addObserver:self selector:@selector(applicationDidEnterBackground:)
            name:UIApplicationDidEnterBackgroundNotification object:nil];
    }

    return self;
}

- (void)applicationDidBecomeActive: (NSNotification *)notification
{
    if (!self.httpServer.isRunning)
        [self changeHTTPServerState:[[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingSaveHTTPUploadServerStatus]];

    if (_backgroundTaskIdentifier && _backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
        _backgroundTaskIdentifier = 0;
    }
}

- (void)applicationDidEnterBackground: (NSNotification *)notification
{
    if (self.httpServer.isRunning) {
        if (!_backgroundTaskIdentifier || _backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
            _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"VLCUploader" expirationHandler:^{
                [self changeHTTPServerState:NO];
                [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
                _backgroundTaskIdentifier = 0;
            }];
        }
    }
}

- (BOOL)changeHTTPServerState:(BOOL)state
{
    if (!state) {
        [self.httpServer stop];
        return true;
    }
    // Initialize our http server
    _httpServer = [[HTTPServer alloc] init];
    [_httpServer setInterface:WifiInterfaceName];

    // Tell the server to broadcast its presence via Bonjour.
    // This allows browsers such as Safari to automatically discover our service.
    [self.httpServer setType:@"_http._tcp."];

    // Serve files from the standard Sites folder
    NSString *docRoot = [[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"] stringByDeletingLastPathComponent];

    APLog(@"Setting document root: %@", docRoot);

    [self.httpServer setDocumentRoot:docRoot];
    [self.httpServer setPort:80];

    [self.httpServer setConnectionClass:[VLCHTTPConnection class]];

    NSError *error = nil;
    if (![self.httpServer start:&error]) {
        if (error.code == 13) {
            APLog(@"Port forbidden by OS, trying another one");
            [self.httpServer setPort:8888];
            if(![self.httpServer start:&error])
                return true;
        }

        /* Address already in Use, take a random one */
        if (error.code == 48) {
            APLog(@"Port already in use, trying another one");
            [self.httpServer setPort:0];
            if(![self.httpServer start:&error])
                return true;
        }

        if (error.code != 0) {
            APLog(@"Error starting HTTP Server: %@", error.localizedDescription);
            [self.httpServer stop];
        }
        return false;
    }
    return true;
}

- (NSString *)currentIPAddress
{
    NSString *address = @"";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = getifaddrs(&interfaces);

    if (success != 0) {
        freeifaddrs(interfaces);
        return address;
    }

    temp_addr = interfaces;
    while (temp_addr != NULL) {
        if (temp_addr->ifa_addr->sa_family == AF_INET) {
            if([@(temp_addr->ifa_name) isEqualToString:WifiInterfaceName])
                address = @(inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr));
        }
        temp_addr = temp_addr->ifa_next;
    }

    freeifaddrs(interfaces);
    return address;
}

- (void)moveFileFrom:(NSString *)filepath
{
    NSString *fileName = [filepath lastPathComponent];
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = searchPaths[0];
    NSString *finalFilePath = [libraryPath stringByAppendingPathComponent:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:finalFilePath]) {
        /* we don't want to over-write existing files, so add an integer to the file name */
        NSString *potentialFilename;
        NSString *fileExtension = [fileName pathExtension];
        NSString *rawFileName = [fileName stringByDeletingPathExtension];
        for (NSUInteger x = 1; x < 100; x++) {
            potentialFilename = [NSString stringWithFormat:@"%@ %lu.%@", rawFileName, (unsigned long)x, fileExtension];
            if (![[NSFileManager defaultManager] fileExistsAtPath:[libraryPath stringByAppendingPathComponent:potentialFilename]])
                break;
        }
        finalFilePath = [libraryPath stringByAppendingPathComponent:potentialFilename];
    }

    NSError *error;
    [fileManager moveItemAtPath:filepath toPath:finalFilePath error:&error];
    if (error) {
        APLog(@"Moving received media %@ to library folder failed (%li), deleting", fileName, (long)error.code);
        [fileManager removeItemAtPath:filepath error:nil];
    }

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [(VLCAppDelegate*)[UIApplication sharedApplication].delegate activateIdleTimer];

    /* update media library when file upload was completed */
    VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate performSelectorOnMainThread:@selector(updateMediaList) withObject:nil waitUntilDone:NO];
}

@end
