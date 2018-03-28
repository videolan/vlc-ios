/*****************************************************************************
 * VLCCloudStorageTableViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Fabio Ritrovato <sephiroth87 # videolan.org>
 *          Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCloudStorageTableViewController.h"
#import "VLCCloudStorageTableViewCell.h"
#import "VLCProgressView.h"
#import "VLC_iOS-Swift.h"

@interface VLCCloudStorageTableViewController()
{
    VLCProgressView *_progressView;
    UIRefreshControl *_refreshControl;
    UIBarButtonItem *_progressBarButtonItem;
    UIBarButtonItem *_logoutButton;
}

@end

@implementation VLCCloudStorageTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _authorizationInProgress = NO;

    self.modalPresentationStyle = UIModalPresentationFormSheet;

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_BACK", nil) style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = backButton;

    _logoutButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_LOGOUT", "") style:UIBarButtonItemStylePlain target:self action:@selector(logout)];

    [self.loginButton setTitle:NSLocalizedString(@"DROPBOX_LOGIN", nil) forState:UIControlStateNormal];

    [self.navigationController.toolbar setBackgroundImage:[UIImage imageNamed:@"sudHeaderBg"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForTheme) name:kVLCThemeDidChangeNotification object:nil];

    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.tintColor = [UIColor whiteColor];
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:_refreshControl];

    self.navigationItem.titleView.contentMode = UIViewContentModeScaleAspectFit;

    self.tableView.rowHeight = [VLCCloudStorageTableViewCell heightOfCell];

    _numberOfFilesBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"NUM_OF_FILES", nil), 0] style:UIBarButtonItemStylePlain target:nil action:nil];
    [_numberOfFilesBarButtonItem setTitleTextAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:11.] } forState:UIControlStateNormal];
    _numberOfFilesBarButtonItem.tintColor = PresentationTheme.current.colors.orangeUI;

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.hidesWhenStopped = YES;
    _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:_activityIndicator];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];

    _progressView = [VLCProgressView new];
    _progressBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_progressView];
    _progressView.tintColor = PresentationTheme.current.colors.orangeUI;

    [self _showProgressInToolbar:NO];
    [self updateForTheme];
}

- (void)updateForTheme
{
    self.tableView.separatorColor = PresentationTheme.current.colors.background;
    self.tableView.backgroundColor = PresentationTheme.current.colors.background;
    self.view.backgroundColor = PresentationTheme.current.colors.background;
    _refreshControl.backgroundColor = PresentationTheme.current.colors.background;
    _activityIndicator.activityIndicatorViewStyle = PresentationTheme.current == PresentationTheme.brightTheme ? UIActivityIndicatorViewStyleGray : UIActivityIndicatorViewStyleWhiteLarge;
    self.loginToCloudStorageView.backgroundColor = PresentationTheme.current.colors.background;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.toolbarHidden = NO;
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    [self.navigationController.toolbar setBackgroundImage:[UIImage imageNamed:@"bottomBlackBar"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.toolbarHidden = YES;
    [super viewWillDisappear:animated];
}

-(void)handleRefresh
{
    //set the title while refreshing
    _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"LOCAL_SERVER_REFRESH",nil)];
    //set the date and time of refreshing
    NSDateFormatter *formattedDate = [[NSDateFormatter alloc]init];
    [formattedDate setDateFormat:@"MMM d, h:mm a"];
    NSString *lastupdated = [NSString stringWithFormat:NSLocalizedString(@"LOCAL_SERVER_LAST_UPDATE",nil),[formattedDate stringFromDate:[NSDate date]]];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastupdated attributes:attrsDictionary];

    [self requestInformationForCurrentPath];
}

- (void)requestInformationForCurrentPath
{
    [_activityIndicator startAnimating];
    [self.controller requestDirectoryListingAtPath:self.currentPath];
}

- (void)mediaListUpdated
{
    [_activityIndicator stopAnimating];
    [_refreshControl endRefreshing];

    [self.tableView reloadData];

    NSUInteger count = self.controller.currentListFiles.count;
    if (count == 0)
        self.numberOfFilesBarButtonItem.title = NSLocalizedString(@"NO_FILES", nil);
    else if (count != 1)
        self.numberOfFilesBarButtonItem.title = [NSString stringWithFormat:NSLocalizedString(@"NUM_OF_FILES", nil), count];
    else
        self.numberOfFilesBarButtonItem.title = NSLocalizedString(@"ONE_FILE", nil);
}

- (void)_showProgressInToolbar:(BOOL)value
{
    if (!value)
        [self setToolbarItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], _numberOfFilesBarButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]] animated:YES];
    else {
        _progressView.progressBar.progress = 0.;
        [self setToolbarItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], _progressBarButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]] animated:YES];
    }
}

- (void)updateRemainingTime:(NSString *)time
{
    [_progressView updateTime:time];
}

- (void)currentProgressInformation:(CGFloat)progress
{
    [_progressView.progressBar setProgress:progress animated:YES];
}

- (void)operationWithProgressInformationStarted
{
    [self _showProgressInToolbar:YES];
}

- (void)operationWithProgressInformationStopped
{
    [self _showProgressInToolbar:NO];
}
#pragma mark - UITableViewDataSources

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.controller.currentListFiles.count;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(__kindof UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCCloudStorageTableViewCell *cloudcell = [cell isKindOfClass:VLCCloudStorageTableViewCell.class] ? (id)cell : nil;
    cloudcell.backgroundColor = (indexPath.row % 2 == 0)? PresentationTheme.current.colors.cellBackgroundB : PresentationTheme.current.colors.cellBackgroundA;
    cloudcell.titleLabel.textColor = PresentationTheme.current.colors.cellTextColor;
    cloudcell.folderTitleLabel.textColor = PresentationTheme.current.colors.cellTextColor;
    cloudcell.subtitleLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor;
}

- (void)goBack
{
    if (((![self.currentPath isEqualToString:@""] && ![self.currentPath isEqualToString:@"/"]) && [self.currentPath length] > 0) && [self.controller isAuthorized]){
        self.currentPath = [self.currentPath stringByDeletingLastPathComponent];
        [self requestInformationForCurrentPath];
    } else
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)showLoginPanel
{
    self.loginToCloudStorageView.frame = self.tableView.frame;
    self.navigationItem.rightBarButtonItem = nil;
    [self.tableView addSubview:self.loginToCloudStorageView];
}

- (void)updateViewAfterSessionChange
{
    if (self.controller.canPlayAll) {
        self.navigationItem.rightBarButtonItems = @[_logoutButton, [UIBarButtonItem themedPlayAllButtonWithTarget:self andSelector:@selector(playAllAction:)]];
    } else {
        self.navigationItem.rightBarButtonItem = _logoutButton;
    }

    if(_authorizationInProgress || [self.controller isAuthorized]) {
        if (self.loginToCloudStorageView.superview) {
            [self.loginToCloudStorageView removeFromSuperview];
        }
    }

    if (![self.controller isAuthorized]) {
        [_activityIndicator stopAnimating];
        [self showLoginPanel];
        return;
    }

    //reload if we didn't come back from streaming
    if (self.currentPath == nil) {
        self.currentPath = @"";
    }
    if([self.controller.currentListFiles count] == 0)
        [self requestInformationForCurrentPath];
}

- (void)logout
{
    [self.controller logout];
    [self updateViewAfterSessionChange];
}

- (IBAction)loginAction:(id)sender
{
}

- (IBAction)playAllAction:(id)sender
{
}

@end
