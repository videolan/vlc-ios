//
//  VLCMasterViewController.h
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AQGridView.h"

@class VLCMovieViewController;
@class VLCAboutViewController;

@interface VLCPlaylistViewController : UIViewController <AQGridViewDataSource, AQGridViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) VLCMovieViewController *movieViewController;
@property (nonatomic, strong) VLCAboutViewController *aboutViewController;

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet AQGridView *gridView;

- (void)updateViewContents;

@end
