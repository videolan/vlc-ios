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

typedef enum {
    VLCLibraryModeAllFiles  = 0,
    VLCLibraryModeAllAlbums = 1,
    VLCLibraryModeAllSeries = 2
} VLCLibraryMode;

@class VLCMovieViewController;
@class EmptyLibraryView;

@interface VLCPlaylistViewController : UIViewController <UITabBarDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) VLCMovieViewController *movieViewController;
@property (nonatomic, strong) UIViewController *menuViewController;

- (IBAction)leftButtonAction:(id)sender;

- (void)updateViewContents;
- (void)openMovieFromURL:(NSURL *)url;
- (void)removeMediaObject:(MLFile *)mediaObject;

- (void)setLibraryMode:(VLCLibraryMode)mode;

@end

@interface EmptyLibraryView: UIView

@property (nonatomic, strong) IBOutlet UILabel *emptyLibraryLabel;
@property (nonatomic, strong) IBOutlet UILabel *emptyLibraryLongDescriptionLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
