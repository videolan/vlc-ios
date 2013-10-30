//
//  VLCGoogleDriveTableViewController.m
//  VLC for iOS
//
//  Created by Carola Nitz on 21.09.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCGoogleDriveTableViewController.h"
#import "VLCGoogleDriveTableViewCell.h"
#import "VLCGoogleDriveController.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"
#import "UIBarButtonItem+Theme.h"
#import "VLCGoogleDriveConstants.h"
#import "GTMOAuth2ViewControllerTouch.h"

static NSString *const kKeychainItemName = @"Google Drive Quickstart #3";

@interface VLCGoogleDriveTableViewController ()
{
    VLCGoogleDriveController *_googleDriveController;
    GTMOAuth2ViewControllerTouch *_authController;
    NSString *_currentPath;

    UIBarButtonItem *_backButton;
    UIBarButtonItem *_backToMenuButton;

    UIBarButtonItem *_numberOfFilesBarButtonItem;
    UIBarButtonItem *_progressBarButtonItem;
    UIBarButtonItem *_downloadingBarLabel;
    UIProgressView *_progressView;

    UIActivityIndicatorView *_activityIndicator;
}

@end

@implementation VLCGoogleDriveTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.modalPresentationStyle = UIModalPresentationFormSheet;

    _googleDriveController = [[VLCGoogleDriveController alloc] init];
    _googleDriveController.delegate = self;
    [_googleDriveController startSession];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DriveWhite"]];
    self.navigationItem.titleView.contentMode = UIViewContentModeScaleAspectFit;

    _backButton = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(goBack:)];
    _backToMenuButton = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = _backToMenuButton;

    self.tableView.rowHeight = [VLCGoogleDriveTableViewCell heightOfCell];
    self.tableView.separatorColor = [UIColor colorWithWhite:.122 alpha:1.];
    self.view.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];

    _numberOfFilesBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"NUM_OF_FILES", @""), 0] style:UIBarButtonItemStylePlain target:nil action:nil];
    [_numberOfFilesBarButtonItem setTitleTextAttributes:@{ UITextAttributeFont : [UIFont systemFontOfSize:11.] } forState:UIControlStateNormal];

    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    _progressBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_progressView];
    _downloadingBarLabel = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"DOWNLOADING",@"") style:UIBarButtonItemStylePlain target:nil action:nil];
    [_downloadingBarLabel setTitleTextAttributes:@{ UITextAttributeFont : [UIFont systemFontOfSize:11.] } forState:UIControlStateNormal];

    [_loginToGoogleDriveButton setTitle:NSLocalizedString(@"DROPBOX_LOGIN", @"") forState:UIControlStateNormal];

    [self.navigationController.toolbar setBackgroundImage:[UIImage imageNamed:@"sudHeaderBg"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

    [self _showProgressInToolbar:NO];

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.hidesWhenStopped = YES;

    [self.view addSubview:_activityIndicator];
}

- (GTMOAuth2ViewControllerTouch *)createAuthController
{
    _authController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeDriveFile
                                                                clientID:kVLCGoogleDriveClientID
                                                            clientSecret:kVLCGoogleDriveClientSecret
                                                        keychainItemName:kKeychainItemName
                                                                delegate:self
                                                        finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    return _authController;
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)authResult
                 error:(NSError *)error
{
    if (error != nil)
    {
        [self showAlert:@"Authentication Error" message:error.localizedDescription];
        _googleDriveController.driveService.authorizer = nil;
    }
    else
    {
        _googleDriveController.driveService.authorizer = authResult;
    }
    [self updateViewAfterSessionChange];
}

- (void)showAlert:(NSString *)title message:(NSString *)message
{
    UIAlertView *alert;
    alert = [[UIAlertView alloc] initWithTitle: title
                                       message: message
                                      delegate: nil
                             cancelButtonTitle: @"OK"
                             otherButtonTitles: nil];
    [alert show];
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
    [_googleDriveController requestDirectoryListingAtPath:_currentPath];

    self.navigationItem.leftBarButtonItem = ![_currentPath isEqualToString:@"/"] ? _backButton : _backToMenuButton;
}

#pragma mark - interface interaction

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
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
    return _googleDriveController.currentListFiles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GoogleDriveCell";

    VLCGoogleDriveTableViewCell *cell = (VLCGoogleDriveTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCGoogleDriveTableViewCell cellWithReuseIdentifier:CellIdentifier];

   // cell.fileMetadata = _googleDriveController.currentListFiles[indexPath.row];

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor colorWithWhite:.122 alpha:1.];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    _selectedFile = _googleDriveController.currentListFiles[indexPath.row];
//    if (!_selectedFile.isDirectory) {
//        /* selected item is a proper file, ask the user if s/he wants to download it */
//        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"GOOGLE_DRIVE_DOWNLOAD", @"") message:[NSString stringWithFormat:NSLocalizedString(@"GOOGLE_DRIVE_DL_LONG", @""), _selectedFile.filename, [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"") otherButtonTitles:NSLocalizedString(@"BUTTON_DOWNLOAD", @""), nil];
//        [alert show];
//    } else {
//        /* dive into subdirectory */
//        _currentPath = [_currentPath stringByAppendingFormat:@"/%@", _selectedFile.filename];
//        [self _requestInformationForCurrentPath];
//        _selectedFile = nil;
//    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
   // if (buttonIndex == 1)
      //  [_googleDriveController downloadFileToDocumentFolder:_selectedFile];

   // _selectedFile = nil;
}

#pragma mark - dropbox controller delegate

- (void)mediaListUpdated
{
    [_activityIndicator stopAnimating];

    [self.tableView reloadData];

    NSUInteger count = _googleDriveController.currentListFiles.count;
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
    if (![_googleDriveController isAuthorized]) {
        [self _showLoginPanel];
        return;
    } else if (self.loginToGoogleDriveView.superview)
        [self.loginToGoogleDriveView removeFromSuperview];
        _currentPath = @"/";
    [self _requestInformationForCurrentPath];
}

#pragma mark - login dialog

- (void)_showLoginPanel
{
    self.loginToGoogleDriveView.frame = self.tableView.frame;
    [self.view addSubview:self.loginToGoogleDriveView];
}

- (IBAction)loginToGoogleDriveAction:(id)sender
{
    if (![_googleDriveController isAuthorized]) {
        _googleDriveController.isAuthorized = NO;
        [self.navigationController pushViewController:[self createAuthController] animated:YES];
    } else {
        _googleDriveController.isAuthorized = YES;
        [_googleDriveController logout];
    }
}

@end
