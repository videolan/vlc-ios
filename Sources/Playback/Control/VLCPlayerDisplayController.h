/*****************************************************************************
 * VLCPlayerDisplayController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaybackService.h"

@class VLCPlaybackService;
@class VLCServices;

typedef NS_ENUM(UInt8, VLCMLMediaType);

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, VLCPlayerDisplayControllerDisplayMode) {
    VLCPlayerDisplayControllerDisplayModeFullscreen,
    VLCPlayerDisplayControllerDisplayModeMiniplayer,
};

typedef NS_ENUM(NSUInteger, VLCPlayerDisplayControllerQueueStatusMessage) {
    VLCPlayerDisplayControllerQueueStatusMessageAppended,
    VLCPlayerDisplayControllerQueueStatusMessagePlayingNext,
};

@protocol VLCPlayerDisplayControllerDelegate

@end

@interface VLCPlayerDisplayController : UIViewController

@property (nonatomic, assign) VLCPlayerDisplayControllerDisplayMode displayMode;
@property (nonatomic, weak, nullable) VLCPlaybackService *playbackController;
@property (nullable, nonatomic, readonly) NSArray<UIKeyCommand *> *keyCommands;
@property (nonatomic, readonly) BOOL canBecomeFirstResponder;
@property (readonly, nonnull) UIViewController<VLCPlaybackServiceDelegate> *videoPlayerViewController;
@property (readwrite, nonatomic) VLCMLMediaType currentMediaType;

- (instancetype)init;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                                 bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (void)showFullscreenPlayback;
- (void)showAudioPlayer;
- (void)closeFullscreenPlayback;

- (void)pushPlaybackView;
- (void)dismissPlaybackView;

- (void)showPlayqueueStatus:(VLCPlayerDisplayControllerQueueStatusMessage)status withDelay:(NSTimeInterval)delay;

@end

NS_ASSUME_NONNULL_END
