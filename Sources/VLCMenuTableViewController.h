//
//  VLCMenuTableViewController.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 10.08.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import <UIKit/UIKit.h>

@class VLCSettingsController;
@class IASKAppSettingsViewController;

@interface VLCMenuTableViewController : UIViewController

@property (strong, nonatomic) IASKAppSettingsViewController *settingsViewController;
@property (strong, nonatomic) VLCSettingsController *settingsController;

@property (nonatomic, strong) UITableView *tableView;

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition;

@end
