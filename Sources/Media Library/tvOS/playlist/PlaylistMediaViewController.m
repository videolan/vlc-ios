/*****************************************************************************
 * PlaylistMediaViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2023-2026 VideoLAN. All rights reserved.
 *
 * Authors: Eshan Singh <eshansingh.dev # gmail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "PlaylistMediaViewController.h"
#import "VLCRemoteBrowsingTVCell.h"
#import "VLCMovieTVCollectionViewCell.h"
#import "CAAnimation+VLCWiggle.h"
#import "VLCMaskView.h"
#import "VLC-Swift.h"

@interface PlaylistMediaViewController () <UICollectionViewDataSource, UICollectionViewDelegate , UITextFieldDelegate>
@property (nonatomic) NSIndexPath *currentlyFocusedIndexPath;

// Searching properties
@property (nonatomic, assign) BOOL didBeginSearching;
@property (nonatomic, strong) NSMutableArray<VLCMLMedia*> *searchedPlaylistMedia;

@end

@implementation PlaylistMediaViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.playlistMediaCollection registerClass:[VLCMovieTVCollectionViewCell class]
                    forCellWithReuseIdentifier:VLCMovieTVCollectionViewCellIdentifier];
    self.playlistMediaCollection.delegate = self;
    self.playlistMediaCollection.dataSource = self;
    self.playlistTitle.text = self.playlist.name;

    self.playlistMedia = [[NSMutableArray alloc] init];
    self.playlistMedia = [NSMutableArray arrayWithArray:self.playlist.media];

    _searchMediaBar.delegate = self;
    _didBeginSearching = NO;
    _searchedPlaylistMedia = [[NSMutableArray alloc] init];

    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.playlistMediaCollection.collectionViewLayout;
    const CGFloat inset = 50.;
    flowLayout.sectionInset = UIEdgeInsetsMake(inset, inset, inset, inset);
    flowLayout.itemSize = [VLCMovieTVCollectionViewCell cellSize];
    flowLayout.minimumInteritemSpacing = 48.0;
    flowLayout.minimumLineSpacing = 80.0;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    UICollectionView *collectionView = self.playlistMediaCollection;
    VLCMaskView *maskView = (VLCMaskView *)collectionView.maskView;
    maskView.maskEnd = self.topLayoutGuide.length * 0.8;

    /*
     Update the position from where the collection view's content should
     start to fade out. The size of the fade increases as the collection
     view scrolls to a maximum of half the navigation bar's height.
     */
    CGFloat maximumMaskStart = maskView.maskEnd + (self.topLayoutGuide.length * 0.5);
    CGFloat verticalScrollPosition = MAX(0, collectionView.contentOffset.y + collectionView.contentInset.top);
    maskView.maskStart = MIN(maximumMaskStart, maskView.maskEnd + verticalScrollPosition);

    /*
     Position the mask view so that it is always fills the visible area of
     the collection view.
     */
    CGSize collectionViewSize = collectionView.bounds.size;
    maskView.frame = CGRectMake(0, collectionView.contentOffset.y, collectionViewSize.width, collectionViewSize.height);
}

#pragma mark - collection view data source

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCMovieTVCollectionViewCell *cell = (VLCMovieTVCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:VLCMovieTVCollectionViewCellIdentifier forIndexPath:indexPath];
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (_didBeginSearching) {
        return _searchedPlaylistMedia.count;
    } else {
        return _playlistMedia.count;
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(VLCMovieTVCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCMLMedia *media;
    if (_didBeginSearching) {
        media = _searchedPlaylistMedia[indexPath.row];
    } else {
        media = _playlistMedia[indexPath.row];
    }
    [cell configureWithMedia:media];
}

-(BOOL)collectionView:(UICollectionView *)collectionView shouldUpdateFocusInContext:(UICollectionViewFocusUpdateContext *)context
{
    if (self.editing) {
        return context.nextFocusedIndexPath == nil;
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didUpdateFocusInContext:(UICollectionViewFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    NSIndexPath *nextPath = context.nextFocusedIndexPath;
    if (!nextPath) {
        self.editing = NO;
    }
    self.currentlyFocusedIndexPath = nextPath;

}

#pragma mark - collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCMLMedia *mediaToPlay;
    mediaToPlay = _didBeginSearching ? _searchedPlaylistMedia[indexPath.row] : _playlistMedia[indexPath.row];
    [[VLCPlaybackService sharedInstance] playMedia: mediaToPlay];
    VLCFullscreenMovieTVViewController *fullscreenViewController = [[VLCFullscreenMovieTVViewController alloc] init];
    [self presentViewController:fullscreenViewController animated:YES completion:nil];
}
#pragma mark - editing

- (NSIndexPath *)indexPathToDelete
{
    NSIndexPath *indexPathToDelete = self.currentlyFocusedIndexPath;
    return indexPathToDelete;
}

- (NSString *)itemToDelete
{
    NSIndexPath *indexPathToDelete = self.indexPathToDelete;
    if (!indexPathToDelete) {

        return nil;
    }
    VLCMLMedia *mediaToDelete;
    if (_didBeginSearching) {
        mediaToDelete = _searchedPlaylistMedia[indexPathToDelete.row];
    } else {
        mediaToDelete = _playlistMedia[indexPathToDelete.row];
    }
    return mediaToDelete.title;
}

- (void)deleteFileAtIndex:(NSIndexPath *)indexPathToDelete
{
    [super deleteFileAtIndex:indexPathToDelete];
    VLCMLMedia *mediaToDestroy;

    if (!indexPathToDelete) {
        return;
    }

    if (_didBeginSearching) {
        mediaToDestroy = _searchedPlaylistMedia[indexPathToDelete.row];
        [_searchedPlaylistMedia removeObjectAtIndex:indexPathToDelete.row];
        [_playlistMedia removeObjectAtIndex:indexPathToDelete.row];
        if (_searchedPlaylistMedia.count == 0) {
            _didBeginSearching = NO;
            _searchMediaBar.text = @"";
        }
    } else {
        mediaToDestroy = _playlistMedia[indexPathToDelete.row];
    }

    [self.playlistMediaCollection performBatchUpdates:^{
        [mediaToDestroy deleteMainFile];
        [self.playlistMediaCollection deleteItemsAtIndexPaths:@[indexPathToDelete]];
    } completion:^(BOOL finished) {
        self.editing = NO;
    }];
}

- (void)renameFileAtIndex:(NSIndexPath *)indexPathToRename
{
    VLCMLMedia *mediaToRename;

    if (_didBeginSearching) {
        mediaToRename = _searchedPlaylistMedia[indexPathToRename.row];
    } else {
        mediaToRename = _playlistMedia[indexPathToRename.row];
    }
    NSString *currentTitle = mediaToRename.title;

    NSString *alertTitle = [NSString stringWithFormat:NSLocalizedString(@"RENAME_MEDIA_TO", nil), currentTitle];
    UIAlertController *renameAlert = [UIAlertController alertControllerWithTitle:alertTitle message:nil preferredStyle:UIAlertControllerStyleAlert];

    __block NSString *newName = nil;

    [renameAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) style:UIAlertActionStyleCancel
                                                         handler:nil];

    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_RENAME", nil) style: UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = renameAlert.textFields.firstObject;
        newName = textField.text;

        if (![newName isEqualToString:@""]) {
            [mediaToRename updateTitle:newName];
            self.searchMediaBar.text = @"";
            [self.playlistMediaCollection reloadData];
        }
    }];

    [renameAlert addAction:confirmAction];
    [renameAlert addAction:cancelAction];

    [self presentViewController:renameAlert animated:YES completion:nil];
}

- (void)setEditing:(BOOL)editing
{
    [super setEditing:editing];

    UICollectionViewCell *focusedCell = [self.playlistMediaCollection cellForItemAtIndexPath:self.currentlyFocusedIndexPath];
    if (editing) {
        [focusedCell.layer addAnimation:[CAAnimation vlc_wiggleAnimationwithSoftMode:NO]
                                 forKey:VLCWiggleAnimationKey];
    } else {
        [focusedCell.layer removeAnimationForKey:VLCWiggleAnimationKey];
    }
}
#pragma mark - search bar delegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSString *searchString = textField.text;
    NSMutableArray<VLCMLMedia *> *mutablePlaylistMedia = [_searchedPlaylistMedia mutableCopy];
    [mutablePlaylistMedia removeAllObjects];
    _searchedPlaylistMedia = [mutablePlaylistMedia copy];

    if ([textField.text isEqualToString:@""]) {
        self.didBeginSearching = NO;
        [self.playlistMediaCollection reloadData];
        return;
    }

    self.didBeginSearching = YES;

    NSArray<VLCMLMedia *> *searchResult = [_playlist searchMediaWithPattern:searchString sort:VLCMLSortingCriteriaDefault desc:NO];
    _searchedPlaylistMedia = [NSMutableArray arrayWithArray:searchResult];

    [self.playlistMediaCollection reloadData];
}
@end
