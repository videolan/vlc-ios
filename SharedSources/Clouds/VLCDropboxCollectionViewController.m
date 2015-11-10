//
//  VLCDropboxCollectionViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 10/11/15.
//  Copyright © 2015 VideoLAN. All rights reserved.
//

#import "VLCDropboxCollectionViewController.h"
#import "VLCDropboxController.h"
#import "UIDevice+VLC.h"
#import "DBKeychain.h"
#import "VLCRemoteBrowsingTVCell.h"

@interface VLCDropboxCollectionViewController () <VLCCloudStorageDelegate>
{
    VLCDropboxController *_dropboxController;
    DBMetadata *_selectedFile;
    NSArray *_mediaList;
}
@end

@implementation VLCDropboxCollectionViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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

    if (self.currentPath != nil)
        self.title = self.currentPath.lastPathComponent;

    [self updateViewAfterSessionChange];
}

- (void)mediaListUpdated
{
    _mediaList = [self.controller.currentListFiles copy];
    [self.collectionView reloadData];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCCloudStorageCollectionViewCell *cell = (VLCCloudStorageCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:VLCRemoteBrowsingTVCellIdentifier forIndexPath:indexPath];
    if (!cell) {
        NSLog(@"oh boy");
    }

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
    if (!_selectedFile.isDirectory)
        [_dropboxController streamFile:_selectedFile currentNavigationController:self.navigationController];
    else {
        /* dive into subdirectory */
        NSString *futurePath = [self.currentPath stringByAppendingFormat:@"/%@", _selectedFile.filename];
        [_dropboxController reset];
        VLCDropboxCollectionViewController *targetViewController = [[VLCDropboxCollectionViewController alloc] initWithNibName:@"VLCRemoteBrowsingCollectionViewController" bundle:nil];
        targetViewController.currentPath = futurePath;
        [self.navigationController pushViewController:targetViewController animated:YES];
    }
    _selectedFile = nil;
}

@end
