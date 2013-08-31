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

#define EXPERIMENTAL_LIBRARY 1

#define kVLCLibraryModeAllFiles 0
#define kVLCLibraryModeAllAlbums 1
#define kVLCLibraryModeAllSeries 2

@class VLCMovieViewController;
@class EmptyLibraryView;
@class AQGridView;

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

- (void)setLibraryMode:(NSUInteger)mode;

@end

@interface EmptyLibraryView: UIView

@property (nonatomic, strong) IBOutlet UILabel *emptyLibraryLabel;
@property (nonatomic, strong) IBOutlet UILabel *emptyLibraryLongDescriptionLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
