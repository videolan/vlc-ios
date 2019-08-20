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

    self.modalPresentationStyle = UIModalPresentationFormSheet;

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_BACK", nil) style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = backButton;

    _logoutButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_LOGOUT", "") style:UIBarButtonItemStylePlain target:self action:@selector(logout)];

    [self.loginButton setTitle:NSLocalizedString(@"DROPBOX_LOGIN", nil) forState:UIControlStateNormal];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForTheme) name:kVLCThemeDidChangeNotification object:nil];

    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.tintColor = [UIColor whiteColor];
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:_refreshControl];

    self.navigationItem.titleView.contentMode = UIViewContentModeScaleAspectFit;

    self.tableView.rowHeight = [VLCCloudStorageTableViewCell heightOfCell];

    _numberOfFilesBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"NUM_OF_FILES", nil), 0] style:UIBarButtonItemStylePlain target:nil action:nil];
    _sortBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: [NSString stringWithFormat:NSLocalizedString(@"SORT", nil), 0]
                                                          style:UIBarButtonItemStylePlain target:self action:@selector(sortButtonClicked:)];
    _sortBarButtonItem.tintColor = PresentationTheme.current.colors.orangeUI;
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
    _progressView.progressLabel.textColor = PresentationTheme.current.colors.cellTextColor;
    
    sheet = [[VLCActionSheet alloc] init];
    manager = [[VLCCloudSortingSpecifierManager alloc] initWithController: self];
    sheet.dataSource = manager;
    sheet.delegate = manager;
    sheet.modalPresentationStyle = UIModalPresentationCustom;
    [sheet.collectionView registerClass:[VLCActionSheetCell class] forCellWithReuseIdentifier:VLCActionSheetCell.identifier];

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
    self.navigationController.toolbar.barStyle = PresentationTheme.current.colors.toolBarStyle;
    _progressView.progressLabel.textColor = PresentationTheme.current.colors.cellTextColor;
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

    NSUInteger count = self.controller.currentListFiles.count;
    if (count == 0)
        self.numberOfFilesBarButtonItem.title = NSLocalizedString(@"NO_FILES", nil);
    else if (count != 1)
        self.numberOfFilesBarButtonItem.title = [NSString stringWithFormat:NSLocalizedString(@"NUM_OF_FILES", nil), count];
    else
        self.numberOfFilesBarButtonItem.title = NSLocalizedString(@"ONE_FILE", nil);
}

- (NSArray*)_generateToolbarItemsWithSortButton : (BOOL)withsb
{
    NSMutableArray* result = [NSMutableArray array];
    if (withsb)
    {
        [result addObjectsFromArray:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], _sortBarButtonItem]];
    }
    [result addObjectsFromArray:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], _numberOfFilesBarButtonItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]]];
    return result;
}

- (void)_showProgressInToolbar:(BOOL)value
{
    if (!value) {
        [self setToolbarItems:[self _generateToolbarItemsWithSortButton:[self.controller supportSorting]] animated:YES];
        
    }
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
    cloudcell.backgroundColor = PresentationTheme.current.colors.cellBackgroundA;
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
    BOOL hasProgressbar = NO;
    for (id item in self.toolbarItems) {
        if (item == _progressBarButtonItem) {
            hasProgressbar = YES;
        }
    }
    if (!hasProgressbar) {
        //Only show sorting button and number of files button when there is no progress bar in the toolbar
        //Only show sorting button when controller support sorting and is authorized
        [self setToolbarItems:[self _generateToolbarItemsWithSortButton:self.controller.isAuthorized && [self.controller supportSorting]] animated:YES];
       
    }
    if (self.controller.canPlayAll) {
        self.navigationItem.rightBarButtonItems = @[_logoutButton, [UIBarButtonItem themedPlayAllButtonWithTarget:self andSelector:@selector(playAllAction:)]];
    } else {
        self.navigationItem.rightBarButtonItem = _logoutButton;
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

    //reload if we didn't come back from streaming
    if (self.currentPath == nil) {
        self.currentPath = @"";
    }
    if ([self.controller.currentListFiles count] == 0)
        [self requestInformationForCurrentPath];
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
