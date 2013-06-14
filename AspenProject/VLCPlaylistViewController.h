//
//  VLCMasterViewController.h
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import <UIKit/UIKit.h>
#import "AQGridView.h"

@class VLCMovieViewController;
@class VLCMenuViewController;
@class EmptyLibraryView;

@interface VLCPlaylistViewController : UIViewController <UITabBarDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) VLCMovieViewController *movieViewController;
@property (nonatomic, strong) UIViewController *menuViewController;
@property (nonatomic, strong) UIPopoverController *addMediaPopoverController;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) AQGridView *gridView;

@property (nonatomic, strong) EmptyLibraryView *emptyLibraryView;


- (IBAction)leftButtonAction:(id)sender;

- (void)updateViewContents;
- (void)openMovieFromURL:(NSURL *)url;
- (void)removeMediaObject:(MLFile *)mediaObject;

@end

@interface EmptyLibraryView: UIView

@property (nonatomic, strong) IBOutlet UILabel *emptyLibraryLabel;
@property (nonatomic, strong) IBOutlet UILabel *emptyLibraryLongDescriptionLabel;

@end
