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

@interface VLCOneDriveTableViewController () <UITableViewDataSource, UITableViewDelegate, VLCOneDriveControllerDelegate, VLCCloudStorageTableViewCell>
{
    UIBarButtonItem *_backButton;
    UIBarButtonItem *_logoutButton;
    UIBarButtonItem *_numberOfFilesBarButtonItem;
    UIBarButtonItem *_progressBarButtonItem;
    VLCProgressView *_progressView;

    UIActivityIndicatorView *_activityIndicator;

    VLCOneDriveController *_oneDriveController;
    NSString *_currentPath;

    VLCOneDriveObject *_selectedFile;
}
@end

@implementation VLCOneDriveTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _oneDriveController = [VLCOneDriveController sharedInstance];
    _oneDriveController.delegate = self;

    self.modalPresentationStyle = UIModalPresentationFormSheet;

    self.navigationItem.title = @"OneDrive";

    _backButton = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = _backButton;

    _logoutButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_LOGOUT", "") style:UIBarButtonItemStyleBordered target:self action:@selector(logout)];

    self.tableView.rowHeight = [VLCCloudStorageTableViewCell heightOfCell];
    self.tableView.separatorColor = [UIColor VLCDarkBackgroundColor];
    self.view.backgroundColor = [UIColor VLCDarkBackgroundColor];

    _numberOfFilesBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"NUM_OF_FILES", nil), 0] style:UIBarButtonItemStylePlain target:nil action:nil];
    [_numberOfFilesBarButtonItem setTitleTextAttributes:@{ UITextAttributeFont : [UIFont systemFontOfSize:11.] } forState:UIControlStateNormal];

    _progressView = [VLCProgressView new];
    _progressBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_progressView];

    self.cloudStorageLogo = nil;
    if (!SYSTEM_RUNS_IOS7_OR_LATER) {
        self.flatLoginButton.hidden = YES;
        [self.loginButton setTitle:NSLocalizedString(@"DROPBOX_LOGIN", nil) forState:UIControlStateNormal];
    } else {
        self.loginButton.hidden = YES;
        [self.flatLoginButton setTitle:NSLocalizedString(@"DROPBOX_LOGIN", nil) forState:UIControlStateNormal];
    }

    [self.navigationController.toolbar setBackgroundImage:[UIImage imageNamed:@"sudHeaderBg"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

    [self _showProgressInToolbar:NO];

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.hidesWhenStopped = YES;
    _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_activityIndicator];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.toolbarHidden = NO;
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    [self.navigationController.toolbar setBackgroundImage:[UIImage imageNamed:@"bottomBlackBar"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

    [super viewWillAppear:animated];

    if (_oneDriveController.activeSession)
        [_oneDriveController login];

    if (!_oneDriveController.userAuthenticated)
        [self _showLoginDialog];

    [self.cloudStorageLogo sizeToFit];
    self.cloudStorageLogo.center = self.view.center;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.toolbarHidden = YES;
    [super viewWillDisappear:animated];
}

#pragma mark - generic interface interaction

- (IBAction)goBack:(id)sender
{
    if (_oneDriveController.rootFolder != _oneDriveController.currentFolder) {
        if ([_oneDriveController.rootFolder.name isEqualToString:_oneDriveController.currentFolder.parent.name]) {
            _oneDriveController.currentFolder = nil;
            self.title = _oneDriveController.rootFolder.name;
        } else {
            _oneDriveController.currentFolder = _oneDriveController.currentFolder.parent;
            self.title = _oneDriveController.currentFolder.name;
        }
        [_activityIndicator startAnimating];
        [_oneDriveController loadCurrentFolder];
    } else
        [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _oneDriveController.currentFolder.items.count;
}

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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor VLCDarkBackgroundColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCOneDriveObject *selectedObject = _oneDriveController.currentFolder.items[indexPath.row];

    if (selectedObject.isFolder) {
        /* dive into sub folder */
        [_activityIndicator startAnimating];
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

- (void)logout
{
    [_oneDriveController logout];
    [self updateViewAfterSessionChange];
}

- (void)_showLoginDialog
{
    self.loginToCloudStorageView.frame = self.tableView.frame;
    self.navigationItem.rightBarButtonItem = nil;
    [self.view addSubview:self.loginToCloudStorageView];
}

- (void)loginAction:(id)sender
{
    [_oneDriveController login];
}

#pragma mark - onedrive controller delegation

- (void)mediaListUpdated
{
    [_activityIndicator stopAnimating];

    [self.tableView reloadData];

    NSUInteger count = _oneDriveController.currentFolder.items.count;
    if (count == 0)
        _numberOfFilesBarButtonItem.title = NSLocalizedString(@"NO_FILES", nil);
    else if (count != 1)
        _numberOfFilesBarButtonItem.title = [NSString stringWithFormat:NSLocalizedString(@"NUM_OF_FILES", nil), count];
    else
        _numberOfFilesBarButtonItem.title = NSLocalizedString(@"ONE_FILE", nil);
}

- (void)sessionWasUpdated
{
    [self updateViewAfterSessionChange];
}

#pragma mark - download visualization

- (void)_showProgressInToolbar:(BOOL)value
{
    if (!value)
        [self setToolbarItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], _numberOfFilesBarButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]] animated:YES];
    else {
        _progressView.progressBar.progress = 0.;
        [self setToolbarItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], _progressBarButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]] animated:YES];
    }
}


- (void)operationWithProgressInformationStarted
{
    [self _showProgressInToolbar:YES];
}

- (void)currentProgressInformation:(float)progress
{
    [_progressView.progressBar setProgress:progress animated:YES];
}

- (void)updateRemainingTime:(NSString *)time
{
    [_progressView updateTime:time];
}

- (void)operationWithProgressInformationStopped
{
    [self _showProgressInToolbar:NO];
}

#pragma mark - app delegate

- (void)updateViewAfterSessionChange
{
    self.navigationItem.rightBarButtonItem = _logoutButton;
    if (![_oneDriveController userAuthenticated]) {
        [self _showLoginDialog];
        return;
    } else if (self.loginToCloudStorageView.superview) {
        [self.loginToCloudStorageView removeFromSuperview];
    }

    if (_oneDriveController.currentFolder != nil)
        [self mediaListUpdated];
    else {
        [_activityIndicator startAnimating];
        [_oneDriveController loadCurrentFolder];
    }
}

#pragma mark - cell delegationx

- (void)triggerDownloadForCell:(VLCCloudStorageTableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    _selectedFile = _oneDriveController.currentFolder.items[indexPath.row];

    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DROPBOX_DOWNLOAD", nil) message:[NSString stringWithFormat:NSLocalizedString(@"DROPBOX_DL_LONG", nil), _selectedFile.name, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:NSLocalizedString(@"BUTTON_DOWNLOAD", nil), nil];
    [alert show];
}

@end
