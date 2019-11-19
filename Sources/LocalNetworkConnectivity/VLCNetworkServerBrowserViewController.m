/*****************************************************************************
 * VLCNetworkServerBrowserViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerBrowserViewController.h"
#import "VLCNetworkListCell.h"
#import "VLCActivityManager.h"
#import "VLCStatusLabel.h"
#import "VLCPlaybackService.h"
#import "VLCDownloadViewController.h"

#import "VLCNetworkServerBrowser-Protocol.h"
#import "VLCServerBrowsingController.h"

#import "VLC-Swift.h"

@interface VLCNetworkServerBrowserViewController () <VLCNetworkServerBrowserDelegate,VLCNetworkListCellDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
    UIRefreshControl *_refreshControl;
}
@property (nonatomic) id<VLCNetworkServerBrowser> serverBrowser;
@property (nonatomic) VLCServerBrowsingController *browsingController;
@property (nonatomic) NSArray<id<VLCNetworkServerBrowserItem>> *searchArray;
@end

@implementation VLCNetworkServerBrowserViewController

- (instancetype)initWithServerBrowser:(id<VLCNetworkServerBrowser>)browser
{
    self = [super init];
    if (self) {
        _serverBrowser = browser;
        browser.delegate = self;
        _browsingController = [[VLCServerBrowsingController alloc] initWithViewController:self serverBrowser:browser];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.tintColor = PresentationTheme.current.colors.orangeUI;
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    if (@available(iOS 10, *)) {
        self.tableView.refreshControl = _refreshControl;
    } else {
        [self.tableView addSubview:_refreshControl];
    }

    self.tableView.backgroundColor = PresentationTheme.current.colors.background;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDidChange) name:kVLCThemeDidChangeNotification object:nil];

    self.title = self.serverBrowser.title;
    [self update];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateUI];
}

- (void)networkServerBrowserDidUpdate:(id<VLCNetworkServerBrowser>)networkBrowser
{
    [self updateUI];
    [[VLCActivityManager defaultManager] networkActivityStopped];
    [_refreshControl endRefreshing];
}

- (void)networkServerBrowserShouldPopView:(id<VLCNetworkServerBrowser>)networkBrowser
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)networkServerBrowserEndParsing:(id<VLCNetworkServerBrowser>)networkBrowser
{
    [self stopActivityIndicator];
}

- (void)networkServerBrowser:(id<VLCNetworkServerBrowser>)networkBrowser requestDidFailWithError:(NSError *)error
{
    [VLCAlertViewController alertViewManagerWithTitle:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_TITLE", nil)
                                         errorMessage:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_MESSAGE", nil)
                                       viewController:self];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return PresentationTheme.current.colors.statusBarStyle;
}

- (void)updateUI
{
    [self.tableView reloadData];
    self.title = self.serverBrowser.title;
}

- (void)update
{
    [self.serverBrowser update];
    [[VLCActivityManager defaultManager] networkActivityStarted];
}

-(void)handleRefresh
{
    [self update];
}

#pragma mark - server browser item specifics

- (void)didSelectItem:(id<VLCNetworkServerBrowserItem>)item index:(NSUInteger)index singlePlayback:(BOOL)singlePlayback
{
    if (item.isContainer) {
        VLCNetworkServerBrowserViewController *targetViewController = [[VLCNetworkServerBrowserViewController alloc] initWithServerBrowser:item.containerBrowser];
        [self.navigationController pushViewController:targetViewController animated:YES];
    } else {
        if (singlePlayback) {
            [self.browsingController streamFileForItem:item];
        } else {
            VLCMediaList *mediaList = self.serverBrowser.mediaList;
            [self.browsingController configureSubtitlesInMediaList:mediaList];
            [self.browsingController streamMediaList:mediaList startingAtIndex:index];
        }
    }
}

- (void)playAllAction:(id)sender
{
    NSArray *items = self.serverBrowser.items;

    NSMutableArray *fileList = [[NSMutableArray alloc] init];
    for (id<VLCNetworkServerBrowserItem> iter in items) {
        if (![iter isContainer]) {
            [fileList addObject:[iter media]];
        }
    }

    if (fileList.count > 0) {
        VLCMediaList *fileMediaList = [[VLCMediaList alloc] initWithArray:fileList];
        [self.browsingController configureSubtitlesInMediaList:fileMediaList];
        [self.browsingController streamMediaList:fileMediaList startingAtIndex:0];
    }
}

#pragma mark - table view data source, for more see super

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.searchController.isActive)
        return _searchArray.count;

    return self.serverBrowser.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCNetworkListCell *cell = (VLCNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:VLCNetworkListCellIdentifier];
    if (cell == nil)
        cell = [VLCNetworkListCell cellWithReuseIdentifier:VLCNetworkListCellIdentifier];


    id<VLCNetworkServerBrowserItem> item;
    if (self.searchController.isActive) {
        item = _searchArray[indexPath.row];
    } else {
        item = self.serverBrowser.items[indexPath.row];
    }

    [self.browsingController configureCell:cell withItem:item];

    cell.delegate = self;

    return cell;
}

#pragma mark - table view delegate, for more see super

- (void)tableView:(UITableView *)tableView willDisplayCell:(VLCNetworkListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];

    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row)
        [[VLCActivityManager defaultManager] networkActivityStopped];

    cell.titleLabel.textColor = cell.folderTitleLabel.textColor = cell.subtitleLabel.textColor = cell.thumbnailView.tintColor = PresentationTheme.current.colors.cellTextColor;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<VLCNetworkServerBrowserItem> item;
    NSInteger row = indexPath.row;
    BOOL singlePlayback = ![[NSUserDefaults standardUserDefaults] boolForKey:kVLCAutomaticallyPlayNextItem];
    if (self.searchController.isActive) {
        if (row < _searchArray.count) {
            item = _searchArray[row];
            singlePlayback = YES;
        }
    } else {
        NSArray *items = self.serverBrowser.items;
        if (row < items.count) {
            item = items[row];
        }
    }

    if (item) {
        [self didSelectItem:item index:row singlePlayback:singlePlayback];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - VLCNetworkListCell delegation

- (void)triggerDownloadForCell:(VLCNetworkListCell *)cell
{
    id<VLCNetworkServerBrowserItem> item;
    if (self.searchController.isActive)
        item = _searchArray[[self.tableView indexPathForCell:cell].row];
    else
        item = self.serverBrowser.items[[self.tableView indexPathForCell:cell].row];

    if ([self.browsingController triggerDownloadForItem:item]) {
        [cell.statusLabel showStatusMessage:NSLocalizedString(@"DOWNLOADING", nil)];
    }
}

#pragma mark - Search Research Updater

- (void)updateSearchResultsForSearchController:(UISearchController *)_searchController
{
    NSString *searchString = _searchController.searchBar.text;
    [self searchForText:searchString];
    [self.tableView reloadData];
}

- (void)searchForText:(NSString *)searchString
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains[c] %@",searchString];
    _searchArray = [self.serverBrowser.items filteredArrayUsingPredicate:predicate];
}

#pragma mark -

- (void)themeDidChange
{
    self.tableView.backgroundColor = PresentationTheme.current.colors.background;
    [self setNeedsStatusBarAppearanceUpdate];
}

@end
