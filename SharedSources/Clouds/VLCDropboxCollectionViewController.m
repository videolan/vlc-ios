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

#import "VLCDropboxCollectionViewController.h"
#import "VLCDropboxController.h"
#import "UIDevice+VLC.h"
#import "VLCRemoteBrowsingTVCell.h"
#import "VLCRemoteBrowsingTVCell+CloudStorage.h"

@interface VLCDropboxCollectionViewController () <VLCCloudStorageDelegate>
{
    VLCDropboxController *_dropboxController;
    DBFILESMetadata *_selectedFile;
    NSArray *_mediaList;
}
@end

@implementation VLCDropboxCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _dropboxController = [VLCDropboxController sharedInstance];
    self.controller = _dropboxController;
    self.controller.delegate = self;

    self.title = @"Dropbox";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.controller = [VLCDropboxController sharedInstance];
    self.controller.delegate = self;

    if (self.currentPath != nil) {
        NSString *lastPathComponent = self.currentPath.lastPathComponent;
        self.title = lastPathComponent.length > 0 ? lastPathComponent : @"Dropbox";
    }

    [self updateViewAfterSessionChange];
}

- (void)mediaListUpdated
{
    _mediaList = [self.controller.currentListFiles copy];
    [self.collectionView reloadData];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCRemoteBrowsingTVCell *cell = (VLCRemoteBrowsingTVCell *)[collectionView dequeueReusableCellWithReuseIdentifier:VLCRemoteBrowsingTVCellIdentifier forIndexPath:indexPath];

    NSUInteger index = indexPath.row;
    if (_mediaList) {
        if (index < _mediaList.count) {
            cell.dropboxFile = _mediaList[index];
        }
    }

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedFile = _mediaList[indexPath.row];
    if (![_selectedFile isKindOfClass:[DBFILESFolderMetadata class]])
        [_dropboxController streamFile:_selectedFile currentNavigationController:self.navigationController];
    else {
        /* dive into subdirectory */
        NSString *futurePath = [self.currentPath stringByAppendingFormat:@"/%@", _selectedFile.name];
        [_dropboxController reset];
        VLCDropboxCollectionViewController *targetViewController = [[VLCDropboxCollectionViewController alloc] initWithNibName:@"VLCRemoteBrowsingCollectionViewController" bundle:nil];
        targetViewController.currentPath = futurePath;
        [self.navigationController pushViewController:targetViewController animated:YES];
    }
    _selectedFile = nil;
}

@end
