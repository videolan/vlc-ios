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

@interface VLCPlaylistViewController : UIViewController <AQGridViewDataSource, AQGridViewDelegate, UITableViewDataSource, UITableViewDelegate, UITabBarDelegate>
{
    NSURL *_pasteURL;
    BOOL _editMode;
}

@property (nonatomic, strong) VLCMovieViewController *movieViewController;
@property (nonatomic, strong) VLCAboutViewController *aboutViewController;

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet AQGridView *gridView;

@property (nonatomic, strong) IBOutlet UITabBar *tabBar;
@property (nonatomic, strong) IBOutlet UITabBarItem *localFilesBarItem;
@property (nonatomic, strong) IBOutlet UITabBarItem *networkStreamsBarItem;

- (void)updateViewContents;
- (void)openMovieFromURL:(NSURL *)url;
- (void)removeMediaObject:(MLFile *)mediaObject;

@end
