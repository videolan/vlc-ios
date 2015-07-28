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

- (instancetype)init
{
    self = [super init];
    if (self) {
        if ([WCSession isSupported]) {
            WCSession *session = [WCSession defaultSession];
            session.delegate = self;
            [session activateSession];
        }
    }
    return self;
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

- (void)session:(nonnull WCSession *)session didReceiveMessage:(nonnull NSDictionary<NSString *,id> *)userInfo replyHandler:(nonnull void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler {
    UIApplication *application = [UIApplication sharedApplication];
    /* dispatch background task */
    __block UIBackgroundTaskIdentifier taskIdentifier = [application beginBackgroundTaskWithName:nil
                                                                               expirationHandler:^{
                                                                                   [application endBackgroundTask:taskIdentifier];
                                                                                   taskIdentifier = UIBackgroundTaskInvalid;
                                                                               }];

    VLCWatchMessage *message = [[VLCWatchMessage alloc] initWithDictionary:userInfo];
    NSString *name = message.name;
    NSDictionary *responseDict = nil;
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
        APLog(@"Did not handle request from WatchKit Extension: %@",userInfo);
    }
    replyHandler(responseDict);
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

@end
