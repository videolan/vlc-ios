/*****************************************************************************
 * VLCDropboxTableViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Fabio Ritrovato <sephiroth87 # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDropboxController.h"

#if TARGET_OS_IOS
#import "VLCCloudStorageTableViewController.h"

@interface VLCDropboxTableViewController : VLCCloudStorageTableViewController

@end

#else
#import "VLCCloudStorageTVTableViewController.h"

@interface VLCDropboxTableViewController : VLCCloudStorageTVTableViewController

@end

#endif
