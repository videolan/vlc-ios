/*****************************************************************************
 * VLCRemoteControlService.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRemoteControlService.h"
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
    return [commands copy];
}

- (void)subscribeToRemoteCommands
{
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];

    /* Since the control center and lockscreen shows only either skipForward/Backward
     * or next/previousTrack buttons but prefers skip buttons,
     * we only enable skip buttons if we have no medialist
     */
    BOOL enableSkip = NO;
    if (_remoteControlServiceDelegate) {
        enableSkip = [_remoteControlServiceDelegate remoteControlServiceNumberOfMediaItemsinList:self] <= 1;
    }
    commandCenter.skipForwardCommand.enabled = enableSkip;
    commandCenter.skipBackwardCommand.enabled = enableSkip;

    //Enable when you want to support these
    commandCenter.ratingCommand.enabled = NO;
    commandCenter.likeCommand.enabled = NO;
    commandCenter.dislikeCommand.enabled = NO;
    commandCenter.bookmarkCommand.enabled = NO;
    commandCenter.enableLanguageOptionCommand.enabled = NO;
    commandCenter.disableLanguageOptionCommand.enabled = NO;
    commandCenter.changeRepeatModeCommand.enabled = NO;
    commandCenter.changeShuffleModeCommand.enabled = NO;
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

- (void)unsubscribeFromRemoteCommands
{
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;

    for (MPRemoteCommand *command in RemoteCommandCenterCommandsToHandle()) {
        [command removeTarget:self];
    }
}

- (MPRemoteCommandHandlerStatus )remoteCommandEvent:(MPRemoteCommandEvent *)event
{
    if (!_remoteControlServiceDelegate) return MPRemoteCommandHandlerStatusCommandFailed;

    MPRemoteCommandCenter *cc = [MPRemoteCommandCenter sharedCommandCenter];

    if (event.command == cc.pauseCommand) {
        [_remoteControlServiceDelegate remoteControlServiceHitPause:self];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    if (event.command == cc.playCommand) {
        [_remoteControlServiceDelegate remoteControlServiceHitPlay:self];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    if (event.command == cc.stopCommand) {
        [_remoteControlServiceDelegate remoteControlServiceHitStop:self];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    if (event.command == cc.togglePlayPauseCommand) {
        [_remoteControlServiceDelegate remoteControlServiceTogglePlayPause:self];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    if (event.command == cc.nextTrackCommand) {
        BOOL success = [_remoteControlServiceDelegate remoteControlServiceHitPlayNextIfPossible:self];
        return success ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusNoSuchContent;
    }
    if (event.command == cc.previousTrackCommand) {
        BOOL success = [_remoteControlServiceDelegate remoteControlServiceHitPlayPreviousIfPossible:self];
        return success ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusNoSuchContent;
    }
    if (event.command == cc.skipForwardCommand) {
        MPSkipIntervalCommandEvent *skipEvent = (MPSkipIntervalCommandEvent *)event;
        [_remoteControlServiceDelegate remoteControlService:self jumpForwardInSeconds:skipEvent.interval];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    if (event.command == cc.skipBackwardCommand) {
        MPSkipIntervalCommandEvent *skipEvent = (MPSkipIntervalCommandEvent *)event;
        [_remoteControlServiceDelegate remoteControlService:self jumpBackwardInSeconds:skipEvent.interval];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    if (event.command == cc.changePlaybackRateCommand) {
        MPChangePlaybackRateCommandEvent *rateEvent = (MPChangePlaybackRateCommandEvent *)event;
        [_remoteControlServiceDelegate remoteControlService:self setPlaybackRate:rateEvent.playbackRate];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    if (@available(iOS 9.1, *)) {
        if (event.command == cc.changePlaybackPositionCommand) {
            MPChangePlaybackPositionCommandEvent *positionEvent = (MPChangePlaybackPositionCommandEvent *)event;
            [_remoteControlServiceDelegate remoteControlService:self setCurrentPlaybackTime:positionEvent.positionTime];
            return MPRemoteCommandHandlerStatusSuccess;
        }
    }
    NSAssert(NO, @"remote control event not handled");
    APLog(@"%s Wasn't able to handle remote control event: %@",__PRETTY_FUNCTION__,event);
    return MPRemoteCommandHandlerStatusCommandFailed;

}

@end
