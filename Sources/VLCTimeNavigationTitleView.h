/*****************************************************************************
 * VLCTimeNavigationTitleView.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@class VLCOBSlider;

@interface VLCTimeNavigationTitleView : UIView
@property (weak, nonatomic) IBOutlet UIButton *minimizePlaybackButton;
@property (weak, nonatomic) IBOutlet VLCOBSlider *positionSlider;
@property (weak, nonatomic) IBOutlet UIButton *timeDisplayButton;
@property (weak, nonatomic) IBOutlet UIButton *aspectRatioButton;
@end
