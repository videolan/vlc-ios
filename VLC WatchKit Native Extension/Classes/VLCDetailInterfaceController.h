/*****************************************************************************
 * VLCDetailInterfaceController.h
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
#import "VLCBaseInterfaceController.h"

@interface VLCDetailInterfaceController : VLCBaseInterfaceController
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *durationLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *playNowButton;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *group;
@property (weak, nonatomic) IBOutlet WKInterfaceObject *progressObject;

@property (copy, nonatomic) NSString *mediaTitle;
@property (copy, nonatomic) NSString *mediaDuration;
@property (nonatomic) CGFloat playbackProgress;

- (IBAction)playNow;
@end
