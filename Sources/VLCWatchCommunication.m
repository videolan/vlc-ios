/*****************************************************************************
 * VLCWatchCommunication.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/


#import "VLCWatchCommunication.h"
#import "VLCWatchMessage.h"
#import "VLCPlaybackController+MediaLibrary.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation VLCWatchCommunication

+ (BOOL)isSupported {
    return [WCSession class] != nil && [WCSession isSupported];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        if ([WCSession isSupported]) {
            WCSession *session = [WCSession defaultSession];
            session.delegate = self;
            [session activateSession];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(savedManagedObjectContextNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
        }
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
}

static VLCWatchCommunication *_singeltonInstance = nil;

+ (VLCWatchCommunication *)sharedInstance
{
    @synchronized(self) {
        static dispatch_once_t pred;
        dispatch_once(&pred, ^{
            _singeltonInstance = [[self alloc] init];
        });
    }
    return _singeltonInstance;
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

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    [vpc playMediaLibraryObject:managedObject];
}

- (NSDictionary *)handleMessage:(nonnull VLCWatchMessage *)message {
    UIApplication *application = [UIApplication sharedApplication];
    /* dispatch background task */
    __block UIBackgroundTaskIdentifier taskIdentifier = [application beginBackgroundTaskWithName:nil
                                                                               expirationHandler:^{
                                                                                   [application endBackgroundTask:taskIdentifier];
                                                                                   taskIdentifier = UIBackgroundTaskInvalid;
                                                                               }];

    NSString *name = message.name;
    NSDictionary *responseDict = @{};
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
        APLog(@"Did not handle request from WatchKit Extension: %@",message);
    }
    return responseDict;
}

- (void)session:(nonnull WCSession *)session didReceiveMessage:(nonnull NSDictionary<NSString *,id> *)userInfo replyHandler:(nonnull void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
    VLCWatchMessage *message = [[VLCWatchMessage alloc] initWithDictionary:userInfo];
    NSDictionary *responseDict = [self handleMessage:message];
    replyHandler(responseDict);
}

- (void)session:(nonnull WCSession *)session didReceiveMessage:(nonnull NSDictionary<NSString *,id> *)messageDict {
    VLCWatchMessage *message = [[VLCWatchMessage alloc] initWithDictionary:messageDict];
    [self handleMessage:message];
}


- (void)setVolumeFromWatch:(VLCWatchMessage *)message
{
    NSNumber *volume = (id)message.payload;
    if ([volume isKindOfClass:[NSNumber class]]) {
        /*
         * Since WatchKit doesn't provide something like MPVolumeView we use deprecated API.
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

#pragma mark - Notifications
- (void)startRelayingNotificationName:(nullable NSString *)name object:(nullable id)object {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(relayNotification:) name:name object:object];
}
- (void)stopRelayingNotificationName:(nullable NSString *)name object:(nullable id)object {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:name object:object];
}
- (void)relayNotification:(NSNotification *)notification {

    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[@"name"] = notification.name;
    if (notification.userInfo) {
        payload[@"userInfo"] = notification.userInfo;
    }
    NSDictionary *dict = [VLCWatchMessage messageDictionaryForName:VLCWatchMessageNameNotification
                                                           payload:payload];
    if ([WCSession isSupported] && [[WCSession defaultSession] isReachable]) {
        [[WCSession defaultSession] sendMessage:dict replyHandler:nil errorHandler:nil];
    }
}

#pragma mark - Copy CoreData to Watch

- (void)savedManagedObjectContextNotification:(NSNotification *)notification {
    NSManagedObjectContext *moc = notification.object;
    if (moc.persistentStoreCoordinator == [[MLMediaLibrary sharedMediaLibrary] persistentStoreCoordinator]) {
        [self copyCoreDataToWatch];
    }
}

- (void)copyCoreDataToWatch {
    if (![[WCSession defaultSession] isReachable]) return;

    MLMediaLibrary *library = [MLMediaLibrary sharedMediaLibrary];
    NSPersistentStoreCoordinator *libraryPSC = [library persistentStoreCoordinator];
    NSPersistentStore *persistentStore = [libraryPSC persistentStoreForURL:[library persistentStoreURL]];
    NSURL *tmpURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:persistentStore.URL.lastPathComponent]];

    NSPersistentStoreCoordinator *migratePSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:libraryPSC.managedObjectModel];
    NSError *error;
    NSPersistentStore *migrateStore = [migratePSC addPersistentStoreWithType:persistentStore.type
                                                               configuration:persistentStore.configurationName
                                                                         URL:persistentStore.URL
                                                                     options:persistentStore.options
                                                                       error:&error];
    if (!migrateStore) {
        NSLog(@"%s failed to add persistent store with error %@",__PRETTY_FUNCTION__,error);
        return;
    }


    NSMutableDictionary *destOptions = [persistentStore.options mutableCopy] ?: [NSMutableDictionary new];
    destOptions[NSSQLitePragmasOption] = @{@"journal_mode": @"OFF"};

    [migratePSC destroyPersistentStoreAtURL:tmpURL withType:persistentStore.type options:destOptions error:nil];

    error = nil;
    BOOL success = [migratePSC migratePersistentStore:migrateStore
                                                toURL:tmpURL
                                              options:destOptions
                                             withType:NSSQLiteStoreType error:&error];
    if (!success) {
        NSLog(@"%s failed to copy persistent store to tmp location for copy to watch with error %@",__PRETTY_FUNCTION__,error);
    }

    NSDictionary *metadata = @{@"filetype":@"coredata"};
    [[WCSession defaultSession] transferFile:tmpURL metadata:metadata];
}

@end
