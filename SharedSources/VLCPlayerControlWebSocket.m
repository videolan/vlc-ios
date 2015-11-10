/*****************************************************************************
 * VLCPlayerControlWebSocket.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlayerControlWebSocket.h"

@implementation VLCPlayerControlWebSocket

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didOpen
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(playbackStarted)
                               name:VLCPlaybackControllerPlaybackDidStart
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(playbackStarted)
                               name:VLCPlaybackControllerPlaybackDidResume
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(_respondToPlaying)
                               name:VLCPlaybackControllerPlaybackMetadataDidChange
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(playbackPaused)
                               name:VLCPlaybackControllerPlaybackDidPause
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(playbackEnded)
                               name:VLCPlaybackControllerPlaybackDidStop
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(playbackEnded)
                               name:VLCPlaybackControllerPlaybackDidFail
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(playbackSeekTo)
                               name:VLCPlaybackControllerPlaybackPositionUpdated
                             object:nil];

    APLog(@"web socket did open");

    [super didOpen];
}

- (void)didReceiveMessage:(NSString *)msg
{
    APLog(@"web socket received message: '%@'", msg);
    if ([msg isEqualToString:@"playing"]) {
        [self _respondToPlaying];
    } else if ([msg isEqualToString:@"play"]) {
        [self _respondToPlay];
    } else if ([msg isEqualToString:@"pause"]) {
        [self _respondToPause];
    } else if ([msg isEqualToString:@"ended"]) {
        [self _respondToEnded];
    } else if ([msg isEqualToString:@"seekTo"]) {
        [self _respondToSeek];
    } else if ([msg isEqualToString:@"volume"]) {
        [self sendMessage:@"VOLUME CONTROL NOT SUPPORTED ON THIS DEVICE"];
    } else
        [self sendMessage:@"INVALID REQUEST!"];
}

#ifndef NDEBUG
- (void)didClose
{
    APLog(@"web socket did close");

    [super didClose];
}
#endif

- (void)_respondToPlaying
{
    /* JSON response
     {
        "type": "playing",
        "currentTime": 42,
        "media": {
            "id": "some id",
            "title": "some title",
            "duration": 120000
        }
     }
     */

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    NSDictionary *returnDict;

    if (vpc.activePlaybackSession) {
        VLCMediaPlayer *player = vpc.mediaPlayer;
        if (player) {
            VLCMedia *media = player.media;

            if (media) {
                NSString *mediaTitle = vpc.mediaTitle;
                if (!mediaTitle)
                    mediaTitle = @"";
                NSDictionary *mediaDict = @{ @"id" : media.url.absoluteString,
                                             @"title" : mediaTitle,
                                             @"duration" : @(media.length.intValue)};
                returnDict = @{ @"currentTime" : @(player.time.intValue),
                                @"type" : @"playing",
                                @"media" : mediaDict };
            }
        }
    }
    if (!returnDict) {
        returnDict = [NSDictionary dictionary];
    }

    NSError *error;
    NSData *returnData = [NSJSONSerialization dataWithJSONObject:returnDict options:0 error:&error];
    if (error != nil) {
        APLog(@"%s: JSON serialization failed %@", __PRETTY_FUNCTION__, error);
    }

    [self sendData:returnData];
}

#pragma mark - play

- (void)_respondToPlay
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    VLCMediaListPlayer *listPlayer = vpc.listPlayer;
    if (listPlayer) {
        [listPlayer play];
    }
}

- (void)playbackStarted
{
    /*
     {
        "type": "play",
        "currentTime": 42,
        "media": {
            "id": 42
        }
     }
     */

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    VLCMediaPlayer *player = vpc.mediaPlayer;
    if (player) {
        VLCMedia *media = player.media;
        if (media) {
            NSDictionary *mediaDict = @{ @"id" : media.url.absoluteString};
            NSDictionary *returnDict = @{ @"currentTime" : @(player.time.intValue),
                                          @"type" : @"play",
                                          @"media" : mediaDict };

            NSError *error;
            NSData *returnData = [NSJSONSerialization dataWithJSONObject:returnDict options:0 error:&error];
            if (error != nil) {
                APLog(@"%s: JSON serialization failed %@", __PRETTY_FUNCTION__, error);
            }

            [self sendData:returnData];
        }
    }
}

#pragma mark - pause

- (void)_respondToPause
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    VLCMediaListPlayer *listPlayer = vpc.listPlayer;
    if (listPlayer) {
        [listPlayer pause];
    }
}

- (void)playbackPaused
{
    /*
     {
        "type": "pause",
        "currentTime": 42,
        "media": {
            "id": 42
        }
     }
     */

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    VLCMediaPlayer *player = vpc.mediaPlayer;
    if (player) {
        VLCMedia *media = player.media;
        if (media) {
            NSDictionary *mediaDict = @{ @"id" : media.url.absoluteString};
            NSDictionary *returnDict = @{ @"currentTime" : @(player.time.intValue),
                                          @"type" : @"pause",
                                          @"media" : mediaDict };

            NSError *error;
            NSData *returnData = [NSJSONSerialization dataWithJSONObject:returnDict options:0 error:&error];
            if (error != nil) {
                APLog(@"%s: JSON serialization failed %@", __PRETTY_FUNCTION__, error);
            }

            [self sendData:returnData];
        }
    }
}

#pragma mark - ended

- (void)_respondToEnded
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    [vpc stopPlayback];
}

- (void)playbackEnded
{
    /*
     {
        "type": "ended",
        "media": {
            "id": 42
        }
     }
     */

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    VLCMediaPlayer *player = vpc.mediaPlayer;
    if (player) {
        VLCMedia *media = player.media;
        if (media) {
            NSDictionary *mediaDict = @{ @"id" : media.url.absoluteString};
            NSDictionary *returnDict = @{ @"type" : @"ended",
                                          @"media" : mediaDict };

            NSError *error;
            NSData *returnData = [NSJSONSerialization dataWithJSONObject:returnDict options:0 error:&error];
            if (error != nil) {
                APLog(@"%s: JSON serialization failed %@", __PRETTY_FUNCTION__, error);
            }

            [self sendData:returnData];
        }
    }
}

#pragma mark - seek

- (void)_respondToSeek
{
    [self sendMessage:@"VOLUME CONTROL NOT SUPPORTED ON THIS DEVICE"];
}

- (void)playbackSeekTo
{
    /* 
     {
        "type": "seekTo",
        "currentTime": 42,
        "media": {
            "id": 42
        }
     }
     */

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    VLCMediaPlayer *player = vpc.mediaPlayer;
    if (player) {
        VLCMedia *media = player.media;
        if (media) {
            NSDictionary *mediaDict = @{ @"id" : media.url.absoluteString};
            NSDictionary *returnDict = @{ @"currentTime" : @(player.time.intValue),
                                          @"type" : @"seekTo",
                                          @"media" : mediaDict };

            NSError *error;
            NSData *returnData = [NSJSONSerialization dataWithJSONObject:returnDict options:0 error:&error];
            if (error != nil) {
                APLog(@"%s: JSON serialization failed %@", __PRETTY_FUNCTION__, error);
            }

            [self sendData:returnData];
        }
    }
}

@end
