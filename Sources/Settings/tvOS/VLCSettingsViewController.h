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
#import "VLC-Swift.h"

@class MediaLibraryService;

@interface VLCSettingsViewController : UIViewController

@property (readwrite, weak, nonatomic) IBOutlet UITableView *tableView;
@property (readonly) MediaLibraryService *mediaLibraryService;

@end
