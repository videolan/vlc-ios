/*****************************************************************************
 * VLCSidebarController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <Foundation/Foundation.h>

@interface VLCSidebarController : NSObject

+ (instancetype)sharedInstance;

- (void)hideSidebar;
- (void)toggleSidebar;
- (void)resizeContentView;

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath scrollPosition:(UITableViewScrollPosition)scrollPosition;

- (void)performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem;

@property (readonly) UIViewController *fullViewController;
@property (readwrite, retain) UIViewController *contentViewController;

@end
