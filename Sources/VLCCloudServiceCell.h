/*****************************************************************************
 * VLCCloudServiceCell.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCCloudServiceCell : UITableViewCell

@property(nonatomic) IBOutlet UIImageView *icon;
@property(nonatomic) IBOutlet UILabel *cloudTitle;
@property(nonatomic) IBOutlet UILabel *cloudInformation;
@property(nonatomic) IBOutlet UILabel *lonesomeCloudTitle;

@end
