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
{
    UITableView *_tableView;
    AQGridView *_gridview;
}

@property (strong, nonatomic) VLCMovieViewController *movieViewController;
@property (strong, nonatomic) VLCAboutViewController *aboutViewController;

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet AQGridView *gridView;

- (void)updateViewContents;

@end
