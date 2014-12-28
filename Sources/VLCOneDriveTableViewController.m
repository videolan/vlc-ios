/*****************************************************************************
 * VLCOneDriveTableViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
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

@interface VLCOneDriveTableViewController () <UITableViewDataSource, UITableViewDelegate>
{
    UIBarButtonItem *_backButton;
    UIBarButtonItem *_backToMenuButton;

    UIActivityIndicatorView *_activityIndicator;

    VLCOneDriveController *_oneDriveController;
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
    _backToMenuButton = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = _backToMenuButton;

    self.tableView.rowHeight = [VLCCloudStorageTableViewCell heightOfCell];
    self.tableView.separatorColor = [UIColor VLCDarkBackgroundColor];
    self.view.backgroundColor = [UIColor VLCDarkBackgroundColor];

    self.cloudStorageLogo = nil;
    if (!SYSTEM_RUNS_IOS7_OR_LATER) {
        self.flatLoginButton.hidden = YES;
        [self.loginButton setTitle:NSLocalizedString(@"ONEDRIVE_LOGIN", nil) forState:UIControlStateNormal];
    } else {
        self.loginButton.hidden = YES;
        [self.flatLoginButton setTitle:NSLocalizedString(@"ONEDRIVE_LOGIN", nil) forState:UIControlStateNormal];
    }

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.hidesWhenStopped = YES;
    _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_activityIndicator];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // FIXME: we should update the listing...
    [self _showLoginDialog];

    [self.cloudStorageLogo sizeToFit];
    self.cloudStorageLogo.center = self.view.center;
}

#pragma mark - generic interface interaction

- (IBAction)goBack:(id)sender
{
    [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController] toggleSidebar:![(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController].sidebarShowing duration:kGHRevealSidebarDefaultAnimationDuration];
}

#pragma mark - table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor VLCDarkBackgroundColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark - login dialog
- (void)_showLoginDialog
{
    self.loginToCloudStorageView.frame = self.tableView.frame;
    [self.view addSubview:self.loginToCloudStorageView];
}

- (void)loginAction:(id)sender
{
    if (![_oneDriveController activeSession])
        [_oneDriveController login];
    else
        [_oneDriveController logout];
}

@end
