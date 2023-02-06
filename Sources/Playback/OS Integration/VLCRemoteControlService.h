/*****************************************************************************
 * VLCRemoteControlService.h
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

@class VLCRemoteControlService;

@protocol VLCRemoteControlServiceDelegate

- (void)remoteControlServiceHitPlay:(VLCRemoteControlService *)rcs;
- (void)remoteControlServiceHitPause:(VLCRemoteControlService *)rcs;
- (void)remoteControlServiceTogglePlayPause:(VLCRemoteControlService *)rcs;
- (void)remoteControlServiceHitStop:(VLCRemoteControlService *)rcs;
- (BOOL)remoteControlServiceHitPlayNextIfPossible:(VLCRemoteControlService *)rcs;
- (BOOL)remoteControlServiceHitPlayPreviousIfPossible:(VLCRemoteControlService *)rcs;
- (void)remoteControlService:(VLCRemoteControlService *)rcs jumpForwardInSeconds:(NSTimeInterval)seconds;
- (void)remoteControlService:(VLCRemoteControlService *)rcs jumpBackwardInSeconds:(NSTimeInterval)seconds;
- (NSInteger)remoteControlServiceNumberOfMediaItemsinList:(VLCRemoteControlService *)rcs;
- (void)remoteControlService:(VLCRemoteControlService *)rcs setPlaybackRate:(CGFloat)playbackRate;
- (void)remoteControlService:(VLCRemoteControlService *)rcs setCurrentPlaybackTime:(NSTimeInterval)playbackTime;
- (void)remoteControlService:(VLCRemoteControlService *)rcs setShuffleType:(NSInteger)shuffleType;
- (void)remoteControlService:(VLCRemoteControlService *)rcs setRepeatType:(NSInteger)repeatType;

@end

@interface VLCRemoteControlService : NSObject

@property (nonatomic, weak) id<VLCRemoteControlServiceDelegate> remoteControlServiceDelegate;

- (void)subscribeToRemoteCommands;
- (void)unsubscribeFromRemoteCommands;

@end
