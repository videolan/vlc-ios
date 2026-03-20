/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>
#import "VLCDeletionCapableViewController.h"

@interface VLCRemotePlaybackViewController : VLCDeletionCapableViewController

@property (readwrite, nonatomic, weak) IBOutlet UILabel *httpServerLabel;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *toggleHTTPServerButton;
@property (weak, nonatomic) IBOutlet UITextField *searchBar;

@property (readwrite, nonatomic, weak) IBOutlet UICollectionView *cachedMediaCollectionView;
@property (readwrite, nonatomic, weak) IBOutlet UIImageView *cachedMediaConeImageView;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *sortButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *deleteButton;
@property (readwrite, nonatomic, weak) IBOutlet UIButton *playlistButton;
@property (weak, nonatomic) IBOutlet UIButton *editSelectionButton;
@property (readwrite, nonatomic, weak) IBOutlet UISegmentedControl *contentSwitchSegmentedControl;

- (IBAction)toggleHTTPServer:(id)sender;
- (IBAction)addToPlaylist:(id)sender;
- (IBAction)toggleEditSelectionMode:(id)sender;
- (IBAction)toggleContentMode:(id)sender;
- (IBAction)deleteSelection:(id)sender;

@end
