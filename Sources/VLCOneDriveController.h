/*****************************************************************************
 * VLCOneDriveController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOneDriveTableViewController.h"

@protocol VLCOneDriveControllerDelegate <NSObject>

@end

@interface VLCOneDriveController : NSObject

@property (nonatomic, weak) VLCOneDriveTableViewController *delegate;
@property (readonly) BOOL activeSession;

+ (VLCOneDriveController *)sharedInstance;

- (void)login;
- (void)logout;

- (void)requestDirectoryListingAtPath:(NSString *)path;
- (void)downloadFileWithPath:(NSString *)path;
- (void)streamFileWithPath:(NSString *)path;

@end
