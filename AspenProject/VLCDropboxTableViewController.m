//
//  VLCDropboxTableViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 24.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCDropboxTableViewController.h"
#import "VLCDropboxTableViewCell.h"
#import "VLCDropboxController.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"
#import "VLCDropboxConstants.h"
#import <DropboxSDK/DropboxSDK.h>

@interface VLCDropboxTableViewController ()
{
    VLCDropboxController *_dropboxController;
    NSString *_currentPath;

    UIBarButtonItem *_numberOfFilesBarButtonItem;
    UIBarButtonItem *_progressBarButtonItem;
    UIBarButtonItem *_downloadingBarLabel;
    UIProgressView *_progressView;

    UIActivityIndicatorView *_activityIndicator;
    DBMetadata *_selectedFile;
}

@end

@implementation VLCDropboxTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _dropboxController = [[VLCDropboxController alloc] init];
    _dropboxController.delegate = self;

    DBSession* dbSession = [[DBSession alloc] initWithAppKey:kVLCDropboxAppKey appSecret:kVLCDropboxPrivateKey root:kDBRootDropbox];
    [DBSession setSharedSession:dbSession];
    [DBRequest setNetworkRequestDelegate:_dropboxController];

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dropbox-white"]];
    self.navigationItem.titleView.contentMode = UIViewContentModeScaleAspectFit;

    self.tableView.rowHeight = [VLCDropboxTableViewCell heightOfCell];
    self.tableView.separatorColor = [UIColor colorWithWhite:.122 alpha:1.];
    self.view.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];

    _numberOfFilesBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"NUM_OF_FILES", @""), 0] style:UIBarButtonItemStylePlain target:nil action:nil];
    [_numberOfFilesBarButtonItem setTitleTextAttributes:@{ UITextAttributeFont : [UIFont systemFontOfSize:11.] } forState:UIControlStateNormal];

    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    _progressBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_progressView];
    _downloadingBarLabel = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"DOWNLOADING",@"") style:UIBarButtonItemStylePlain target:nil action:nil];
    [_downloadingBarLabel setTitleTextAttributes:@{ UITextAttributeFont : [UIFont systemFontOfSize:11.] } forState:UIControlStateNormal];

    [_loginToDropboxButton setTitle:NSLocalizedString(@"DROPBOX_LOGIN", @"") forState:UIControlStateNormal];

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
        _progressView.progress = 0.;
        [self setToolbarItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], _downloadingBarLabel, _progressBarButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]] animated:YES];
    }
}

- (void)_requestInformationForCurrentPath
{
    [_activityIndicator startAnimating];
    [_dropboxController requestDirectoryListingAtPath:_currentPath];
}

- (IBAction)folderUp:(id)sender
{
    _currentPath = [_currentPath stringByDeletingLastPathComponent];
    [self _requestInformationForCurrentPath];
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

    VLCDropboxTableViewCell *cell = (VLCDropboxTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCDropboxTableViewCell cellWithReuseIdentifier:CellIdentifier];

    cell.fileMetadata = _dropboxController.currentListFiles[indexPath.row];

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
    if (!_selectedFile.isDirectory) {
        /* selected item is a proper file, ask the user if s/he wants to download it */
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DROPBOX_DOWNLOAD", @"") message:[NSString stringWithFormat:NSLocalizedString(@"DROPBOX_DL_LONG", @""), _selectedFile.filename, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"") otherButtonTitles:NSLocalizedString(@"BUTTON_DOWNLOAD", @""), nil];
        [alert show];
    } else {
        /* dive into subdirectory */
        _currentPath = [_currentPath stringByAppendingFormat:@"/%@", _selectedFile.filename];
        [self _requestInformationForCurrentPath];
        _selectedFile = nil;
    }

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

- (void)currentProgressInformation:(float)progress
{
    [_progressView setProgress: progress animated:YES];
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
    } else if (self.loginToDropboxView.superview)
        [self.loginToDropboxView removeFromSuperview];

    _currentPath = @"/";
    [self _requestInformationForCurrentPath];
}

#pragma mark - login dialog

- (void)_showLoginPanel
{
    self.loginToDropboxView.frame = self.tableView.frame;
    [self.tableView addSubview:self.loginToDropboxView];
}

- (IBAction)loginToDropboxAction:(id)sender
{
    if (!_dropboxController.sessionIsLinked)
        [[DBSession sharedSession] linkFromController:self];
    else
        [_dropboxController logout];
}

@end
