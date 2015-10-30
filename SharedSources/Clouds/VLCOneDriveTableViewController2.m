//
//  VLCOneDriveTableViewController2.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 30/10/15.
//  Copyright © 2015 VideoLAN. All rights reserved.
//

#import "VLCOneDriveTableViewController2.h"
#import "VLCOneDriveController.h"
#import "VLCCloudStorageTableViewCell.h"

@interface VLCOneDriveTableViewController2 () <VLCCloudStorageDelegate>
{
    VLCOneDriveObject *_currentFolder;
    VLCOneDriveController *_oneDriveController;
}
@end

@implementation VLCOneDriveTableViewController2

- (instancetype)initWithOneDriveObject:(VLCOneDriveObject *)object
{
    self = [super init];

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

#pragma mark - table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"OneDriveCell";

    VLCCloudStorageTableViewCell *cell = (VLCCloudStorageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCCloudStorageTableViewCell cellWithReuseIdentifier:CellIdentifier];

    if (_currentFolder == nil)
        _currentFolder = _oneDriveController.rootFolder;

    if (_currentFolder) {
        NSArray *items = _currentFolder.items;

        if (indexPath.row < items.count) {
            cell.oneDriveFile = items[indexPath.row];
            cell.delegate = self;
        }
    }

    return cell;
}

#pragma mark - table view delegate

- (void)mediaListUpdated
{
    [self.tableView reloadData];
    [self.activityIndicator stopAnimating];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (_currentFolder == nil)
        return;

    NSArray *folderItems = _currentFolder.items;
    NSInteger row = indexPath.row;
    if (row >= folderItems.count)
        return;

    VLCOneDriveObject *selectedObject = folderItems[row];
    if (selectedObject.isFolder) {
        /* dive into sub folder */
        VLCOneDriveTableViewController2 *targetViewController = [[VLCOneDriveTableViewController2 alloc] initWithOneDriveObject:selectedObject];
        [self.navigationController pushViewController:targetViewController animated:YES];
    } else {
        /* stream file */
        NSURL *url = [NSURL URLWithString:selectedObject.downloadPath];
        VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
        [vpc playURL:url successCallback:nil errorCallback:nil];
#if TARGET_OS_TV
        VLCFullscreenMovieTVViewController *movieVC = [VLCFullscreenMovieTVViewController fullscreenMovieTVViewController];
        [self presentViewController:movieVC
                           animated:YES
                         completion:nil];
#endif
    }
}

#pragma mark - onedrive controller delegation

- (void)sessionWasUpdated
{
    [self updateViewAfterSessionChange];
}

@end
