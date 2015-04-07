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

@interface VLCNowPlayingInterfaceController ()
@property (nonatomic, copy) NSString *titleString;
@property (nonatomic, copy) NSNumber *playBackDurationNumber;
@end

@implementation VLCNowPlayingInterfaceController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setTitle:NSLocalizedString(@"PLAYING", nil)];
    }
    return self;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

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

}
- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"nowPlayingInfoUpdate" object:nil];
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
        float durationFloat = duration.floatValue;
        duration = @(durationFloat*1000);
    }
    self.playBackDurationNumber = duration;
    self.image.image = [VLCThumbnailsCache thumbnailForManagedObject:file];
}

- (IBAction)playPausePressed {
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



- (void)setTitleString:(NSString *)titleString {
    if (![_titleString isEqualToString:titleString] || (_titleString==nil && titleString)) {
        _titleString = [titleString copy];
        self.titleLabel.text = titleString;
    }
}

- (void)setPlayBackDurationNumber:(NSNumber *)playBackDurationNumber {
    if (![_playBackDurationNumber isEqualToNumber:playBackDurationNumber] || (_playBackDurationNumber==nil && playBackDurationNumber)) {
        _playBackDurationNumber = playBackDurationNumber;
        self.durationLabel.text = [VLCTime timeWithNumber:playBackDurationNumber].stringValue;
    }
}

@end


