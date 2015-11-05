/*****************************************************************************
 * VLCHTTPUploaderViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Jean-Baptiste Kempf <jb # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCHTTPUploaderController.h"
#import "VLCHTTPConnection.h"
#import "VLCActivityManager.h"
#import "HTTPServer.h"
#import "Reachability.h"

#import <ifaddrs.h>
#import <arpa/inet.h>

#if TARGET_OS_IOS
#import "VLCMediaFileDiscoverer.h"
#endif

@interface VLCHTTPUploaderController()

@property(nonatomic, strong) HTTPServer *httpServer;

@end

@implementation VLCHTTPUploaderController
{
    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
    Reachability *_reachability;
}

+ (instancetype)sharedInstance
{
    static VLCHTTPUploaderController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [VLCHTTPUploaderController new];
    });

    return sharedInstance;
}

- (id)init
{
    if (self = [super init]) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(applicationDidBecomeActive:)
            name:UIApplicationDidBecomeActiveNotification object:nil];
        [center addObserver:self selector:@selector(applicationDidEnterBackground:)
            name:UIApplicationDidEnterBackgroundNotification object:nil];
        [center addObserver:self selector:@selector(netReachabilityChanged) name:kReachabilityChangedNotification object:nil];
        
        BOOL isHTTPServerOn = [[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingSaveHTTPUploadServerStatus];
        [self changeHTTPServerState:isHTTPServerOn];

    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
            dispatch_block_t expirationHandler = ^{
                [self changeHTTPServerState:NO];
                [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
                _backgroundTaskIdentifier = 0;
            };
            if ([[UIApplication sharedApplication] respondsToSelector:@selector(beginBackgroundTaskWithName:expirationHandler:)]) {
                _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"VLCUploader" expirationHandler:expirationHandler];
            } else {
                _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:expirationHandler];
            }
        }
    }
}

- (NSString *)httpStatus
{
    if (self.httpServer.isRunning) {
        if (self.httpServer.listeningPort != 80) {
            return [NSString stringWithFormat:@"http://%@:%i\nhttp://%@:%i", [self currentIPAddress], self.httpServer.listeningPort, [self hostname], self.httpServer.listeningPort];
        } else {
            return [NSString stringWithFormat:@"http://%@\nhttp://%@", [self currentIPAddress], [self hostname]];
        }
    } else {
        return NSLocalizedString(@"HTTP_UPLOAD_SERVER_OFF", nil);
    }
}

- (BOOL)isServerRunning
{
    return self.httpServer.isRunning;
}

- (void)netReachabilityChanged
{
    if (_reachability.currentReachabilityStatus != ReachableViaWiFi) {
        [[VLCHTTPUploaderController sharedInstance] changeHTTPServerState:NO];
    }
}

- (BOOL)changeHTTPServerState:(BOOL)state
{
    if (!state) {
        [self.httpServer stop];
        return true;
    }
    // clean cache before accepting new stuff
    [self cleanCache];

    // Initialize our http server
    _httpServer = [[HTTPServer alloc] init];

    // find an interface to listen on
    struct ifaddrs *listOfInterfaces = NULL;
    struct ifaddrs *anInterface = NULL;
    NSString *interfaceToUse = nil;
    int ret = getifaddrs(&listOfInterfaces);
    if (ret == 0) {
        anInterface = listOfInterfaces;

        while (anInterface != NULL) {
            if (anInterface->ifa_addr->sa_family == AF_INET) {
                APLog(@"Found interface %s", anInterface->ifa_name);

                /* check for primary interface first */
                if (strncmp (anInterface->ifa_name,"en0",strlen("en0")) == 0) {
                    unsigned int flags = anInterface->ifa_flags;
                    if( (flags & 0x1) && (flags & 0x40) && !(flags & 0x8) ) {
                        interfaceToUse = [NSString stringWithUTF8String:anInterface->ifa_name];
                        break;
                    }
                }

                /* oh well, let's move on to the secondary interface */
                if (strncmp (anInterface->ifa_name,"en1",strlen("en1")) == 0) {
                    unsigned int flags = anInterface->ifa_flags;
                    if( (flags & 0x1) && (flags & 0x40) && !(flags & 0x8) ) {
                        interfaceToUse = [NSString stringWithUTF8String:anInterface->ifa_name];
                        break;
                    }
                }
            }
            anInterface = anInterface->ifa_next;
        }
        freeifaddrs(listOfInterfaces);
    }
    if (interfaceToUse == nil)
        return false;

    [_httpServer setInterface:interfaceToUse];

    [_httpServer setIPv4Enabled:YES];
    [_httpServer setIPv6Enabled:[[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingWiFiSharingIPv6] boolValue]];

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
        if (error.code == EACCES) {
            APLog(@"Port forbidden by OS, trying another one");
            [self.httpServer setPort:8888];
            if(![self.httpServer start:&error])
                return true;
        }

        /* Address already in Use, take a random one */
        if (error.code == EADDRINUSE) {
            APLog(@"Port already in use, trying another one");
            [self.httpServer setPort:0];
            if(![self.httpServer start:&error])
                return true;
        }

        if (error) {
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

- (NSString *)hostname
{
    char baseHostName[256];
    int success = gethostname(baseHostName, 255);
    if (success != 0)
        return nil;
    baseHostName[255] = '\0';

#if !TARGET_IPHONE_SIMULATOR
    return [NSString stringWithFormat:@"%s.local", baseHostName];
#else
    return [NSString stringWithFormat:@"%s", baseHostName];
#endif
}

- (void)moveFileFrom:(NSString *)filepath
{
    /* update media library when file upload was completed */
    VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
    [activityManager networkActivityStopped];
    [activityManager activateIdleTimer];

#if TARGET_OS_IOS
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

    [[VLCMediaFileDiscoverer sharedInstance] performSelectorOnMainThread:@selector(updateMediaList) withObject:nil waitUntilDone:NO];
#endif
}

- (void)cleanCache
{
    if ([[VLCActivityManager defaultManager] haveNetworkActivity])
        return;

    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* uploadDirPath = [searchPaths[0] stringByAppendingPathComponent:@"Upload"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:uploadDirPath])
        [fileManager removeItemAtPath:uploadDirPath error:nil];
}

@end
