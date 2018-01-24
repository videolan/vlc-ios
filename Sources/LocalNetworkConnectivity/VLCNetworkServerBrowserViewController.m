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
#import "VLCPlaybackController.h"
#import "VLCDownloadViewController.h"


#import "VLCNetworkServerBrowser-Protocol.h"
#import "VLCServerBrowsingController.h"

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
    _refreshControl.backgroundColor = [UIColor VLCDarkBackgroundColor];
    _refreshControl.tintColor = [UIColor whiteColor];
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:_refreshControl];

    self.title = self.serverBrowser.title;
    [self update];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateUI];
}

- (void)networkServerBrowserDidUpdate:(id<VLCNetworkServerBrowser>)networkBrowser {
    [self updateUI];
    [[VLCActivityManager defaultManager] networkActivityStopped];
    [_refreshControl endRefreshing];
}

- (void)networkServerBrowser:(id<VLCNetworkServerBrowser>)networkBrowser requestDidFailWithError:(NSError *)error {

    [self vlc_showAlertWithTitle:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_TITLE", nil)
                         message:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_MESSAGE", nil)
                     buttonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)];
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
    //set the title while refreshing
    _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"LOCAL_SERVER_REFRESH",nil)];
    //set the date and time of refreshing
    NSDateFormatter *formattedDate = [[NSDateFormatter alloc]init];
    [formattedDate setDateFormat:@"MMM d, h:mm a"];
    NSString *lastupdated = [NSString stringWithFormat:NSLocalizedString(@"LOCAL_SERVER_LAST_UPDATE",nil),[formattedDate stringFromDate:[NSDate date]]];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastupdated attributes:attrsDictionary];
    //end the refreshing

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
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<VLCNetworkServerBrowserItem> item;
    NSInteger row = indexPath.row;
    BOOL singlePlayback = ![[NSUserDefaults standardUserDefaults] boolForKey:kVLCAutomaticallyPlayNextItem];
    if (self.searchController.isActive) {
        item = _searchArray[row];
        singlePlayback = YES;
    } else {
        item = self.serverBrowser.items[row];
    }

    [self didSelectItem:item index:row singlePlayback:singlePlayback];

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

@end
