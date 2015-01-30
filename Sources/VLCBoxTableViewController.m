/*****************************************************************************
 * VLCBoxTableViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCBoxTableViewController.h"
#import "VLCBoxController.h"
#import "VLCAppDelegate.h"
#import <SSKeychain/SSKeychain.h>
#import "UIDevice+VLC.h"

@interface VLCBoxTableViewController () <VLCCloudStorageTableViewCell, BoxAuthorizationViewControllerDelegate, VLCCloudStorageDelegate>
{
    BoxFile *_selectedFile;
    VLCBoxController *_boxController;
}

@end

@implementation VLCBoxTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _boxController = (VLCBoxController *)[VLCBoxController sharedInstance];
    [_boxController startSession];
    self.controller = _boxController;
    self.controller.delegate = self;

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BoxWhite"]];

    [self.cloudStorageLogo setImage:[UIImage imageNamed:@"BoxWhite"]];

    [self.cloudStorageLogo sizeToFit];
    self.cloudStorageLogo.center = self.view.center;
    
    // Handle logged in
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boxApiTokenDidRefresh)
                                                 name:BoxOAuth2SessionDidRefreshTokensNotification
                                               object:[BoxSDK sharedSDK].OAuth2Session];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boxApiTokenDidRefresh)
                                                 name:BoxOAuth2SessionDidBecomeAuthenticatedNotification
                                               object:[BoxSDK sharedSDK].OAuth2Session];
    // Handle logout
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boxDidGetLoggedOut)
                                                 name:BoxOAuth2SessionDidReceiveAuthenticationErrorNotification
                                               object:[BoxSDK sharedSDK].OAuth2Session];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boxDidGetLoggedOut)
                                                 name:BoxOAuth2SessionDidReceiveRefreshErrorNotification
                                               object:[BoxSDK sharedSDK].OAuth2Session];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boxAPIAuthenticationDidFail)
                                                 name:BoxOAuth2SessionDidReceiveAuthenticationErrorNotification
                                               object:[BoxSDK sharedSDK].OAuth2Session];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boxAPIInitiateLogin)
                                                 name:BoxOAuth2SessionDidReceiveRefreshErrorNotification
                                               object:[BoxSDK sharedSDK].OAuth2Session];

}

- (UIViewController *)createAuthController
{
    NSURL *authorizationURL = [[BoxSDK sharedSDK].OAuth2Session authorizeURL];
    BoxAuthorizationViewController *authorizationController = [[BoxAuthorizationViewController alloc] initWithAuthorizationURL:authorizationURL redirectURI:kVLCBoxRedirectURL];
    authorizationController.delegate = self;
    return authorizationController;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.currentPath = @"";
    if([_boxController.currentListFiles count] == 0)
        [self _requestInformationForCurrentPath];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ((VLCAppDelegate*)[UIApplication sharedApplication].delegate.window.rootViewController.presentedViewController == nil) {
        [_boxController stopSession];
        [self.tableView reloadData];
    }
}

#pragma mark - Table view data source

- (VLCCloudStorageTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"BoxCell";

    VLCCloudStorageTableViewCell *cell = (VLCCloudStorageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCCloudStorageTableViewCell cellWithReuseIdentifier:CellIdentifier];

    cell.boxFile = _boxController.currentListFiles[indexPath.row];
    cell.delegate = self;

    return cell;
}

#pragma mark - Table view delegate

- (void)mediaListUpdated
{
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedFile = _boxController.currentListFiles[indexPath.row];
    if (![_selectedFile.type isEqualToString:@"folder"])
        [_boxController streamFile:(BoxFile *)_selectedFile];
    else {
        /* dive into subdirectory */
        if (![self.currentPath isEqualToString:@""])
            self.currentPath = [self.currentPath stringByAppendingString:@"/"];
        self.currentPath = [self.currentPath stringByAppendingString:_selectedFile.modelID];
        [self _requestInformationForCurrentPath];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)triggerDownloadForCell:(VLCCloudStorageTableViewCell *)cell
{
    _selectedFile = _boxController.currentListFiles[[self.tableView indexPathForCell:cell].row];

    if (_selectedFile.size.longLongValue < [[UIDevice currentDevice] freeDiskspace].longLongValue) {
        /* selected item is a proper file, ask the user if s/he wants to download it */
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DROPBOX_DOWNLOAD", nil) message:[NSString stringWithFormat:NSLocalizedString(@"DROPBOX_DL_LONG", nil), _selectedFile.name, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:NSLocalizedString(@"BUTTON_DOWNLOAD", nil), nil];
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil) message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), _selectedFile.name, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil) otherButtonTitles:nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
        [_boxController downloadFileToDocumentFolder:_selectedFile];
    _selectedFile = nil;
}

#pragma mark - box controller delegate

#pragma mark - BoxAuthorizationViewControllerDelegate

- (BOOL)authorizationViewController:(BoxAuthorizationViewController *)authorizationViewController shouldLoadReceivedOAuth2RedirectRequest:(NSURLRequest *)request
{
    [[BoxSDK sharedSDK].OAuth2Session performAuthorizationCodeGrantWithReceivedURL:request.URL];
    [self.navigationController popViewControllerAnimated:YES];
    return NO;
}

- (void)authorizationViewControllerDidStartLoading:(BoxAuthorizationViewController *)authorizationViewController
{
    //needs to be implemented
}

- (void)authorizationViewControllerDidFinishLoading:(BoxAuthorizationViewController *)authorizationViewController
{
    //needs to be implemented
}

- (void)boxDidGetLoggedOut
{
    [self _showLoginPanel];
}

- (void)boxApiTokenDidRefresh
{
    NSString *token = [BoxSDK sharedSDK].OAuth2Session.refreshToken;
    [SSKeychain setPassword:token forService:kVLCBoxService account:kVLCBoxAccount];
    self.authorizationInProgress = YES;
    [self updateViewAfterSessionChange];
    self.authorizationInProgress = NO;
}

- (void)boxAPIAuthenticationDidFail
{
    //needs to be implemented
}

- (void)boxAPIInitiateLogin
{
    [self _showLoginPanel];
}

- (void)authorizationViewControllerDidCancel:(BoxAuthorizationViewController *)authorizationViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger currentOffset = scrollView.contentOffset.y;
    NSInteger maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;

    if (maximumOffset - currentOffset <= - self.tableView.rowHeight) {
        if (_boxController.hasMoreFiles && !self.activityIndicator.isAnimating) {
            [self _requestInformationForCurrentPath];
        }
    }
}
#pragma mark - login dialog

- (IBAction)loginAction:(id)sender
{
    if (![_boxController isAuthorized]) {
        self.authorizationInProgress = YES;
        [self.navigationController pushViewController:[self createAuthController] animated:YES];
    } else {
        [_boxController logout];
    }
}

@end
