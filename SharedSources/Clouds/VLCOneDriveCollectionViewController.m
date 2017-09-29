/*****************************************************************************
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOneDriveCollectionViewController.h"
#import "VLCOneDriveController.h"
#import "VLCRemoteBrowsingTVCell.h"
#import "VLCRemoteBrowsingTVCell+CloudStorage.h"

@interface VLCOneDriveCollectionViewController ()
{
    VLCOneDriveObject *_currentFolder;
    VLCOneDriveController *_oneDriveController;
}
@end

@implementation VLCOneDriveCollectionViewController

- (instancetype)initWithOneDriveObject:(VLCOneDriveObject *)object
{
    self = [super initWithNibName:@"VLCRemoteBrowsingCollectionViewController" bundle:nil];

    if (self) {
        _oneDriveController = [VLCOneDriveController sharedInstance];
        self.controller = _oneDriveController;
        _oneDriveController.delegate = self;

        _currentFolder = object;
        _oneDriveController.currentFolder = object;
        [_oneDriveController loadCurrentFolder];
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    if (_currentFolder != nil)
        self.title = _currentFolder.name;
    else
        self.title = @"OneDrive";

    [self updateViewAfterSessionChange];
    self.authorizationInProgress = NO;

    [super viewWillAppear:animated];
}

- (void)mediaListUpdated
{
    [self.collectionView reloadData];
    [self.activityIndicator stopAnimating];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCRemoteBrowsingTVCell *cell = (VLCRemoteBrowsingTVCell *)[collectionView dequeueReusableCellWithReuseIdentifier:VLCRemoteBrowsingTVCellIdentifier forIndexPath:indexPath];

    if (_currentFolder == nil)
        _currentFolder = _oneDriveController.rootFolder;

    if (_currentFolder) {
        NSArray *items = _currentFolder.items;

        if (indexPath.row < items.count) {
            cell.oneDriveFile = items[indexPath.row];
        }
    }

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_currentFolder == nil)
        return;

    NSArray *folderItems = _currentFolder.items;
    NSInteger row = indexPath.row;
    if (row >= folderItems.count)
        return;

    VLCOneDriveObject *selectedObject = folderItems[row];
    if (selectedObject.isFolder) {
        /* dive into sub folder */
        VLCOneDriveCollectionViewController *targetViewController = [[VLCOneDriveCollectionViewController alloc] initWithOneDriveObject:selectedObject];
        [self.navigationController pushViewController:targetViewController animated:YES];
    } else {
        /* stream file */
        NSURL *url = [NSURL URLWithString:selectedObject.downloadPath];

        VLCMediaList *medialist = [[VLCMediaList alloc] init];
        [medialist addMedia:[VLCMedia mediaWithURL:url]];
        [[VLCPlaybackController sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];

        VLCFullscreenMovieTVViewController *movieVC = [VLCFullscreenMovieTVViewController fullscreenMovieTVViewController];
        [self presentViewController:movieVC
                           animated:YES
                         completion:nil];
    }
}

- (void)sessionWasUpdated
{
    [self updateViewAfterSessionChange];
}

@end
