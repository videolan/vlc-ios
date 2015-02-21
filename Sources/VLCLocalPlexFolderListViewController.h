/*****************************************************************************
 * VLCLocalPlexFolderListViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

@interface VLCLocalPlexFolderListViewController : UIViewController

@property (nonatomic, strong) UITableView *tableView;

- (id)initWithPlexServer:(NSString *)serverName serverAddress:(NSString *)serverAddress portNumber:(NSString *)portNumber atPath:(NSString *)path;

@end
