//
//  VLCMasterViewController.h
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VLCDetailViewController;

@interface VLCPlaylistViewController : UITableViewController

@property (strong, nonatomic) VLCDetailViewController *detailViewController;

- (void)updateViewContents;

@end
