/*****************************************************************************
 * VLCRemoteControlService.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017, 2023 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRemoteControlService.h"
#import "VLCPlaybackService.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation VLCRemoteControlService

static inline NSArray * RemoteCommandCenterCommandsToHandle()
{
    MPRemoteCommandCenter *cc = [MPRemoteCommandCenter sharedCommandCenter];
    NSMutableArray *commands = [NSMutableArray arrayWithObjects:
                                cc.pauseCommand,
                                cc.playCommand,
                                cc.stopCommand,
                                cc.togglePlayPauseCommand,
                                cc.nextTrackCommand,
                                cc.previousTrackCommand,
                                cc.skipForwardCommand,
                                cc.skipBackwardCommand,
                                cc.changePlaybackRateCommand,
                                nil];
    if (@available(iOS 9.1, *)) {
        [commands addObject:cc.changePlaybackPositionCommand];
    }
    if (@available(iOS 10, *)) {
        [commands addObject:cc.changeShuffleModeCommand];
        [commands addObject:cc.changeRepeatModeCommand];
    }
    return [commands copy];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(playbackStarted:) name:VLCPlaybackServicePlaybackDidStart object:nil];
        [notificationCenter addObserver:self selector:@selector(playbackStopped:) name:VLCPlaybackServicePlaybackDidStop object:nil];
    }
    return self;
}

- (void)playbackStarted:(NSNotification *)aNotification
{
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];

    /* Since the control center and lockscreen shows only either skipForward/Backward
     * or next/previousTrack buttons but prefers skip buttons,
     * we only enable skip buttons if we have no medialist
     */
    BOOL enableSkip = [VLCPlaybackService sharedInstance].mediaList.count <= 1;
    commandCenter.skipForwardCommand.enabled = enableSkip;
    commandCenter.skipBackwardCommand.enabled = enableSkip;

    //Enable when you want to support these
    commandCenter.ratingCommand.enabled = NO;
    commandCenter.likeCommand.enabled = NO;
    commandCenter.dislikeCommand.enabled = NO;
    commandCenter.bookmarkCommand.enabled = NO;
    commandCenter.enableLanguageOptionCommand.enabled = NO;
    commandCenter.disableLanguageOptionCommand.enabled = NO;
    commandCenter.changeRepeatModeCommand.enabled = YES;
    commandCenter.changeShuffleModeCommand.enabled = YES;
    commandCenter.seekForwardCommand.enabled = NO;
    commandCenter.seekBackwardCommand.enabled = NO;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *forwardSkip = [defaults valueForKey:kVLCSettingPlaybackForwardSkipLength];
    commandCenter.skipForwardCommand.preferredIntervals = @[forwardSkip];
    NSNumber *backwardSkip = [defaults valueForKey:kVLCSettingPlaybackBackwardSkipLength];
    commandCenter.skipBackwardCommand.preferredIntervals = @[backwardSkip];

    commandCenter.changePlaybackRateCommand.supportedPlaybackRates = @[@(0.5),@(0.75),@(1.0),@(1.25),@(1.5),@(1.75),@(2.0)];

    for (MPRemoteCommand *command in RemoteCommandCenterCommandsToHandle()) {
        [command addTarget:self action:@selector(remoteCommandEvent:)];
    }
}

- (void)playbackStopped:(NSNotification *)aNotification
{
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;

    for (MPRemoteCommand *command in RemoteCommandCenterCommandsToHandle()) {
        [command removeTarget:self];
    }
}

- (MPRemoteCommandHandlerStatus )remoteCommandEvent:(MPRemoteCommandEvent *)event
{
    MPRemoteCommandCenter *cc = [MPRemoteCommandCenter sharedCommandCenter];
    VLCPlaybackService *vps = [VLCPlaybackService sharedInstance];

    if (event.command == cc.pauseCommand) {
        [vps pause];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    if (event.command == cc.playCommand) {
        [vps play];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    if (event.command == cc.stopCommand) {
        [vps stopPlayback];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    if (event.command == cc.togglePlayPauseCommand) {
        [vps playPause];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    if (event.command == cc.nextTrackCommand) {
        BOOL success = [vps next];
        return success ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusNoSuchContent;
    }
    if (event.command == cc.previousTrackCommand) {
        BOOL success = [vps previous];
        return success ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusNoSuchContent;
    }
    if (event.command == cc.skipForwardCommand) {
        MPSkipIntervalCommandEvent *skipEvent = (MPSkipIntervalCommandEvent *)event;
        [vps jumpForward:skipEvent.interval];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    if (event.command == cc.skipBackwardCommand) {
        MPSkipIntervalCommandEvent *skipEvent = (MPSkipIntervalCommandEvent *)event;
        [vps jumpBackward:skipEvent.interval];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    if (event.command == cc.changePlaybackRateCommand) {
        MPChangePlaybackRateCommandEvent *rateEvent = (MPChangePlaybackRateCommandEvent *)event;
        [vps setPlaybackRate:rateEvent.playbackRate];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    if (@available(iOS 9.1, *)) {
        if (event.command == cc.changePlaybackPositionCommand) {
            MPChangePlaybackPositionCommandEvent *positionEvent = (MPChangePlaybackPositionCommandEvent *)event;
            NSInteger duration = vps.mediaDuration / 1000;
            if (duration > 0) {
                vps.playbackPosition = positionEvent.positionTime / duration;
                return MPRemoteCommandHandlerStatusSuccess;
            }
            return MPRemoteCommandHandlerStatusCommandFailed;
        }
    }
    if (@available(iOS 10, *)) {
        if (event.command == cc.changeShuffleModeCommand) {
            MPChangeShuffleModeCommandEvent *shuffleEvent = (MPChangeShuffleModeCommandEvent *)event;
            vps.shuffleMode = shuffleEvent.shuffleType != MPShuffleTypeOff;
            return MPRemoteCommandHandlerStatusSuccess;
        }
        if (event.command == cc.changeRepeatModeCommand) {
            MPChangeRepeatModeCommandEvent *repeatEvent = (MPChangeRepeatModeCommandEvent *)event;
            switch (repeatEvent.repeatType) {
                case MPRepeatTypeOne:
                    vps.repeatMode = VLCRepeatCurrentItem;
                    break;

                case MPRepeatTypeAll:
                    vps.repeatMode = VLCRepeatAllItems;
                    break;

                default:
                    vps.repeatMode = VLCDoNotRepeat;
                    break;
            }
            return MPRemoteCommandHandlerStatusSuccess;
        }
    }
    NSAssert(NO, @"remote control event not handled");
    APLog(@"%s Wasn't able to handle remote control event: %@",__PRETTY_FUNCTION__,event);
    return MPRemoteCommandHandlerStatusCommandFailed;

}

@end
