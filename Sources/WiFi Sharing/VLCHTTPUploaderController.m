/*****************************************************************************
 * VLCHTTPUploaderController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2020 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Jean-Baptiste Kempf <jb # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *          Jean-Romain Prévost <jr # 3on.fr>
 *          Carola Nitz <caro # videolan.org>
 *          Ron Soffer <rsoffer1 # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCHTTPUploaderController.h"
#import "VLCHTTPConnection.h"
#import "VLCActivityManager.h"
#import "HTTPServer.h"
#import "Reachability.h"

#import <ifaddrs.h>
#import <net/if.h>
#import <arpa/inet.h>

#import "NSString+SupportedMedia.h"

#if TARGET_OS_IOS
#import "VLC-Swift.h"
#import "VLCMediaFileDiscoverer.h"
#endif

NSString *VLCHTTPUploaderBackgroundTaskName = @"VLCHTTPUploaderBackgroundTaskName";

@interface VLCHTTPUploaderController()
{
    HTTPServer *_httpServer;
    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
    Reachability *_reachability;

    NSTimer *_idleTimer;
    NSMutableSet<NSString *> *_playlistUploadPaths;
}
@end

@implementation VLCHTTPUploaderController

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
        [center addObserver:self
                   selector:@selector(applicationDidBecomeActive:)
                       name:UIApplicationDidBecomeActiveNotification
                     object:nil];
        [center addObserver:self
                   selector:@selector(netReachabilityChanged)
                       name:kReachabilityChangedNotification
                     object:nil];

        BOOL isHTTPServerOn = [[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingSaveHTTPUploadServerStatus];
        [self netReachabilityChanged];
        [self changeHTTPServerState:isHTTPServerOn];
        _playlistUploadPaths = [NSMutableSet set];
    }

    return self;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if (!_httpServer.isRunning)
        [self changeHTTPServerState:[[NSUserDefaults standardUserDefaults] boolForKey:kVLCSettingSaveHTTPUploadServerStatus]];
}

- (void)beginBackgroundTask
{
    if (!_backgroundTaskIdentifier || _backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        dispatch_block_t expirationHandler = ^{
            [self changeHTTPServerState:NO];
            [[UIApplication sharedApplication] endBackgroundTask:self->_backgroundTaskIdentifier];
            self->_backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        };
        _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:VLCHTTPUploaderBackgroundTaskName
                                                                                 expirationHandler:expirationHandler];
    }
}

- (void)endBackgroundTask
{
    if (_backgroundTaskIdentifier && _backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
        _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
}

- (NSString *)httpStatus
{
    if (_httpServer.isRunning) {
        if (_httpServer.listeningPort != 80) {
            return [NSString stringWithFormat:@"http://%@:%i\nhttp://%@:%i",
                    [self currentIPAddress],
                    _httpServer.listeningPort,
                    [self hostname],
                    _httpServer.listeningPort];
        } else {
            return [NSString stringWithFormat:@"http://%@\nhttp://%@",
                    [self currentIPAddress],
                    [self hostname]];
        }
    } else {
        return NSLocalizedString(@"HTTP_UPLOAD_SERVER_OFF", nil);
    }
}

- (NSString *)addressToCopy
{
    if (_httpServer.isRunning) {
        if (_httpServer.listeningPort != 80) {
            return [NSString stringWithFormat:@"http://%@:%i", [self currentIPAddress], _httpServer.listeningPort];
        } else {
            return [NSString stringWithFormat:@"http://%@", [self currentIPAddress]];
        }
    } else {
        return NSLocalizedString(@"HTTP_UPLOAD_SERVER_OFF", nil);
    }
}

- (BOOL)isServerRunning
{
    return _httpServer.isRunning;
}

- (BOOL)isUsingEthernet
{
    return [_nameOfUsedNetworkInterface isEqualToString:@"en3"];
}

- (void)netReachabilityChanged
{
    // find an interface to listen on
    struct ifaddrs *listOfInterfaces = NULL;
    struct ifaddrs *anInterface = NULL;
    BOOL serverWasRunning = self.isServerRunning;
    [self changeHTTPServerState:NO];
    _nameOfUsedNetworkInterface = nil;
    NSString *preferredipv4Interface;
    NSString *preferredipv6Interface;
    int ret = getifaddrs(&listOfInterfaces);
    if (ret == 0) {
        anInterface = listOfInterfaces;

        while (anInterface != NULL) {
            if (anInterface->ifa_addr->sa_family == AF_INET) {
#if WIFI_SHARING_DEBUG
                APLog(@"Found an IPv4 interface %s, address %@", anInterface->ifa_name, @(inet_ntoa(((struct sockaddr_in *)anInterface->ifa_addr)->sin_addr)));
#endif
                if ([self interfaceIsSuitableForUse:anInterface]) {
                    preferredipv4Interface = [NSString stringWithUTF8String:anInterface->ifa_name];
                }
            } else if (anInterface->ifa_addr->sa_family == AF_INET6) {
                char addr[INET6_ADDRSTRLEN];
                struct sockaddr_in6 *in6 = (struct sockaddr_in6*)anInterface->ifa_addr;
                inet_ntop(AF_INET6, &in6->sin6_addr, addr, sizeof(addr));
#if WIFI_SHARING_DEBUG
                APLog(@"Found an IPv6 interface %s, address %@", anInterface->ifa_name, @(addr));
#endif
                if ([self interfaceIsSuitableForUse:anInterface]) {
                    preferredipv6Interface = [NSString stringWithUTF8String:anInterface->ifa_name];
                }
            }
            anInterface = anInterface->ifa_next;
        }
    }
    freeifaddrs(listOfInterfaces);
    if (preferredipv4Interface) {
        _nameOfUsedNetworkInterface = preferredipv4Interface;
    } else {
        _nameOfUsedNetworkInterface = preferredipv6Interface;
    }
    if (_nameOfUsedNetworkInterface == nil) {
        _isReachable = NO;
        [self changeHTTPServerState:NO];
        return;
    }
    _isReachable = YES;
    if (serverWasRunning) {
        [self changeHTTPServerState:YES];
    }
}

- (BOOL)necessaryFlagsSetOnInterface:(struct ifaddrs *)anInterface withName:(const char *)nameToCompare
{
    if (strncmp (anInterface->ifa_name, nameToCompare, strlen(nameToCompare)) == 0) {
        unsigned int flags = anInterface->ifa_flags;
        if( (flags & IFF_UP) && (flags & IFF_RUNNING) && !(flags & IFF_LOOPBACK) ) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)interfaceIsSuitableForUse:(struct ifaddrs *)anInterface
{
    /* check for primary interface first */
    if ([self necessaryFlagsSetOnInterface:anInterface withName:"en0"]) {
        return YES;
    }

    /* oh well, let's move on to the secondary interface */
    if ([self necessaryFlagsSetOnInterface:anInterface withName:"en1"]) {
        return YES;
    }

    /* we can do ethernet, too */
    if ([self necessaryFlagsSetOnInterface:anInterface withName:"en3"]) {
        return YES;
    }

    /* we can also run on the tethering interface */
    if ([self necessaryFlagsSetOnInterface:anInterface withName:"bridge100"]) {
        return YES;
    }

    return NO;
}

- (BOOL)changeHTTPServerState:(BOOL)state
{
    if (!state) {
        [_httpServer stop];
        [self endBackgroundTask];
        return true;
    }

    if (_nameOfUsedNetworkInterface == nil) {
        APLog(@"No interface to listen on, server not started");
        _isReachable = NO;
        [self endBackgroundTask];
        return NO;
    }

#if TARGET_OS_IOS
    // clean cache before accepting new stuff
    [self cleanCache];
#endif

    // Initialize our http server
    _httpServer = [[HTTPServer alloc] init];

    [_httpServer setInterface:_nameOfUsedNetworkInterface];

    [_httpServer setIPv4Enabled:YES];
    [_httpServer setIPv6Enabled:[[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingWiFiSharingIPv6] boolValue]];

    // Tell the server to broadcast its presence via Bonjour.
    // This allows browsers such as Safari to automatically discover our service.
    [_httpServer setType:@"_http._tcp."];

    // Serve files from the standard Sites folder
    NSString *docRoot = [[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"] stringByDeletingLastPathComponent];

    APLog(@"Setting document root: %@", docRoot);

    [_httpServer setDocumentRoot:docRoot];
    [_httpServer setPort:80];

    [_httpServer setConnectionClass:[VLCHTTPConnection class]];

    NSError *error = nil;
    if (![_httpServer start:&error]) {
        if (error.code == EACCES) {
            APLog(@"Port forbidden by OS, trying another one");
            [_httpServer setPort:8888];
            if (![_httpServer start:&error]) {
                [self beginBackgroundTask];
                return true;
            }
        }

        /* Address already in Use, take a random one */
        if (error.code == EADDRINUSE) {
            APLog(@"Port already in use, trying another one");
            [_httpServer setPort:0];
            if (![_httpServer start:&error]) {
                [self beginBackgroundTask];
                return true;
            }
        }

        if (error) {
            APLog(@"Error starting HTTP Server: %@", error.localizedDescription);
            [_httpServer stop];
        }
        [self endBackgroundTask];
        return false;
    }

    [self beginBackgroundTask];
    return true;
}

- (NSString *)currentIPAddress
{
    NSString *ipv4address = @"";
    NSString *ipv6address = @"";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *interface = NULL;
    int success = getifaddrs(&interfaces);

    if (success != 0) {
        freeifaddrs(interfaces);
        return ipv4address;
    }

    interface = interfaces;
    while (interface != NULL) {
        if (interface->ifa_addr->sa_family == AF_INET) {
            if([@(interface->ifa_name) isEqualToString:_nameOfUsedNetworkInterface] && [self interfaceIsSuitableForUse:interface]) {
                ipv4address = @(inet_ntoa(((struct sockaddr_in *)interface->ifa_addr)->sin_addr));
            }
        } else if (interface->ifa_addr->sa_family == AF_INET6) {
            if([@(interface->ifa_name) isEqualToString:_nameOfUsedNetworkInterface] && [self interfaceIsSuitableForUse:interface]) {
                char addr[INET6_ADDRSTRLEN];
                struct sockaddr_in6 *in6 = (struct sockaddr_in6*)interface->ifa_addr;
                inet_ntop(AF_INET6, &in6->sin6_addr, addr, sizeof(addr));
                ipv6address = @(addr);
            }
        }
        interface = interface->ifa_next;
    }

    freeifaddrs(interfaces);

    /* return the IPv4 address in dual stack networks as it is more readable */
    if (ipv4address.length > 0) {
        /* ignore link-local addresses following RFC 3927 */
        if (![ipv4address hasPrefix:@"169.254."]) {
            return ipv4address;
        }
    }
    return [NSString stringWithFormat:@"[%@]", ipv6address];
}

- (NSString *)hostname
{
    return [[NSProcessInfo processInfo] hostName];
}

- (NSString *)hostnamePort
{
    return [NSString stringWithFormat:@"%i", _httpServer.listeningPort];
}

#if TARGET_OS_IOS
- (void)moveFileOutOfCache:(NSString *)filepath
{
    NSString *fileName = [filepath lastPathComponent];
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *uploadPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)
                            firstObject] stringByAppendingPathComponent:kVLCHTTPUploadDirectory];

    NSString *finalFilePath = [libraryPath
                               stringByAppendingString:[filepath
                                                        stringByReplacingOccurrencesOfString:uploadPath
                                                        withString:@""]];

    NSFileManager *fileManager = [NSFileManager defaultManager];

    // Re-create the folder structure of the user
    if (![fileManager createDirectoryAtPath:[finalFilePath stringByDeletingLastPathComponent]
                withIntermediateDirectories:YES attributes:nil error:nil])
        APLog(@"Could not create directory at path: %@", finalFilePath);

    if ([fileManager fileExistsAtPath:finalFilePath]) {
        /* we don't want to over-write existing files, so add an integer to the file name */
        NSString *potentialFullPath;
        NSString *currentPath = [finalFilePath stringByDeletingLastPathComponent];
        NSString *fileExtension = [fileName pathExtension];
        NSString *rawFileName = [fileName stringByDeletingPathExtension];
        for (NSUInteger x = 1; x < 100; x++) {
            potentialFullPath = [currentPath stringByAppendingString:[NSString
                                                                      stringWithFormat:@"/%@-%lu.%@",
                                                                      rawFileName,
                                                                      (unsigned long)x,
                                                                      fileExtension]];

            if (![[NSFileManager defaultManager] fileExistsAtPath:potentialFullPath]) {
                finalFilePath = potentialFullPath;
                break;
            }
        }
    }

    NSError *error;
    [fileManager moveItemAtPath:filepath toPath:finalFilePath error:&error];
    if (error) {
        APLog(@"Moving received media %@ to library folder failed (%li), deleting", fileName, (long)error.code);
        [fileManager removeItemAtPath:filepath error:nil];
    }

    [[VLCMediaFileDiscoverer sharedInstance] performSelectorOnMainThread:@selector(updateMediaList) withObject:nil waitUntilDone:NO];
    // FIXME: Replace notifications by cleaner observers
    [[NSNotificationCenter defaultCenter] postNotificationName:NSNotification.VLCNewFileAddedNotification
                                                        object:self];
}
#endif

- (void)moveFileFrom:(NSString *)filepath
{
    VLCActivityManager *activityManager = [VLCActivityManager defaultManager];
    [activityManager networkActivityStopped];
    [activityManager activateIdleTimer];

    // Check if downloaded file is a playlist in order to parse at the end of the download.
    if ([[filepath lastPathComponent] isSupportedPlaylistFormat]) {
        [_playlistUploadPaths addObject:filepath];
        return;
    }

    /* on tvOS, the media remains in the cache folder and will disappear from there
     * while on iOS we have persistent storage, so move it there */
#if TARGET_OS_IOS
    [self moveFileOutOfCache:filepath];
#endif
}

- (void)cleanCache
{
    if ([[VLCActivityManager defaultManager] haveNetworkActivity])
        return;

    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *uploadDirPath = [searchPaths.firstObject
                               stringByAppendingPathComponent:kVLCHTTPUploadDirectory];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:uploadDirPath])
        [fileManager removeItemAtPath:uploadDirPath error:nil];
}

#if TARGET_OS_IOS
- (void)resetIdleTimer
{
    const int timeInterval = 4;

    if (!_idleTimer)
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_idleTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                                target:self
                                                              selector:@selector(idleTimerDone)
                                                              userInfo:nil
                                                               repeats:NO];
        });
    else {
        if (fabs([_idleTimer.fireDate timeIntervalSinceNow]) < timeInterval)
            [_idleTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:timeInterval]];
    }
}

- (void)idleTimerDone
{
    _idleTimer = nil;

    for (NSString *path in _playlistUploadPaths) {
        [self moveFileOutOfCache:path];
    }

    [_playlistUploadPaths removeAllObjects];
}
#endif

@end
