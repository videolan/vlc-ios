/*****************************************************************************
 * VLCCloudStorageTableViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2019 VideoLAN. All rights reserved.
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
#import "VLC-Swift.h"

typedef NS_ENUM(NSInteger, VLCToolbarStyle) {
    VLCToolbarStyleNone,
    VLCToolbarStyleProgress,
    VLCToolbarStyleSortAndNumOfFiles,
    VLCToolbarStyleNumOfFiles
};

@interface VLCCloudStorageTableViewController()
{
    VLCProgressView *_progressView;
    VLCActionSheet *sheet;
    VLCCloudSortingSpecifierManager *manager;
    UIRefreshControl *_refreshControl;
    UIBarButtonItem *_progressBarButtonItem;
    UIBarButtonItem *_logoutButton;
    UINavigationController *tempNav;
}

@end

@implementation VLCCloudStorageTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _authorizationInProgress = NO;
    ColorPalette *colors = PresentationTheme.current.colors;

    self.modalPresentationStyle = UIModalPresentationFormSheet;

    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_BACK", nil) style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = backButton;

    _logoutButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_LOGOUT", "") style:UIBarButtonItemStylePlain target:self action:@selector(logout)];

    [self.loginButton setTitle:NSLocalizedString(@"DROPBOX_LOGIN", nil) forState:UIControlStateNormal];
    [self.loginButton setTitleColor:colors.orangeUI forState:UIControlStateNormal];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(updateForTheme) name:kVLCThemeDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(updateForSizing) name:UIContentSizeCategoryDidChangeNotification object:nil];

    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.tintColor = [UIColor whiteColor];
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:_refreshControl];

    self.navigationItem.titleView.contentMode = UIViewContentModeScaleAspectFit;

    self.tableView.rowHeight = [VLCCloudStorageTableViewCell heightOfCell];

    _numberOfFilesBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"NUM_OF_FILES", nil), 0] style:UIBarButtonItemStylePlain target:nil action:nil];
    _sortBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"SORT", nil), 0]
                                                          style:UIBarButtonItemStylePlain target:self action:@selector(sortButtonClicked:)];
    _sortBarButtonItem.tintColor = colors.orangeUI;
    _numberOfFilesBarButtonItem.tintColor = colors.orangeUI;

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.hidesWhenStopped = YES;
    _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:_activityIndicator];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];

    _progressView = [VLCProgressView new];
    _progressBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_progressView];
    _progressView.tintColor = colors.orangeUI;

    sheet = [[VLCActionSheet alloc] init];
    manager = [[VLCCloudSortingSpecifierManager alloc] initWithController: self];
    sheet.dataSource = manager;
    sheet.delegate = manager;
    sheet.modalPresentationStyle = UIModalPresentationCustom;
    [sheet.collectionView registerClass:[VLCActionSheetCell class] forCellWithReuseIdentifier:VLCActionSheetCell.identifier];

    [self updateToolbarWithProgress:nil];
    [self updateForTheme];
}

- (void)updateForTheme
{
    ColorPalette *colors = PresentationTheme.current.colors;
    self.tableView.separatorColor = colors.background;
    self.tableView.backgroundColor = colors.background;
    self.view.backgroundColor = colors.background;
    _refreshControl.backgroundColor = colors.background;
    _activityIndicator.activityIndicatorViewStyle = PresentationTheme.current == PresentationTheme.brightTheme ? UIActivityIndicatorViewStyleGray : UIActivityIndicatorViewStyleWhiteLarge;
    self.loginToCloudStorageView.backgroundColor = colors.background;
    self.navigationController.toolbar.barStyle = colors.toolBarStyle;
    _progressView.progressLabel.textColor = colors.cellTextColor;
}

- (void)updateForSizing
{
    self.tableView.rowHeight = [VLCCloudStorageTableViewCell heightOfCell];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    //Workaround since in viewWillDisappear self.navigationController can be nil which will lead to a lingering toolbar
    tempNav = self.navigationController;
    tempNav.toolbarHidden = NO;
    [super viewWillAppear:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return PresentationTheme.current.colors.statusBarStyle;
}

- (void)viewWillDisappear:(BOOL)animated
{
    tempNav.toolbarHidden = YES;
    tempNav = nil;
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

    [self updateToolbarWithProgress:nil];
    NSUInteger count = self.controller.currentListFiles.count;
    if (count == 0)
        self.numberOfFilesBarButtonItem.title = NSLocalizedString(@"NO_FILES", nil);
    else if (count != 1)
        self.numberOfFilesBarButtonItem.title = [NSString stringWithFormat:NSLocalizedString(@"NUM_OF_FILES", nil), count];
    else
        self.numberOfFilesBarButtonItem.title = NSLocalizedString(@"ONE_FILE", nil);
}

- (void)updateToolbarWithProgress:(NSNumber *)progress {
    if (progress != nil) {
        _progressView.progressBar.progress = progress.floatValue;
        [self updateToolbarWithStyle:VLCToolbarStyleProgress];
    } else if (!self.controller.isAuthorized) {
        [self updateToolbarWithStyle:VLCToolbarStyleNone];
    } else if ([self.controller supportSorting]) {
        [self updateToolbarWithStyle:VLCToolbarStyleSortAndNumOfFiles];
    } else {
        [self updateToolbarWithStyle:VLCToolbarStyleNumOfFiles];
    }
}

- (void)updateToolbarWithStyle:(VLCToolbarStyle)style {
    NSMutableArray *items = [NSMutableArray arrayWithObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    switch(style) {
        case VLCToolbarStyleNone:
            break;
        case VLCToolbarStyleProgress:
            [items addObjectsFromArray:@[_progressBarButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]]];
            break;
        case VLCToolbarStyleSortAndNumOfFiles:
            [items addObjectsFromArray:@[_sortBarButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]]];
            // no break to continue to VLCToolbarStyleNumOfFiles
        case VLCToolbarStyleNumOfFiles:
            [items addObjectsFromArray:@[_numberOfFilesBarButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]]];
            break;
    }
    [self setToolbarItems:items animated:YES];
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
    [self updateToolbarWithProgress:@(0)];
}

- (void)operationWithProgressInformationStopped
{
    [self updateToolbarWithProgress:nil];
}

#pragma mark - UITableViewDataSources

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.controller.currentListFiles.count;
}

#pragma mark - UITableViewDelegate

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
    BOOL hasProgressbar = NO;
    for (id item in self.toolbarItems) {
        if (item == _progressBarButtonItem) {
            hasProgressbar = YES;
        }
    }
    if (!hasProgressbar) {
        [self updateToolbarWithProgress:nil];
    }
    if (_authorizationInProgress || [self.controller isAuthorized]) {
        if (self.loginToCloudStorageView.superview) {
            [self.loginToCloudStorageView removeFromSuperview];
        }
    }
    if (![self.controller isAuthorized]) {
        [_activityIndicator stopAnimating];
        [self showLoginPanel];
        return;
    }

    //  Set right bar buttons after cloud access is authorized
    if (self.controller.canPlayAll) {
        self.navigationItem.rightBarButtonItems = @[
            _logoutButton,
            [UIBarButtonItem themedPlayAllButtonWithTarget:self andSelector:@selector(playAllAction:)]
        ];
    } else {
        self.navigationItem.rightBarButtonItem = _logoutButton;
    }

    // Reload if we didn't come back from streaming
    if (self.currentPath == nil) {
        self.currentPath = @"";
    }

    if ([self.controller.currentListFiles count] == 0) {
        [self requestInformationForCurrentPath];
    }
}

- (void)logout
{
    _currentPath = nil;
    [self.controller logout];
    [self updateViewAfterSessionChange];
}

- (void)sortButtonClicked:(UIBarButtonItem*)sender
{
    [self presentViewController:self->sheet animated:YES completion:^{
        [self->sheet.collectionView selectItemAtIndexPath:self->manager.selectedIndex animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
    }];
}

- (IBAction)loginAction:(id)sender
{
}

- (IBAction)playAllAction:(id)sender
{
}

@end
