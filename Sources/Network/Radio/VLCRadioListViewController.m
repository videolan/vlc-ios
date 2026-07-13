/*****************************************************************************
 * VLCRadioListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRadioListViewController.h"
#import "VLCServiceBrowserRadio.h"
#import "VLCNetworkListCell.h"
#import "VLCNetworkServerBrowserViewController.h"
#import "VLCPlaybackService.h"

#import "VLC-Swift.h"

@interface VLCRadioListViewController () <VLCLocalNetworkServiceBrowserDelegate>
{
    VLCServiceBrowserRadio *_serviceBrowser;
    NSArray<id<VLCLocalNetworkService>> *_searchResults;
}
@end

@implementation VLCRadioListViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _serviceBrowser = [[VLCServiceBrowserRadio alloc] init];
        _serviceBrowser.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"RADIO", nil);
    [self removePlayAllAction];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self startActivityIndicator];
    [_serviceBrowser startDiscovery];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [_serviceBrowser stopDiscovery];
}

#pragma mark - service access

- (BOOL)isSearching
{
    return self.searchController.isActive && self.searchController.searchBar.text.length > 0;
}

- (id<VLCLocalNetworkService>)serviceForIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.row;

    if ([self isSearching]) {
        return row < _searchResults.count ? _searchResults[row] : nil;
    }

    return [_serviceBrowser networkServiceForIndex:row];
}

- (VLCMedia *)mediaForService:(id<VLCLocalNetworkService>)service
{
    if (![service isKindOfClass:[VLCLocalNetworkServiceVLCMedia class]])
        return nil;

    return [(VLCLocalNetworkServiceVLCMedia *)service mediaItem];
}

#pragma mark - table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self isSearching]) {
        return _searchResults.count;
    }

    return _serviceBrowser.numberOfItems;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCNetworkListCell *cell = (VLCNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:VLCNetworkListCellIdentifier];
    if (cell == nil)
        cell = [VLCNetworkListCell cellWithReuseIdentifier:VLCNetworkListCellIdentifier];

    id<VLCLocalNetworkService> service = [self serviceForIndexPath:indexPath];
    VLCMedia *media = [self mediaForService:service];

    [cell setIsDirectory:media.mediaType == VLCMediaTypeDirectory];
    [cell setIconURL:service.iconURL];
    if (cell.iconURL == nil)
        [cell setIcon:service.icon];
    [cell setTitle:service.title];
    [cell setTitleLabelCentered:YES];

    return cell;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(VLCNetworkListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];

    ColorPalette *themeColors = PresentationTheme.current.colors;
    cell.titleLabel.textColor = cell.folderTitleLabel.textColor = cell.thumbnailView.tintColor = themeColors.cellTextColor;
    cell.subtitleLabel.textColor = themeColors.cellDetailTextColor;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    id<VLCLocalNetworkService> service = [self serviceForIndexPath:indexPath];
    id<VLCNetworkServerBrowser> serverBrowser = [service serverBrowser];
    if (!serverBrowser) {
        VLCMedia *media = [self mediaForService:service];
        if (media) {
            VLCMediaList *mediaList = [[VLCMediaList alloc] init];
            [mediaList addMedia:media];
            [[VLCPlaybackService sharedInstance] playMediaList:mediaList firstIndex:0 subtitlesFilePath:nil];
        }
        return;
    }

    VLCNetworkServerBrowserViewController *targetViewController =
        [[VLCNetworkServerBrowserViewController alloc] initWithServerBrowser:serverBrowser
                                                         medialibraryService:[[VLCAppCoordinator sharedInstance] mediaLibraryService]];
    [self.navigationController pushViewController:targetViewController animated:YES];
}

#pragma mark - search

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = searchController.searchBar.text;
    NSUInteger count = _serviceBrowser.numberOfItems;
    NSMutableArray<id<VLCLocalNetworkService>> *results = [NSMutableArray arrayWithCapacity:count];

    for (NSUInteger i = 0; i < count; i++) {
        id<VLCLocalNetworkService> service = [_serviceBrowser networkServiceForIndex:i];
        if ([service.title rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [results addObject:service];
        }
    }

    _searchResults = results;
    [self.tableView reloadData];
}

#pragma mark - VLCLocalNetworkServiceBrowserDelegate

- (void)localNetworkServiceBrowserDidUpdateServices:(id<VLCLocalNetworkServiceBrowser>)serviceBrowser
{
    [self stopActivityIndicator];

    if ([self isSearching]) {
        [self updateSearchResultsForSearchController:self.searchController];
        return;
    }

    [self.tableView reloadData];
}

@end
