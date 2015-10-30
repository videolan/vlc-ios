/*****************************************************************************
 * VLCBoxTableViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#if TARGET_OS_IOS
#import "VLCCloudStorageTableViewController.h"

@interface VLCBoxTableViewController : VLCCloudStorageTableViewController

@end

#else
#import "VLCCloudStorageTVTableViewController.h"

@interface VLCBoxTableViewController : VLCCloudStorageTVTableViewController

- (instancetype)initWithPath:(NSString *)path;

@end

#endif
