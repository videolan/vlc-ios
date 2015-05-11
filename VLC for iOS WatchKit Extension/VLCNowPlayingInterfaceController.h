/*****************************************************************************
 * VLCNowPlayingInterfaceController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface VLCNowPlayingInterfaceController : WKInterfaceController
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *playElementsGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *durationLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *skipBackwardButton;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *playPauseButton;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *playPauseButtonGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *skipForwardButton;
@property (weak, nonatomic) IBOutlet WKInterfaceObject *progressObject;
@property (weak, nonatomic) IBOutlet WKInterfaceSlider *volumeSlider;

- (IBAction)playPausePressed;
- (IBAction)skipForward;
- (IBAction)skipBackward;
- (IBAction)volumeSliderChanged:(float)value;


@end
