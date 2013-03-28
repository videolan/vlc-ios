//
//  VLCMasterViewController.h
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VLCMovieViewController;

@interface VLCPlaylistViewController : UITableViewController

@property (strong, nonatomic) VLCMovieViewController *movieViewController;

- (void)updateViewContents;

@end
