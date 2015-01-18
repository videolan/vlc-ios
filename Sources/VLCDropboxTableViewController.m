/*****************************************************************************
 * VLCDropboxTableViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *          Fabio Ritrovato <sephiroth87 # videolan.org>
 *          Tamas Timar <ttimar.vlc # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCDropboxTableViewController.h"
#import "VLCDropboxController.h"
#import "VLCAppDelegate.h"
#import "VLCDropboxConstants.h"
#import "UIDevice+VLC.h"

@interface VLCDropboxTableViewController () <VLCCloudStorageTableViewCell>
{
    VLCDropboxController *_dropboxController;
    DBMetadata *_selectedFile;
}

@end

@implementation VLCDropboxTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _dropboxController = [[VLCDropboxController alloc] init];
    self.controller = _dropboxController;
    self.controller.delegate = self;

    DBSession* dbSession = [[DBSession alloc] initWithAppKey:kVLCDropboxAppKey appSecret:kVLCDropboxPrivateKey root:kDBRootDropbox];
    [DBSession setSharedSession:dbSession];
    [DBRequest setNetworkRequestDelegate:_dropboxController];

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dropbox-white"]];

    [self.cloudStorageLogo setImage:[UIImage imageNamed:@"dropbox-white.png"]];

    [self.cloudStorageLogo sizeToFit];
    self.cloudStorageLogo.center = self.view.center;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateViewAfterSessionChange];
}

#pragma mark - interface interaction

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DropboxCell";

    VLCCloudStorageTableViewCell *cell = (VLCCloudStorageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCCloudStorageTableViewCell cellWithReuseIdentifier:CellIdentifier];

    cell.fileMetadata = _dropboxController.currentListFiles[indexPath.row];
    cell.delegate = self;

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedFile = _dropboxController.currentListFiles[indexPath.row];
    if (!_selectedFile.isDirectory)
        [_dropboxController streamFile:_selectedFile];
    else {
        /* dive into subdirectory */
        self.currentPath = [self.currentPath stringByAppendingFormat:@"/%@", _selectedFile.filename];
        [self _requestInformationForCurrentPath];
    }
    _selectedFile = nil;

    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
        [_dropboxController downloadFileToDocumentFolder:_selectedFile];

    _selectedFile = nil;
}

#pragma mark - login dialog

- (IBAction)loginAction:(id)sender
{
    if (!_dropboxController.isAuthorized) {
        self.authorizationInProgress = YES;
        [[DBSession sharedSession] linkFromController:self];
    } else
        [_dropboxController logout];
}


#pragma mark - VLCCloudStorageTableViewCell delegation
- (void)triggerDownloadForCell:(VLCCloudStorageTableViewCell *)cell
{
    _selectedFile = _dropboxController.currentListFiles[[self.tableView indexPathForCell:cell].row];

    if (_selectedFile.totalBytes < [[UIDevice currentDevice] freeDiskspace].longLongValue) {
        /* selected item is a proper file, ask the user if s/he wants to download it */
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DROPBOX_DOWNLOAD", nil) message:[NSString stringWithFormat:NSLocalizedString(@"DROPBOX_DL_LONG", nil), _selectedFile.filename, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:NSLocalizedString(@"BUTTON_DOWNLOAD", nil), nil];
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil) message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), _selectedFile.filename, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil) otherButtonTitles:nil];
        [alert show];
    }
}

@end
