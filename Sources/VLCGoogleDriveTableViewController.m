/*****************************************************************************
 * VLCGoogleDriveTableViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCGoogleDriveTableViewController.h"
#import "VLCAppDelegate.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "VLCGoogleDriveController.h"
#import "UIDevice+VLC.h"

@interface VLCGoogleDriveTableViewController () <VLCCloudStorageTableViewCell>
{

    VLCGoogleDriveController *_googleDriveController;

    GTLDriveFile *_selectedFile;
    GTMOAuth2ViewControllerTouch *_authController;
}

@end

@implementation VLCGoogleDriveTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _googleDriveController = [VLCGoogleDriveController sharedInstance];
    _googleDriveController.delegate = self;
    self.controller = _googleDriveController;

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DriveWhite"]];

    [self.cloudStorageLogo setImage:[UIImage imageNamed:@"DriveWhite"]];

    [self.cloudStorageLogo sizeToFit];
    self.cloudStorageLogo.center = self.view.center;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateViewAfterSessionChange];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger currentOffset = scrollView.contentOffset.y;
    NSInteger maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;

    if (maximumOffset - currentOffset <= - self.tableView.rowHeight) {
        if (_googleDriveController.hasMoreFiles && !self.activityIndicator.isAnimating) {
            [self _requestInformationForCurrentPath];
        }
    }
}

- (GTMOAuth2ViewControllerTouch *)createAuthController
{
    _authController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeDrive
                                                                clientID:kVLCGoogleDriveClientID
                                                            clientSecret:kVLCGoogleDriveClientSecret
                                                        keychainItemName:kKeychainItemName
                                                                delegate:self
                                                        finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    return _authController;
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController finishedWithAuth:(GTMOAuth2Authentication *)authResult error:(NSError *)error
{
    self.authorizationInProgress = NO;
    if (error != nil) {
        _googleDriveController.driveService.authorizer = nil;
    } else {
        _googleDriveController.driveService.authorizer = authResult;
    }
    [self updateViewAfterSessionChange];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ((VLCAppDelegate *)[UIApplication sharedApplication].delegate.window.rootViewController.presentedViewController == nil) {
        [_googleDriveController stopSession];
        [self.tableView reloadData];
    }

}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GoogleDriveCell";

    VLCCloudStorageTableViewCell *cell = (VLCCloudStorageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCCloudStorageTableViewCell cellWithReuseIdentifier:CellIdentifier];

    cell.driveFile = _googleDriveController.currentListFiles[indexPath.row];
    if ([cell.driveFile.mimeType isEqualToString:@"application/vnd.google-apps.folder"])
        [cell setIsDownloadable:NO];
    else
        [cell setIsDownloadable:YES];

    cell.delegate = self;

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedFile = _googleDriveController.currentListFiles[indexPath.row];
    if (![_selectedFile.mimeType isEqualToString:@"application/vnd.google-apps.folder"]) {
        [_googleDriveController streamFile:_selectedFile];
    } else {
        /* dive into subdirectory */
        if (![self.currentPath isEqualToString:@""])
            self.currentPath = [self.currentPath stringByAppendingString:@"/"];
        self.currentPath = [self.currentPath stringByAppendingString:_selectedFile.identifier];
        [self _requestInformationForCurrentPath];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)triggerDownloadForCell:(VLCCloudStorageTableViewCell *)cell
{
    _selectedFile = _googleDriveController.currentListFiles[[self.tableView indexPathForCell:cell].row];

    if (_selectedFile.fileSize.longLongValue < [[UIDevice currentDevice] freeDiskspace].longLongValue) {
        /* selected item is a proper file, ask the user if s/he wants to download it */
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DROPBOX_DOWNLOAD", nil) message:[NSString stringWithFormat:NSLocalizedString(@"DROPBOX_DL_LONG", nil), _selectedFile.title, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:NSLocalizedString(@"BUTTON_DOWNLOAD", nil), nil];
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil) message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), _selectedFile.title, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil) otherButtonTitles:nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
        [_googleDriveController downloadFileToDocumentFolder:_selectedFile];
    _selectedFile = nil;
}

#pragma mark - login dialog

- (IBAction)loginAction:(id)sender
{
    if (![_googleDriveController isAuthorized]) {
        self.authorizationInProgress = YES;
        [self.navigationController pushViewController:[self createAuthController] animated:YES];
    } else {
        [_googleDriveController logout];
    }
}

@end
