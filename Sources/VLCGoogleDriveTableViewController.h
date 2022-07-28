/*****************************************************************************
 * VLCGoogleDriveTableViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
#import "VLCCloudStorageTableViewController.h"

@interface VLCGoogleDriveTableViewController : VLCCloudStorageTableViewController

- (void)setAuthorizerAndUpdate;

@end
