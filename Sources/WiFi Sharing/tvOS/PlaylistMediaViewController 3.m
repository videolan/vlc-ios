//
//  PlaylistMediaViewController.m
//  VLC-tvOS
//
//  Created by Eshan Singh on 15/08/23.
//  Copyright © 2023 VideoLAN. All rights reserved.
//

#import "PlaylistMediaViewController.h"
#import "VLCRemoteBrowsingTVCell.h"
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
    
    [self.playlistMediaCollection registerNib:[UINib nibWithNibName:@"VLCRemoteBrowsingTVCell" bundle:nil]
                     forCellWithReuseIdentifier: @"VLCRemoteBrowsingTVCell"];
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
    flowLayout.itemSize = CGSizeMake(250.0, 300.0);
    flowLayout.minimumInteritemSpacing = 48.0;
    flowLayout.minimumLineSpacing = 100.0;
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
    VLCRemoteBrowsingTVCell *cell = (VLCRemoteBrowsingTVCell *)[collectionView dequeueReusableCellWithReuseIdentifier:VLCRemoteBrowsingTVCellIdentifier forIndexPath:indexPath];
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

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(VLCRemoteBrowsingTVCell * )cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCMLMedia *mediatoPlay;
    if (_didBeginSearching) {
       mediatoPlay = _searchedPlaylistMedia[indexPath.row];
    } else {
       mediatoPlay = _playlistMedia[indexPath.row];
    }
    [cell setTitle:mediatoPlay.title];
    [cell setCachedThumbnail:mediatoPlay];
    [cell setMediaProgress:mediatoPlay.progress];
    [cell setMediaisNew:!mediatoPlay.isNew];
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
    VLCMLMedia *mediatoPlay;
    mediatoPlay = _didBeginSearching ? _searchedPlaylistMedia[indexPath.row] : _playlistMedia[indexPath.row];
    [[VLCPlaybackService sharedInstance] playMedia: mediatoPlay];
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
    VLCMLMedia *mediatodelete;
    if (_didBeginSearching) {
        mediatodelete = _searchedPlaylistMedia[indexPathToDelete.row];
    } else {
        mediatodelete = _playlistMedia[indexPathToDelete.row];
    }
    return mediatodelete.title;
}

- (void)deleteFileAtIndex:(NSIndexPath *)indexPathToDelete
{
    [super deleteFileAtIndex:indexPathToDelete];
    VLCMLMedia *mediatodestroy;
    
    if (!indexPathToDelete) {
        return;
    }
    
    if (_didBeginSearching) {
          mediatodestroy = _searchedPlaylistMedia[indexPathToDelete.row];
         [_searchedPlaylistMedia removeObjectAtIndex:indexPathToDelete.row];
         [_playlistMedia removeObjectAtIndex:indexPathToDelete.row];
         if (_searchedPlaylistMedia.count == 0) {
              _didBeginSearching = NO;
              _searchMediaBar.text = @"";
         }
    } else {
        mediatodestroy = _playlistMedia[indexPathToDelete.row];
    }
    
    [self.playlistMediaCollection performBatchUpdates:^{
        [mediatodestroy deleteMainFile];
        [self.playlistMediaCollection deleteItemsAtIndexPaths:@[indexPathToDelete]];
    } completion:^(BOOL finished) {
        self.editing = NO;
    }];
}

- (void)renameFileAtIndex:(NSIndexPath *)indexPathToRename
{
    VLCMLMedia *mediatoRename;
    
    if (_didBeginSearching) {
        mediatoRename = _searchedPlaylistMedia[indexPathToRename.row];
    } else {
        mediatoRename = _playlistMedia[indexPathToRename.row];
    }
    NSString *currentTitle = mediatoRename.title;
    
    NSString *alertTitle = [NSString stringWithFormat:@"Rename %@ to:", currentTitle];
    UIAlertController *renameAlert = [UIAlertController alertControllerWithTitle:alertTitle message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    __block NSString *newName = nil;
    
    [renameAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Confirm" style: UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    UITextField *textField = renameAlert.textFields.firstObject;
    newName = textField.text;
        
        if (![newName isEqualToString:@""]) {
            [mediatoRename updateTitle:newName];
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
