/*****************************************************************************
 * VLCNowPlayingTemplateObserver.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2022, 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNowPlayingTemplateObserver.h"
#import "VLCPlaybackService.h"
#import <MediaPlayer/MediaPlayer.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

NSString *const VLCDisplayPlayQueueCarPlay = @"VLCDisplayPlayQueueCarPlay";

@implementation VLCNowPlayingTemplateObserver

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(playbackDidMoveOnToNextItem:)
                                   name:VLCPlaybackServicePlaybackDidMoveOnToNextItem
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(playModeUpdated:)
                                   name:VLCPlaybackServicePlaybackModeUpdated
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(shuffleModeUpdated)
                                   name:VLCPlaybackServiceShuffleModeUpdated
                                 object:nil];
    }
    return self;
}

- (void)configureNowPlayingTemplate
{
    [self playModeUpdated:nil];

    CPNowPlayingRepeatButton *repeatButton = [[CPNowPlayingRepeatButton alloc] initWithHandler:^(CPNowPlayingRepeatButton *button) {
        VLCPlaybackService *vps = [VLCPlaybackService sharedInstance];
        VLCRepeatMode vlcRepeatMode = vps.repeatMode;
        MPRepeatType reportedRepeatType;
        switch (vlcRepeatMode) {
            case VLCRepeatCurrentItem:
                reportedRepeatType = MPRepeatTypeAll;
                vlcRepeatMode = VLCRepeatAllItems;
                break;
            case VLCRepeatAllItems:
                reportedRepeatType = MPRepeatTypeOff;
                vlcRepeatMode = VLCDoNotRepeat;
                break;
            default:
                reportedRepeatType = MPRepeatTypeOne;
                vlcRepeatMode = VLCRepeatCurrentItem;
                break;
        }

        [MPRemoteCommandCenter sharedCommandCenter].changeRepeatModeCommand.currentRepeatType = reportedRepeatType;
        vps.repeatMode = vlcRepeatMode;
    }];

    CPNowPlayingShuffleButton *shuffleButton = [[CPNowPlayingShuffleButton alloc] initWithHandler:^(CPNowPlayingShuffleButton *button) {
        VLCPlaybackService *vps = [VLCPlaybackService sharedInstance];

        if (vps.shuffleMode) {
            [MPRemoteCommandCenter sharedCommandCenter].changeShuffleModeCommand.currentShuffleType = MPShuffleTypeOff;
            vps.shuffleMode = NO;
        } else {
            [MPRemoteCommandCenter sharedCommandCenter].changeShuffleModeCommand.currentShuffleType = MPShuffleTypeItems;
            vps.shuffleMode = YES;
        }
    }];

    CPNowPlayingTemplate *nowPlayingTemplate = CPNowPlayingTemplate.sharedTemplate;
    [nowPlayingTemplate updateNowPlayingButtons:@[repeatButton, shuffleButton]];
    nowPlayingTemplate.upNextButtonEnabled = [VLCPlaybackService sharedInstance].isNextMediaAvailable;
    nowPlayingTemplate.albumArtistButtonEnabled = NO;
}

- (void)playbackDidMoveOnToNextItem:(NSNotification *)aNotification
{
    CPNowPlayingTemplate *nowPlayingTemplate = CPNowPlayingTemplate.sharedTemplate;
    nowPlayingTemplate.upNextButtonEnabled = [VLCPlaybackService sharedInstance].isNextMediaAvailable;
}

- (void)nowPlayingTemplateUpNextButtonTapped:(CPNowPlayingTemplate *)nowPlayingTemplate
{
//    When CarPlay calls this method on your observer, you should push an instance of CPListTemplate—other template
//    types are not supported when Now Playing is the visible template—on to your navigation stack that displays a
//    list of upcoming or queued content (cf. CPNowPlayingTemplate documentation)
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCDisplayPlayQueueCarPlay object:self];
}

- (void)playModeUpdated:(NSNotification *)aNotification
{
    VLCPlaybackService *vps = [VLCPlaybackService sharedInstance];

    VLCRepeatMode vlcRepeatMode = vps.repeatMode;
    MPRepeatType reportedRepeatType;
    switch (vlcRepeatMode) {
        case VLCRepeatCurrentItem:
            reportedRepeatType = MPRepeatTypeOne;
            break;
        case VLCRepeatAllItems:
            reportedRepeatType = MPRepeatTypeAll;
            break;
        default:
            reportedRepeatType = MPRepeatTypeOff;
    }
    [MPRemoteCommandCenter sharedCommandCenter].changeRepeatModeCommand.currentRepeatType = reportedRepeatType;
}

- (void)shuffleModeUpdated
{
    VLCPlaybackService *vps = [VLCPlaybackService sharedInstance];

    MPShuffleType shuffleType;
    if (vps.shuffleMode) {
        shuffleType = MPShuffleTypeItems;
    } else {
        shuffleType = MPShuffleTypeOff;
    }

    [MPRemoteCommandCenter sharedCommandCenter].changeShuffleModeCommand.currentShuffleType = shuffleType;
}

@end

#pragma clang diagnostic pop
