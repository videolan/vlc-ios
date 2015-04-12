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
#import <MobileVLCKit/VLCTime.h>
#import <MediaLibraryKit/MediaLibraryKit.h>
#import "VLCNotificationRelay.h"
#import "VLCThumbnailsCache.h"
#import "WKInterfaceObject+VLCProgress.h"

@interface VLCNowPlayingInterfaceController ()
{
    CGRect _screenBounds;
    CGFloat _screenScale;
}
@property (nonatomic, copy) NSString *titleString;
@property (nonatomic, copy) NSNumber *playBackDurationNumber;
@property (nonatomic) BOOL isPlaying;
@property (nonatomic) NSTimer *updateTimer;
@end

@implementation VLCNowPlayingInterfaceController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setTitle:NSLocalizedString(@"PLAYING", nil)];
        _isPlaying = YES;
    }
    return self;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    WKInterfaceDevice *currentDevice = [WKInterfaceDevice currentDevice];
    _screenBounds = currentDevice.screenBounds;
    _screenScale = currentDevice.screenScale;

    // Configure interface objects here.
    [self requestNowPlayingInfo];
    [[VLCNotificationRelay sharedRelay] addRelayRemoteName:@"org.videolan.ios-app.nowPlayingInfoUpdate" toLocalName:@"nowPlayingInfoUpdate"];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    [self setTitle:NSLocalizedString(@"PLAYING", nil)];

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
    [WKInterfaceController openParentApplication:@{@"name": @"getNowPlayingInfo"} reply:^(NSDictionary *replyInfo, NSError *error) {
        MLFile *file = nil;
        NSString *uriString = replyInfo[@"URIRepresentation"];
        if (uriString) {
            NSURL *uriRepresentation = [NSURL URLWithString:uriString];
            file = [MLFile fileForURIRepresentation:uriRepresentation];
        }
        [self updateWithNowPlayingInfo:replyInfo[@"nowPlayingInfo"] andFile:file];
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

    /* do not block */
    [self performSelectorInBackground:@selector(loadThumbnailForFile:) withObject:file];
}

- (void)loadThumbnailForFile:(MLFile *)file
{
    UIImage *image = [VLCThumbnailsCache thumbnailForManagedObject:file toFitRect:CGRectMake(0., 0., _screenBounds.size.width * _screenScale, _screenBounds.size.height * _screenScale) shouldReplaceCache:NO];

    [self.playElementsGroup performSelectorOnMainThread:@selector(setBackgroundImage:) withObject:image waitUntilDone:YES];
}

- (IBAction)playPausePressed {
    self.isPlaying = !self.isPlaying;
    [WKInterfaceController openParentApplication:@{@"name": @"playpause"} reply:^(NSDictionary *replyInfo, NSError *error) {
        NSLog(@"playpause %@",replyInfo);
    }];
}

- (IBAction)skipForward {
    [WKInterfaceController openParentApplication:@{@"name": @"skipForward"} reply:^(NSDictionary *replyInfo, NSError *error) {
        NSLog(@"skipForward %@",replyInfo);
    }];
}

- (IBAction)skipBackward {
    [WKInterfaceController openParentApplication:@{@"name": @"skipBackward"} reply:^(NSDictionary *replyInfo, NSError *error) {
        NSLog(@"skipBackward %@",replyInfo);
    }];
}


- (void)setIsPlaying:(BOOL)isPlaying {

    [self.playPauseButton setBackgroundImageNamed:isPlaying? @"pause":@"play"];
    _isPlaying = isPlaying;
}

- (void)setTitleString:(NSString *)titleString {
    if (![_titleString isEqualToString:titleString] || (_titleString==nil && titleString)) {
        _titleString = [titleString copy];
        [self.titleLabel setText:titleString];
    }
}

- (void)setPlayBackDurationNumber:(NSNumber *)playBackDurationNumber {
    if (![_playBackDurationNumber isEqualToNumber:playBackDurationNumber] || (_playBackDurationNumber==nil && playBackDurationNumber)) {
        _playBackDurationNumber = playBackDurationNumber;
        [self.durationLabel setText:[VLCTime timeWithNumber:playBackDurationNumber].stringValue];
    }
}

@end


