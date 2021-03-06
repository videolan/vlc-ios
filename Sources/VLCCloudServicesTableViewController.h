/*****************************************************************************
 * VLCCloudServicesTableViewController.h
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

@interface VLCCloudServicesTableViewController : UITableViewController

@property (nonatomic, readonly, copy) NSString *detailText;
@property (nonatomic, readonly) UIImage *cellImage;

@end
