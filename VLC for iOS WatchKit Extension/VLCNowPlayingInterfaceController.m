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
#import <MediaPlayer/MediaPlayer.h>
#import "VLCTime.h"
#import <MediaLibraryKit/MediaLibraryKit.h>
#import "VLCNotificationRelay.h"
#import "VLCThumbnailsCache.h"
#import "WKInterfaceObject+VLCProgress.h"
#import "VLCWatchMessage.h"

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

    [self setPlaying:YES];

    [self requestNowPlayingInfo];
    [[VLCNotificationRelay sharedRelay] addRelayRemoteName:@"org.videolan.ios-app.nowPlayingInfoUpdate" toLocalName:@"nowPlayingInfoUpdate"];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestNowPlayingInfo) name:@"nowPlayingInfoUpdate" object:nil];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"nowPlayingInfoUpdate" object:nil];
    [self.updateTimer invalidate];
    self.updateTimer = nil;
}

- (void)requestNowPlayingInfo {
    [WKInterfaceController openParentApplication:[VLCWatchMessage messageDictionaryForName:VLCWatchMessageNameGetNowPlayingInfo] reply:^(NSDictionary *replyInfo, NSError *error) {
        MLFile *file = nil;
        NSString *uriString = replyInfo[@"URIRepresentation"];
        if (uriString) {
            NSURL *uriRepresentation = [NSURL URLWithString:uriString];
            file = [MLFile fileForURIRepresentation:uriRepresentation];
        }
        [self updateWithNowPlayingInfo:replyInfo[@"nowPlayingInfo"] andFile:file];
        NSNumber *currentVolume = replyInfo[@"volume"];
        if (currentVolume) {
            self.volume = currentVolume.floatValue;
        }
    }];
}

- (void)updateWithNowPlayingInfo:(NSDictionary*)nowPlayingInfo andFile:(MLFile*)file {
    self.titleString = file.title ?: nowPlayingInfo[MPMediaItemPropertyTitle];

    NSNumber *duration = file.duration;
    if (!duration) {
        duration = nowPlayingInfo[MPMediaItemPropertyPlaybackDuration];
        float durationFloat = duration.floatValue;
        duration = @(durationFloat*1000);
    }

    NSNumber *playbackTime = nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime];
    float playbackTimeFloat = playbackTime.floatValue; // seconds
    float durationFloat = duration.floatValue; // milliseconds
    durationFloat/=1000; // seconds

    [self.progressObject vlc_setProgressFromPlaybackTime:playbackTimeFloat duration:durationFloat hideForNoProgess:YES];

    self.playBackDurationNumber = duration;

    NSNumber *rate = nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate];
    self.playing = rate.floatValue > 0.0;

    if ([self.currentFile isEqual:file]) {
        self.currentFile = file;
        /* do not block */
        [self performSelectorInBackground:@selector(loadThumbnailForFile:) withObject:file];
    }
}

- (void)loadThumbnailForFile:(MLFile *)file
{
    UIImage *image = [VLCThumbnailsCache thumbnailForManagedObject:file toFitRect:CGRectMake(0., 0., _screenBounds.size.width * _screenScale, _screenBounds.size.height * _screenScale) shouldReplaceCache:NO];

    [self.playElementsGroup performSelectorOnMainThread:@selector(setBackgroundImage:) withObject:image waitUntilDone:NO];
}

- (IBAction)playPausePressed {
    NSDictionary *dict = [VLCWatchMessage messageDictionaryForName:VLCWatchMessageNamePlayPause];
    [WKInterfaceController openParentApplication:dict reply:^(NSDictionary *replyInfo, NSError *error) {
        NSNumber *playing = replyInfo[@"playing"];
        if ([playing isKindOfClass:[NSNumber class]]) {
            self.playing = playing.boolValue;
        } else {
            self.playing = !self.playing;
        }
        if (error)
            NSLog(@"playpause failed with reply %@ error: %@",replyInfo,error);
    }];
}

- (IBAction)skipForward {
    NSDictionary *dict = [VLCWatchMessage messageDictionaryForName:VLCWatchMessageNameSkipForward];

    [WKInterfaceController openParentApplication:dict reply:^(NSDictionary *replyInfo, NSError *error) {
        if (error)
            NSLog(@"skipForward failed with reply %@ error: %@",replyInfo,error);
    }];
}

- (IBAction)skipBackward {
    NSDictionary *dict = [VLCWatchMessage messageDictionaryForName:VLCWatchMessageNameSkipBackward];

    [WKInterfaceController openParentApplication:dict reply:^(NSDictionary *replyInfo, NSError *error) {
        if (error)
            NSLog(@"skipBackward failed with reply %@ error: %@",replyInfo,error);
    }];
}

- (IBAction)volumeSliderChanged:(float)value {
    _volume = value;
    NSDictionary *dict = [VLCWatchMessage messageDictionaryForName:VLCWatchMessageNameSetVolume
                                                           payload:@(value)];
    [WKInterfaceController openParentApplication:dict reply:^(NSDictionary *replyInfo, NSError *error) {
        if (error)
            NSLog(@"setVolume failed with reply %@ error: %@",replyInfo,error);
    }];
}


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


