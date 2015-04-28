/*****************************************************************************
 * VLCOneDriveController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOneDriveTableViewController.h"
#import "VLCOneDriveObject.h"

#define VLCOneDriveControllerSessionUpdated @"VLCOneDriveControllerSessionUpdated"

@interface VLCOneDriveController : VLCCloudStorageController

@property (readonly) BOOL activeSession;
@property (nonatomic, readonly) VLCOneDriveObject *rootFolder;
@property (nonatomic, readwrite) VLCOneDriveObject *currentFolder;

+ (VLCOneDriveController *)sharedInstance;

- (void)loginWithViewController:(UIViewController*)presentingViewController;

- (void)downloadObject:(VLCOneDriveObject *)object;

- (void)loadCurrentFolder;

@end
