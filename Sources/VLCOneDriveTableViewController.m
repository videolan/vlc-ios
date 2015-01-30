/*****************************************************************************
 * VLCOneDriveTableViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOneDriveTableViewController.h"
#import "VLCOneDriveController.h"
#import "UIBarButtonItem+Theme.h"
#import "VLCCloudStorageTableViewCell.h"
#import "VLCAppDelegate.h"
#import "VLCOneDriveController.h"
#import "VLCProgressView.h"
#import "UIDevice+VLC.h"

@interface VLCOneDriveTableViewController () <VLCCloudStorageDelegate>
{
    VLCOneDriveController *_oneDriveController;
    VLCOneDriveObject *_selectedFile;
}
@end

@implementation VLCOneDriveTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _oneDriveController = (VLCOneDriveController *)[VLCOneDriveController sharedInstance];
    self.controller = _oneDriveController;
    self.controller.delegate = self;

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"OneDriveWhite"]];

    [self.cloudStorageLogo setImage:[UIImage imageNamed:@"OneDriveWhite"]];

    [self.cloudStorageLogo sizeToFit];
    self.cloudStorageLogo.center = self.view.center;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateViewAfterSessionChange];
    self.authorizationInProgress = NO;
}

#pragma mark - generic interface interaction

- (void)goBack
{
    if ((_oneDriveController.rootFolder != _oneDriveController.currentFolder) && [_oneDriveController isAuthorized]) {
        if ([_oneDriveController.rootFolder.name isEqualToString:_oneDriveController.currentFolder.parent.name]) {
            _oneDriveController.currentFolder = nil;
            self.title = _oneDriveController.rootFolder.name;
        } else {
            _oneDriveController.currentFolder = _oneDriveController.currentFolder.parent;
            self.title = _oneDriveController.currentFolder.name;
        }
        [self.activityIndicator startAnimating];
        [_oneDriveController loadCurrentFolder];
    } else
        [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"OneDriveCell";

    VLCCloudStorageTableViewCell *cell = (VLCCloudStorageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCCloudStorageTableViewCell cellWithReuseIdentifier:CellIdentifier];

    cell.oneDriveFile = _oneDriveController.currentFolder.items[indexPath.row];
    cell.delegate = self;

    return cell;
}

#pragma mark - table view delegate

- (void)mediaListUpdated
{
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCOneDriveObject *selectedObject = _oneDriveController.currentFolder.items[indexPath.row];

    if (selectedObject.isFolder) {
        /* dive into sub folder */
        [self.activityIndicator startAnimating];
        _oneDriveController.currentFolder = selectedObject;
        [_oneDriveController loadCurrentFolder];
        self.title = selectedObject.name;
    } else {
        /* stream file */
        NSURL *url = [NSURL URLWithString:selectedObject.downloadPath];
        VLCAppDelegate *appDelegate = (VLCAppDelegate *)[UIApplication sharedApplication].delegate;
        [appDelegate openMovieFromURL:url];
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
        [_oneDriveController downloadObject:_selectedFile];

    _selectedFile = nil;
}

#pragma mark - login dialog

- (void)loginAction:(id)sender
{
    if (![_oneDriveController isAuthorized]) {
        self.authorizationInProgress = YES;
        [_oneDriveController login];
    } else
        [_oneDriveController logout];
}

#pragma mark - onedrive controller delegation

- (void)sessionWasUpdated
{
    [self updateViewAfterSessionChange];
}

#pragma mark - cell delegation

- (void)triggerDownloadForCell:(VLCCloudStorageTableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    _selectedFile = _oneDriveController.currentFolder.items[indexPath.row];

    if (_selectedFile.size.longLongValue < [[UIDevice currentDevice] freeDiskspace].longLongValue) {
        /* selected item is a proper file, ask the user if s/he wants to download it */
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DROPBOX_DOWNLOAD", nil) message:[NSString stringWithFormat:NSLocalizedString(@"DROPBOX_DL_LONG", nil), _selectedFile.name, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:NSLocalizedString(@"BUTTON_DOWNLOAD", nil), nil];
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil) message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), _selectedFile.name, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil) otherButtonTitles:nil];
        [alert show];
    }
}

@end
