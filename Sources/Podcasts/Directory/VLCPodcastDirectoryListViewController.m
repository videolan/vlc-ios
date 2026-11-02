/*****************************************************************************
 * VLCPodcastDirectoryListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Author: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPodcastDirectoryListViewController.h"
#import "VLCPodcastIndexService.h"
#import "VLCNetworkListCell.h"
#import "VLCAppCoordinator.h"

#import "VLC-Swift.h"

static NSString *const VLCPodcastDirectoryListCellIdentifier = @"LocalNetworkCell";

@interface VLCPodcastDirectoryListViewController () <VLCMediaLibraryBaseModelObserver>
@end

@implementation VLCPodcastDirectoryListViewController
{
    VLCPodcastIndexService *_service;
    PodcastStore *_store;
    VLCPodcastIndexShelf *_shelf;
    NSArray<VLCPodcastIndexFeed *> *_feeds;
}

- (instancetype)initWithService:(VLCPodcastIndexService *)service
                          shelf:(VLCPodcastIndexShelf *)shelf
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _service = service;
        _store = [VLCAppCoordinator sharedInstance].podcastStore;
        _shelf = shelf;
        _feeds = shelf.feeds;
    }
    return self;
}

- (void)dealloc
{
    [_store removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    [self removePlayAllAction];
    [self stopActivityIndicator];

    [self.tableView registerNib:[UINib nibWithNibName:@"VLCNetworkListCell" bundle:nil]
         forCellReuseIdentifier:VLCPodcastDirectoryListCellIdentifier];

    self.title = _shelf.title;
    self.navigationItem.searchController = nil;
    [self loadCategory];

    [_store addObserver:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeDidChange)
                                                 name:kVLCThemeDidChangeNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.prefersLargeTitles = NO;
    [self.tableView reloadData];
}

- (void)themeDidChange
{
    self.tableView.backgroundColor = PresentationTheme.current.colors.background;
}

#pragma mark - loading

- (void)loadCategory
{
    NSString *category = _shelf.category;
    if (!category) {
        return;
    }

    [self beginLoading];
    [_service loadTrendingForCategory:category completion:^(NSArray<VLCPodcastIndexFeed *> *feeds, NSError *error) {
        [self endLoadingWithFeeds:feeds error:error];
    }];
}

- (void)beginLoading
{
    if (_feeds.count > 0) {
        return;
    }

    self.tableView.backgroundView = nil;
    [self startActivityIndicator];
}

- (void)endLoadingWithFeeds:(NSArray<VLCPodcastIndexFeed *> *)feeds error:(NSError *)error
{
    [self stopActivityIndicator];

    if (!error) {
        _feeds = feeds;
    }

    [self updateBackgroundViewForError:error];
    [self.tableView reloadData];
}

- (void)updateBackgroundViewForError:(NSError *)error
{
    if (_feeds.count > 0) {
        self.tableView.backgroundView = nil;
        return;
    }

    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:16.];
    label.textColor = PresentationTheme.current.colors.cellDetailTextColor;
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;

    label.text = error ? NSLocalizedString(@"PODCAST_DIRECTORY_ERROR", nil)
                       : NSLocalizedString(@"PODCAST_DIRECTORY_NO_RESULTS", nil);

    self.tableView.backgroundView = label;
}

#pragma mark - table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _feeds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCNetworkListCell *cell = [tableView dequeueReusableCellWithIdentifier:VLCPodcastDirectoryListCellIdentifier
                                                               forIndexPath:indexPath];

    VLCPodcastIndexFeed *feed = _feeds[indexPath.row];
    [cell configureWithPodcastFeed:feed subscriptionState:[_store subscriptionStateForFeedURL:feed.feedURL]];

    return cell;
}

#pragma mark - table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return VLCNetworkListCell.podcastFeedHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    PodcastDirectoryFeedViewController *feedViewController =
        [[PodcastDirectoryFeedViewController alloc] initWithFeed:_feeds[indexPath.row]
                                                         service:_service];
    [self.navigationController pushViewController:feedViewController animated:YES];
}

#pragma mark - store observer

- (void)mediaLibraryBaseModelReloadView
{
    for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
        VLCNetworkListCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        VLCPodcastIndexFeed *feed = _feeds[indexPath.row];
        [cell applyPodcastSubscriptionState:[_store subscriptionStateForFeedURL:feed.feedURL]];
    }
}

@end
