/*****************************************************************************
 * VLCPlayerDisplayController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@class VLCPlaybackService;
@class VLCServices;

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

@interface VLCPlayerDisplayController : UIViewController

@property (nonatomic, assign) VLCPlayerDisplayControllerDisplayMode displayMode;
@property (nonatomic, weak) VLCPlaybackService *playbackController;
@property (nonatomic, strong) NSLayoutYAxisAnchor *realBottomAnchor;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (instancetype)initWithServices:(id)services NS_DESIGNATED_INITIALIZER;

- (void)showFullscreenPlayback;
- (void)closeFullscreenPlayback;

- (void)pushPlaybackView;
- (void)dismissPlaybackView;

@end
