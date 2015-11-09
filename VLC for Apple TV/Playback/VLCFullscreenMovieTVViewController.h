/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

#import "VLCPlaybackController.h"
#import "VLCTransportBar.h"

@class VLCNetworkImageView;

@interface VLCFullscreenMovieTVViewController : UIViewController <VLCPlaybackControllerDelegate>

@property (readwrite, nonatomic, weak) IBOutlet UIView *movieView;

@property (readwrite, nonatomic, weak) IBOutlet UIView *bottomOverlayView;
@property (readwrite, nonatomic, weak) IBOutlet VLCTransportBar *transportBar;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *bufferingLabel;
@property (readwrite, nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (readwrite, nonatomic, weak) IBOutlet UIView *dimmingView;

@property (readwrite, nonatomic, weak) IBOutlet UIView *audioView;
@property (readwrite, nonatomic, weak) IBOutlet VLCNetworkImageView *audioLargeBackgroundImageView;
@property (readwrite, nonatomic, weak) IBOutlet UIVisualEffectView *audioVisualEffectView;
@property (readwrite, nonatomic, weak) IBOutlet VLCNetworkImageView *audioArtworkImageView;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *audioTitleLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *audioArtistLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *audioAlbumNameLabel;
@property (readwrite, nonatomic, weak) IBOutlet UITextView *audioDescriptionTextView;

+ (instancetype) fullscreenMovieTVViewController;

@end
