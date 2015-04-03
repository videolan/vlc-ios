//
//  VLCNowPlayingInterfaceController.m
//  VLC for iOS
//
//  Created by Tobias Conradi on 02.04.15.
//  Copyright (c) 2015 VideoLAN. All rights reserved.
//

#import "VLCNowPlayingInterfaceController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileVLCKit/VLCTime.h>
#import "VLCNotificationRelay.h"

@interface VLCNowPlayingInterfaceController ()
@property (nonatomic, copy) NSString *titleString;
@property (nonatomic, copy) NSNumber *playBackDurationNumber;
@end

@implementation VLCNowPlayingInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
    [self requestNowPlayingInfo];
    [[VLCNotificationRelay sharedRelay] addRelayRemoteName:@"org.videolan.ios-app.nowPlayingInfoUpdate" toLocalName:@"nowPlayingInfoUpdate"];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
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
        [self updateWithNowPlayingInfo:replyInfo];
        NSLog(@"nowplayingInfo: %@",replyInfo);
    }];
}
- (void)updateWithNowPlayingInfo:(NSDictionary*)nowPlayingInfo {
    self.titleString = nowPlayingInfo[MPMediaItemPropertyTitle];
    self.playBackDurationNumber = nowPlayingInfo[MPMediaItemPropertyPlaybackDuration];
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
        float duratioFloat = playBackDurationNumber.floatValue;
        NSNumber *durationNumber = nil;
        if (duratioFloat>0.0) {
            durationNumber = @(playBackDurationNumber.floatValue*1000);
        }
        self.durationLabel.text = [VLCTime timeWithNumber:durationNumber].stringValue;
    }
}

@end


