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
#import "VLCPlaceholderArtwork.h"

#import "VLC-Swift.h"

static NSString *const VLCPodcastDirectoryListCellIdentifier = @"LocalNetworkCell";
static const CGFloat VLCPodcastDirectoryListArtworkSize = 72.;
static const CGFloat VLCPodcastDirectoryListArtworkRadius = 9.;
static const CGFloat VLCPodcastDirectoryListArtworkFontSize = 20.;
static const CGFloat VLCPodcastDirectoryListVerticalPadding = 8.;

@interface VLCPodcastDirectoryListViewController () <VLCMediaLibraryBaseModelObserver>
@end

@implementation VLCPodcastDirectoryListViewController
{
    VLCPodcastIndexService *_service;
    PodcastStore *_store;
    VLCPodcastIndexShelf *_shelf;
    NSArray<VLCPodcastIndexFeed *> *_feeds;
    NSURLSessionTask *_searchTask;
}

- (instancetype)initWithService:(VLCPodcastIndexService *)service
                          shelf:(VLCPodcastIndexShelf *)shelf
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _service = service;
        _store = PodcastStore.shared;
        _shelf = shelf;
        _feeds = shelf ? shelf.feeds : @[];
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

    if (_shelf) {
        self.title = _shelf.title;
        self.navigationItem.searchController = nil;
        [self loadCategory];
    } else {
        self.title = NSLocalizedString(@"SEARCH", nil);
        self.searchController.searchBar.placeholder = NSLocalizedString(@"PODCAST_DIRECTORY_SEARCH_PLACEHOLDER", nil);
        self.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }

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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (!_shelf && !self.searchController.isActive) {
        self.searchController.active = YES;
        [self.searchController.searchBar becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (self.isMovingFromParentViewController) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performSearch) object:nil];
        [_searchTask cancel];
    }
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

- (void)performSearch
{
    [_searchTask cancel];
    _searchTask = nil;

    NSString *query = [self.searchController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (query.length == 0) {
        _feeds = @[];
        [self stopActivityIndicator];
        self.tableView.backgroundView = nil;
        [self.tableView reloadData];
        return;
    }

    [self beginLoading];
    _searchTask = [_service searchFeedsMatching:query completion:^(NSArray<VLCPodcastIndexFeed *> *feeds, NSError *error) {
        if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
            return;
        }
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
    cell.title = feed.title;
    cell.subtitle = feed.subtitle;
    cell.icon = [VLCPlaceholderArtwork placeholderImageForName:feed.title
                                                          size:CGSizeMake(VLCPodcastDirectoryListArtworkSize, VLCPodcastDirectoryListArtworkSize)
                                                  cornerRadius:VLCPodcastDirectoryListArtworkRadius
                                                      fontSize:VLCPodcastDirectoryListArtworkFontSize];
    cell.iconURL = feed.artworkURL;
    cell.thumbnailWidthConstraint.constant = VLCPodcastDirectoryListArtworkSize;
    cell.thumbnailHeightConstraint.constant = VLCPodcastDirectoryListArtworkSize;
    cell.thumbnailView.layer.cornerRadius = VLCPodcastDirectoryListArtworkRadius;
    cell.isDownloadable = NO;
    cell.isFavorable = NO;
    [self applyState:[_store subscriptionStateForFeedURL:feed.feedURL title:feed.title] toCell:cell];

    return cell;
}

- (void)applyState:(PodcastSubscriptionState)state toCell:(VLCNetworkListCell *)cell
{
    switch (state) {
        case PodcastSubscriptionStateAvailable:
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        case PodcastSubscriptionStatePending: {
            VLCPulsingConeView *coneView = [[VLCPulsingConeView alloc] initWithConeSize:22.];
            [coneView startAnimating];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = coneView;
            break;
        }
        case PodcastSubscriptionStateSubscribed:
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.tintColor = PresentationTheme.current.colors.orangeUI;
            break;
    }
}

#pragma mark - table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return VLCPodcastDirectoryListArtworkSize + 2. * VLCPodcastDirectoryListVerticalPadding;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    PodcastDirectoryFeedViewController *feedViewController =
        [[PodcastDirectoryFeedViewController alloc] initWithFeed:_feeds[indexPath.row]
                                                         service:_service];
    [self.navigationController pushViewController:feedViewController animated:YES];
}

#pragma mark - search

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performSearch) object:nil];
    [self performSelector:@selector(performSearch) withObject:nil afterDelay:0.5];
}

#pragma mark - store observer

- (void)mediaLibraryBaseModelReloadView
{
    for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
        VLCNetworkListCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        VLCPodcastIndexFeed *feed = _feeds[indexPath.row];
        [self applyState:[_store subscriptionStateForFeedURL:feed.feedURL title:feed.title] toCell:cell];
    }
}

@end
