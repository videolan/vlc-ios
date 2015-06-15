//
//  VLCSidebarController.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 15/06/15.
//  Copyright © 2015 VideoLAN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VLCSidebarController : NSObject

+ (instancetype)sharedInstance;

- (void)hideSidebar;
- (void)toggleSidebar;

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath scrollPosition:(UITableViewScrollPosition)scrollPosition;

@property (readonly) UIViewController *fullViewController;
@property (readwrite, retain) UIViewController *contentViewController;

@end
