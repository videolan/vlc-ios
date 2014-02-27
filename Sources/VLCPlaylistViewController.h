/*****************************************************************************
 * VLCPlaylistViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

#define EXPERIMENTAL_LIBRARY 1

typedef enum {
    VLCLibraryModeAllFiles  = 0,
    VLCLibraryModeAllAlbums = 1,
    VLCLibraryModeAllSeries = 2,
    VLCLibraryModeCreateFolder = 3
} VLCLibraryMode;

@class EmptyLibraryView;

@interface VLCPlaylistViewController : UIViewController <UITabBarDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong) UIViewController *menuViewController;

- (IBAction)leftButtonAction:(id)sender;

- (void)updateViewContents;
- (void)removeMediaObject:(id)mediaObject updateDatabase:(BOOL)updateDB;

- (void)setLibraryMode:(VLCLibraryMode)mode;

@end

@interface EmptyLibraryView: UIView

@property (nonatomic, strong) IBOutlet UILabel *emptyLibraryLabel;
@property (nonatomic, strong) IBOutlet UILabel *emptyLibraryLongDescriptionLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UIButton *learnMoreButton;

- (IBAction)learnMore:(id)sender;

@end
