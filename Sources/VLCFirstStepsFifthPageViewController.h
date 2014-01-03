/*****************************************************************************
 * VLCFirstStepsFifthPageViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCFirstStepsFifthPageViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIView *actualContentView;
@property (nonatomic, strong) IBOutlet UILabel *positionLabel;
@property (nonatomic, strong) IBOutlet UILabel *timeLabel;
@property (nonatomic, strong) IBOutlet UILabel *aspectLabel;
@property (nonatomic, strong) IBOutlet UILabel *speedLabel;
@property (nonatomic, strong) IBOutlet UILabel *effectsLabel;
@property (nonatomic, strong) IBOutlet UILabel *repeatLabel;
@property (nonatomic, strong) IBOutlet UILabel *audioLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitlesLabel;
@property (nonatomic, strong) IBOutlet UILabel *volumeLabel;

@property (readonly) NSString *pageTitle;
@property (readonly) NSUInteger page;

@end
