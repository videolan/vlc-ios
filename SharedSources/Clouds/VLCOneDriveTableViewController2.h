/*****************************************************************************
 * VLCOneDriveTableViewController.h
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
#import "VLCCloudStorageTVTableViewController.h"

@class VLCOneDriveObject;

@interface VLCOneDriveTableViewController2 : VLCCloudStorageTVTableViewController

- (instancetype)initWithOneDriveObject:(VLCOneDriveObject *)object;

@end
