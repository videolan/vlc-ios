//
//  PlaylistMediaViewController.h
//  VLC-tvOS
//
//  Created by Eshan Singh on 15/08/23.
//  Copyright © 2023 VideoLAN. All rights reserved.
//

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
