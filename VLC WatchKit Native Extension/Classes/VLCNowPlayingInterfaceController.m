/*****************************************************************************
 * VLCNowPlayingInterfaceController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNowPlayingInterfaceController.h"
#import "VLCTime.h"
#import "WKInterfaceObject+VLCProgress.h"
#import "VLCWatchMessage.h"
#import "VLCThumbnailsCache.h"
#import <WatchConnectivity/WatchConnectivity.h>

static NSString *const VLCNowPlayingUpdateNotification = @"VLCPlaybackControllerPlaybackMetadataDidChange";

@interface VLCNowPlayingInterfaceController ()
{
    CGRect _screenBounds;
    CGFloat _screenScale;
}
@property (nonatomic, copy) NSString *titleString;
@property (nonatomic, copy) NSNumber *playBackDurationNumber;
@property (nonatomic, getter=isPlaying) BOOL playing;
@property (nonatomic) NSTimer *updateTimer;
@property (nonatomic, weak) MLFile *currentFile;
@property (nonatomic) float volume;
@end

@implementation VLCNowPlayingInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    WKInterfaceDevice *currentDevice = [WKInterfaceDevice currentDevice];
    _screenBounds = currentDevice.screenBounds;
    _screenScale = currentDevice.screenScale;

    [self setTitle:NSLocalizedString(@"PLAYING", nil)];
    self.skipBackwardButton.accessibilityLabel = NSLocalizedString(@"BWD_BUTTON", nil);
    self.skipForwardButton.accessibilityLabel = NSLocalizedString(@"FWD_BUTTON", nil);
    self.volumeSlider.accessibilityLabel = NSLocalizedString(@"VOLUME", nil);
    self.durationLabel.accessibilityLabel = NSLocalizedString(@"DURATION", nil);
    self.titleLabel.accessibilityLabel = NSLocalizedString(@"TITLE", nil);

    self.volume = -1.0;

    [self setPlaying:YES];

    [self requestNowPlayingInfo];

    [self vlc_performBlockIfSessionReachable:nil showUnreachableAlert:YES alertOKAction:^{
        [self dismissController];
    }];
}


- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestNowPlayingInfo) name:VLCNowPlayingUpdateNotification object:nil];
    [self requestNowPlayingInfo];

    const NSTimeInterval updateInterval = 5;
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval
                                                        target:self
                                                      selector:@selector(requestNowPlayingInfo)
                                                      userInfo:nil
                                                       repeats:YES];
}
- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VLCNowPlayingUpdateNotification object:nil];
    [self.updateTimer invalidate];
    self.updateTimer = nil;
}


// TODO: don't query for after receiving a notification from iPhone instead add user info to message which sends the notification
// and use that user info dictionary
- (void)requestNowPlayingInfo {

    [self vlc_performBlockIfSessionReachable:^{
        NSDictionary *dict = [VLCWatchMessage messageDictionaryForName:VLCWatchMessageNameGetNowPlayingInfo];
        [[WCSession defaultSession] sendMessage:dict replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyInfo) {
            MLFile *file = nil;
            NSString *uriString = replyInfo[VLCWatchMessageKeyURIRepresentation];
            if (uriString) {
                NSURL *uriRepresentation = [NSURL URLWithString:uriString];
                file = [MLFile fileForURIRepresentation:uriRepresentation];
            }
            [self updateWithNowPlayingInfo:replyInfo[@"nowPlayingInfo"] andFile:file];
            NSNumber *currentVolume = replyInfo[@"volume"];
            if (currentVolume) {
                self.volume = currentVolume.floatValue;
            }
        } errorHandler:nil];
    } showUnreachableAlert:NO];
}

- (void)updateWithNowPlayingInfo:(NSDictionary*)nowPlayingInfo andFile:(MLFile*)file {

    // TODO: fix key use
    self.titleString = file.title ?: nowPlayingInfo[@"title"];

    NSNumber *duration = file.duration;
    if (!duration) {
        duration = nowPlayingInfo[@"playbackDuration"];
        float durationFloat = duration.floatValue;
        duration = @(durationFloat*1000);
    }

    NSNumber *playbackTime = nowPlayingInfo[@"MPNowPlayingInfoPropertyElapsedPlaybackTime"];
    float playbackTimeFloat = playbackTime.floatValue; // seconds
    float durationFloat = duration.floatValue; // milliseconds
    durationFloat/=1000; // seconds

    [self.progressObject vlc_setProgressFromPlaybackTime:playbackTimeFloat duration:durationFloat hideForNoProgess:YES];

    self.playBackDurationNumber = duration;

    NSNumber *rate = nowPlayingInfo[@"MPNowPlayingInfoPropertyPlaybackRate"];
    self.playing = rate.floatValue > 0.0;

    if ([self.currentFile isEqual:file]) {
        self.currentFile = file;
        /* do not block */
        [self performSelectorInBackground:@selector(loadThumbnailForFile:) withObject:file];
    }
}

- (void)loadThumbnailForFile:(MLFile *)file
{
    UIImage *image = [VLCThumbnailsCache thumbnailForManagedObject:file refreshCache:YES toFitRect:_screenBounds scale:_screenScale shouldReplaceCache:NO];

    [self.playElementsGroup performSelectorOnMainThread:@selector(setBackgroundImage:) withObject:image waitUntilDone:NO];
}

- (IBAction)playPausePressed {
    [self vlc_performBlockIfSessionReachable:^{
        NSDictionary *dict = [VLCWatchMessage messageDictionaryForName:VLCWatchMessageNamePlayPause];
        [[WCSession defaultSession] sendMessage:dict replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyInfo) {
            NSNumber *playing = replyInfo[@"playing"];
            if ([playing isKindOfClass:[NSNumber class]]) {
                self.playing = playing.boolValue;
            } else {
                self.playing = !self.playing;
            }

        } errorHandler:^(NSError * _Nonnull error) {
            NSLog(@"playpause failed with error: %@",error);
        }];
    } showUnreachableAlert:YES];
}

- (IBAction)skipForward {
    [self vlc_performBlockIfSessionReachable:^{
        NSDictionary *dict = [VLCWatchMessage messageDictionaryForName:VLCWatchMessageNameSkipForward];
        [[WCSession defaultSession] sendMessage:dict replyHandler:nil errorHandler:^(NSError * _Nonnull error) {
            NSLog(@"skipForward failed with error: %@",error);
        }];

    } showUnreachableAlert:YES];
}

- (IBAction)skipBackward {
    [self vlc_performBlockIfSessionReachable:^{

        NSDictionary *dict = [VLCWatchMessage messageDictionaryForName:VLCWatchMessageNameSkipBackward];
        [[WCSession defaultSession] sendMessage:dict replyHandler:nil errorHandler:^(NSError * _Nonnull error) {
            NSLog(@"skipBackward failed with error: %@",error);
        }];
    } showUnreachableAlert:YES];
}

- (IBAction)volumeSliderChanged:(float)value {
    _volume = value;

    [self vlc_performBlockIfSessionReachable:^{

        NSDictionary *dict = [VLCWatchMessage messageDictionaryForName:VLCWatchMessageNameSetVolume
                                                               payload:@(value)];
        [[WCSession defaultSession] sendMessage:dict replyHandler:nil errorHandler:^(NSError * _Nonnull error) {
            NSLog(@"setVolume failed with error: %@",error);
        }];
    } showUnreachableAlert:YES];
}

#pragma mark value comparing setters -

- (void)setVolume:(float)volume
{
    if (_volume != volume) {
        _volume = volume;
        self.volumeSlider.value = volume;
    }
}

- (void)setPlaying:(BOOL)playing {
    if (_playing != playing) {
        [self.playPauseButtonGroup setBackgroundImageNamed:playing? @"pause":@"play"];
        self.playPauseButton.accessibilityLabel = playing ? NSLocalizedString(@"PAUSE_BUTTON", nil) : NSLocalizedString(@"PLAY_BUTTON", nil);
        _playing = playing;
    }
}

- (void)setTitleString:(NSString *)titleString {
    if (![_titleString isEqualToString:titleString]) {
        _titleString = [titleString copy];
        self.titleLabel.text = titleString;
        self.titleLabel.accessibilityValue = titleString;
    }
}

- (void)setPlayBackDurationNumber:(NSNumber *)playBackDurationNumber {
    if (![_playBackDurationNumber isEqualToNumber:playBackDurationNumber] || (_playBackDurationNumber==nil && playBackDurationNumber)) {
        _playBackDurationNumber = playBackDurationNumber;
        NSString *durationString = [VLCTime timeWithNumber:playBackDurationNumber].stringValue;
        self.durationLabel.text = durationString;
        self.durationLabel.accessibilityValue = durationString;
    }
}

@end


