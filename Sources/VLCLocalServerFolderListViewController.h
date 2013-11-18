/*****************************************************************************
 * VLCLocalServerFolderListViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@class MediaServer1Device;

@interface VLCLocalServerFolderListViewController : UIViewController

@property (nonatomic, strong) UITableView *tableView;

- (id)initWithUPNPDevice:(MediaServer1Device *)device header:(NSString *)header andRootID:(NSString *)rootID;
- (id)initWithFTPServer:(NSString *)serverAddress userName:(NSString *)username andPassword:(NSString *)password atPath:(NSString *)path;

@end
