/*****************************************************************************
 * VLCDropboxTableViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
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
#import "VLCCloudStorageTableViewCell.h"
#import "VLCDropboxController.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"
#import "VLCDropboxConstants.h"
#import "UIBarButtonItem+Theme.h"
#import <DropboxSDK/DropboxSDK.h>

@interface VLCDropboxTableViewController () <VLCCloudStorageTableViewCell>
{
    VLCDropboxController *_dropboxController;
    NSString *_currentPath;

    UIBarButtonItem *_backButton;
    UIBarButtonItem *_backToMenuButton;

    UIBarButtonItem *_numberOfFilesBarButtonItem;
    UIBarButtonItem *_progressBarButtonItem;
    UIBarButtonItem *_downloadingBarLabel;
    UIProgressView *_progressBar;
    UILabel *_progressLabel;

    UIActivityIndicatorView *_activityIndicator;
    DBMetadata *_selectedFile;
}

@end

@implementation VLCDropboxTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.modalPresentationStyle = UIModalPresentationFormSheet;

    _dropboxController = [[VLCDropboxController alloc] init];
    _dropboxController.delegate = self;

    DBSession* dbSession = [[DBSession alloc] initWithAppKey:kVLCDropboxAppKey appSecret:kVLCDropboxPrivateKey root:kDBRootDropbox];
    [DBSession setSharedSession:dbSession];
    [DBRequest setNetworkRequestDelegate:_dropboxController];

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dropbox-white"]];
    self.navigationItem.titleView.contentMode = UIViewContentModeScaleAspectFit;

    _backButton = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(goBack:)];
    _backToMenuButton = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = _backToMenuButton;

    self.tableView.rowHeight = [VLCCloudStorageTableViewCell heightOfCell];
    self.tableView.separatorColor = [UIColor colorWithWhite:.122 alpha:1.];
    self.view.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];

    _numberOfFilesBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"NUM_OF_FILES", @""), 0] style:UIBarButtonItemStylePlain target:nil action:nil];
    [_numberOfFilesBarButtonItem setTitleTextAttributes:@{ UITextAttributeFont : [UIFont systemFontOfSize:11.] } forState:UIControlStateNormal];
    _progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    _progressLabel = [[UILabel alloc] init];
    _progressLabel.textColor = [UIColor whiteColor];
    _progressLabel.font = [UIFont systemFontOfSize:11.];

    UIView *progressView = [[UIView alloc] init];
    [progressView addSubview:_progressBar];
    [progressView addSubview:_progressLabel];

    [progressView addConstraint:[NSLayoutConstraint constraintWithItem:_progressBar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_progressLabel attribute:NSLayoutAttributeWidth multiplier:1.0f constant:0.0f]];
    [progressView addConstraint:[NSLayoutConstraint constraintWithItem:progressView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_progressLabel attribute:NSLayoutAttributeWidth multiplier:1.0f constant:0.0f]];
    [progressView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_progressBar]-[_progressLabel]-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:NSDictionaryOfVariableBindings(_progressBar, _progressLabel)]];

    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    _progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _progressBar.translatesAutoresizingMaskIntoConstraints = NO;

    _progressBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:progressView];

    [self.cloudStorageLogo setImage:[UIImage imageNamed:@"dropbox-white.png"]];
    if (!SYSTEM_RUNS_IOS7_OR_LATER) {
        self.flatLoginButton.hidden = YES;
        [self.loginButton setTitle:NSLocalizedString(@"DROPBOX_LOGIN", @"") forState:UIControlStateNormal];
    } else {
        self.loginButton.hidden = YES;
        [self.flatLoginButton setTitle:NSLocalizedString(@"DROPBOX_LOGIN", @"") forState:UIControlStateNormal];
    }

    [self.navigationController.toolbar setBackgroundImage:[UIImage imageNamed:@"sudHeaderBg"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

    [self _showProgressInToolbar:NO];

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.hidesWhenStopped = YES;

    [self.view addSubview:_activityIndicator];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.toolbarHidden = NO;
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    [self.navigationController.toolbar setBackgroundImage:[UIImage imageNamed:@"bottomBlackBar"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [self updateViewAfterSessionChange];
    [super viewWillAppear:animated];

    CGRect aiFrame = _activityIndicator.frame;
    CGSize tvSize = self.tableView.frame.size;
    aiFrame.origin.x = (tvSize.width - aiFrame.size.width) / 2.;
    aiFrame.origin.y = (tvSize.height - aiFrame.size.height) / 2.;
    _activityIndicator.frame = aiFrame;

    [self.cloudStorageLogo sizeToFit];
    self.cloudStorageLogo.center = self.view.center;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.toolbarHidden = YES;
    [super viewWillDisappear:animated];
}

- (void)_showProgressInToolbar:(BOOL)value
{
    if (!value)
        [self setToolbarItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], _numberOfFilesBarButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]] animated:YES];
    else {
        _progressBar.progress = 0.;
        [self setToolbarItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], _progressBarButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]] animated:YES];
    }
}

- (void)_requestInformationForCurrentPath
{
    [_activityIndicator startAnimating];
    [_dropboxController requestDirectoryListingAtPath:_currentPath];

    self.navigationItem.leftBarButtonItem = ![_currentPath isEqualToString:@"/"] ? _backButton : _backToMenuButton;
}

#pragma mark - interface interaction

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}

- (IBAction)goBack:(id)sender
{
    if (![_currentPath isEqualToString:@"/"] && [_currentPath length] > 0) {
        _currentPath = [_currentPath stringByDeletingLastPathComponent];
        [self _requestInformationForCurrentPath];
    } else
        [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController] toggleSidebar:![(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController].sidebarShowing duration:kGHRevealSidebarDefaultAnimationDuration];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dropboxController.currentListFiles.count;
}

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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor colorWithWhite:.122 alpha:1.];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedFile = _dropboxController.currentListFiles[indexPath.row];
    if (!_selectedFile.isDirectory)
        [_dropboxController streamFile:_selectedFile];
    else {
        /* dive into subdirectory */
        _currentPath = [_currentPath stringByAppendingFormat:@"/%@", _selectedFile.filename];
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

#pragma mark - dropbox controller delegate

- (void)mediaListUpdated
{
    [_activityIndicator stopAnimating];

    [self.tableView reloadData];

    NSUInteger count = _dropboxController.currentListFiles.count;
    if (count == 0)
        _numberOfFilesBarButtonItem.title = NSLocalizedString(@"NO_FILES", @"");
    else if (count != 1)
        _numberOfFilesBarButtonItem.title = [NSString stringWithFormat:NSLocalizedString(@"NUM_OF_FILES", @""), count];
    else
        _numberOfFilesBarButtonItem.title = NSLocalizedString(@"ONE_FILE", @"");
}

- (void)operationWithProgressInformationStarted
{
    [self _showProgressInToolbar:YES];
}

- (void)updateRemainingTime:(NSString *)time
{
    [_progressLabel setText:[NSString stringWithFormat:NSLocalizedString(@"REMAINING_TIME", nil), time]];
    CGSize size = [_progressLabel.text sizeWithFont:_progressLabel.font];
    [_progressLabel setFrame:CGRectMake(_progressLabel.frame.origin.x, _progressLabel.frame.origin.y, size.width, size.height)];
}

- (void)currentProgressInformation:(float)progress {
    [_progressBar setProgress:progress animated:YES];
}

- (void)operationWithProgressInformationStopped
{
    [self _showProgressInToolbar:NO];
}

#pragma mark - communication with app delegate

- (void)updateViewAfterSessionChange
{
    if (![[DBSession sharedSession] isLinked]) {
        [self _showLoginPanel];
        return;
    } else if (self.loginToCloudStorageView.superview)
        [self.loginToCloudStorageView removeFromSuperview];

    _currentPath = @"/";
    [self _requestInformationForCurrentPath];
}

#pragma mark - login dialog

- (void)_showLoginPanel
{
    self.loginToCloudStorageView.frame = self.tableView.frame;
    [self.view addSubview:self.loginToCloudStorageView];
}

- (IBAction)loginAction:(id)sender
{
    if (!_dropboxController.sessionIsLinked)
        [[DBSession sharedSession] linkFromController:self];
    else
        [_dropboxController logout];
}

#pragma mark - table view cell delegation


#pragma mark - VLCLocalNetworkListCell delegation
- (void)triggerDownloadForCell:(VLCCloudStorageTableViewCell *)cell
{
    _selectedFile = _dropboxController.currentListFiles[[self.tableView indexPathForCell:cell].row];

    /* selected item is a proper file, ask the user if s/he wants to download it */
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DROPBOX_DOWNLOAD", @"") message:[NSString stringWithFormat:NSLocalizedString(@"DROPBOX_DL_LONG", @""), _selectedFile.filename, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"") otherButtonTitles:NSLocalizedString(@"BUTTON_DOWNLOAD", @""), nil];
    [alert show];
}

@end
