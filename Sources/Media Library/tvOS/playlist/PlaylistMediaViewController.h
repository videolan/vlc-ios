/*****************************************************************************
 * PlaylistMediaViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023-2026 VideoLAN. All rights reserved.
 *
 * Authors: Eshan Singh <eshansingh.dev # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@class VLCMLPlaylist;

#import "VLCDeletionCapableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface PlaylistMediaViewController : VLCDeletionCapableViewController

@property (readwrite,weak,nonatomic) IBOutlet UILabel *playlistTitle;
@property (readwrite,weak,nonatomic) IBOutlet UICollectionView *playlistMediaCollection;
@property (weak, nonatomic) IBOutlet UITextField *searchMediaBar;

@property (nonatomic, strong) VLCMLPlaylist *playlist;
@property (nonatomic, strong) NSMutableArray<VLCMLMedia *> *playlistMedia;
@property (nonatomic, strong) NSString *playlistName;

@end

NS_ASSUME_NONNULL_END
