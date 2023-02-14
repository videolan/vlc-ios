/*****************************************************************************
 * VLCPlayerDisplayController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
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
@class VLCQueueViewController;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const VLCPlayerDisplayControllerDisplayMiniPlayer;
extern NSString * const VLCPlayerDisplayControllerHideMiniPlayer;

typedef NS_ENUM(NSUInteger, VLCPlayerDisplayControllerDisplayMode) {
    VLCPlayerDisplayControllerDisplayModeFullscreen,
    VLCPlayerDisplayControllerDisplayModeMiniplayer,
};

@protocol VLCMiniPlaybackViewInterface <NSObject>

@required;
@property (nonatomic) BOOL visible;

@end

@protocol VLCPlayerDisplayControllerDelegate

@end

@protocol VLCMiniPlayer;

@interface VLCPlayerDisplayController : UIViewController

@property (nonatomic, assign) VLCPlayerDisplayControllerDisplayMode displayMode;
@property (nonatomic, weak, nullable) VLCPlaybackService *playbackController;
@property (nonatomic, strong, nullable) NSLayoutYAxisAnchor *realBottomAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *leadingConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *trailingConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *playqueueBottomConstraint;
@property (nonatomic, readonly) BOOL isMiniPlayerVisible;
@property (nonatomic, readonly) BOOL hintingPlayqueue;
@property (nonatomic, strong, nullable) UIView *miniPlaybackView;
@property (nonatomic, strong, readonly, nullable) VLCQueueViewController *queueViewController;
@property (nullable, nonatomic, readonly) NSArray<UIKeyCommand *> *keyCommands;
@property (nonatomic, readonly) BOOL canBecomeFirstResponder;

- (nullable instancetype)init;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                                 bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (void)showFullscreenPlayback;
- (void)showAudioPlayer;
- (void)closeFullscreenPlayback;

- (void)pushPlaybackView;
- (void)dismissPlaybackView;

- (void)hintPlayqueueWithDelay:(NSTimeInterval)delay;

@end

NS_ASSUME_NONNULL_END
