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

@interface VLCFullscreenMovieTVViewController : UIViewController <VLCPlaybackControllerDelegate>

@property (readwrite, nonatomic, weak) IBOutlet UIView *movieView;

@property (readwrite, nonatomic, weak) IBOutlet UIView *bottomOverlayView;
@property (readwrite, nonatomic, weak) IBOutlet UIProgressView *playbackProgressView;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *playedTimeLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *remainingTimeLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (readwrite, nonatomic, weak) IBOutlet UILabel *bufferingLabel;

@end
