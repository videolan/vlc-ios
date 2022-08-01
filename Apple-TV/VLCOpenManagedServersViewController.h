/*****************************************************************************
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
#import "VLCDeletionCapableViewController.h"

@interface VLCOpenManagedServersViewController : VLCDeletionCapableViewController <UITableViewDataSource, UITableViewDelegate>

@property (readwrite, nonatomic, weak) IBOutlet UITableView *managedServersTableView;

@property (readonly, nonatomic) BOOL hasManagedServers;

@end
