/*****************************************************************************
 * VLCNowPlayingTemplateObserver.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNowPlayingTemplateObserver.h"
#import "VLCPlaybackService.h"
#import <MediaPlayer/MediaPlayer.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

@implementation VLCNowPlayingTemplateObserver

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackMetadataChanged:)
                                                     name:VLCPlaybackServicePlaybackMetadataDidChange
                                                   object:nil];
    }
    return self;
}

- (void)configureNowPlayingTemplate
{
    CPNowPlayingRepeatButton *repeatButton = [[CPNowPlayingRepeatButton alloc] initWithHandler:^(CPNowPlayingButton *button) {
        [[VLCPlaybackService sharedInstance] toggleRepeatMode];
    }];

    CPNowPlayingShuffleButton *shuffleButton = [[CPNowPlayingShuffleButton alloc] initWithHandler:^(CPNowPlayingButton *button) {
        VLCPlaybackService *vps = [VLCPlaybackService sharedInstance];
        vps.shuffleMode = !vps.isShuffleMode;
    }];

    CPNowPlayingTemplate *nowPlayingTemplate = CPNowPlayingTemplate.sharedTemplate;
    [nowPlayingTemplate updateNowPlayingButtons:@[repeatButton, shuffleButton]];
    nowPlayingTemplate.upNextButtonEnabled = [VLCPlaybackService sharedInstance].isNextMediaAvailable;
    nowPlayingTemplate.albumArtistButtonEnabled = NO;
}

- (void)playbackMetadataChanged:(NSNotification *)aNotification
{
    CPNowPlayingTemplate *nowPlayingTemplate = CPNowPlayingTemplate.sharedTemplate;
    nowPlayingTemplate.upNextButtonEnabled = [VLCPlaybackService sharedInstance].isNextMediaAvailable;
}

- (void)nowPlayingTemplateUpNextButtonTapped:(CPNowPlayingTemplate *)nowPlayingTemplate
{
    [[VLCPlaybackService sharedInstance] next];
}

@end

#pragma clang diagnostic pop
