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
@class VLCAddMediaViewController;

@interface VLCPlaylistViewController : UIViewController <AQGridViewDataSource, AQGridViewDelegate, UITableViewDataSource, UITableViewDelegate, UITabBarDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) VLCMovieViewController *movieViewController;
@property (nonatomic, strong) VLCAddMediaViewController *addMediaViewController;
@property (nonatomic, strong) UIPopoverController *addMediaPopoverController;

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet AQGridView *gridView;

@property (nonatomic, strong) IBOutlet UIView *emptyLibraryView;
@property (nonatomic, strong) IBOutlet UILabel *emptyLibraryLabel;
@property (nonatomic, strong) IBOutlet UILabel *emptyLibraryLongDescriptionLabel;

- (IBAction)leftButtonAction:(id)sender;

- (void)updateViewContents;
- (void)openMovieFromURL:(NSURL *)url;
- (void)removeMediaObject:(MLFile *)mediaObject;

@end
