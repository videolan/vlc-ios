/*****************************************************************************
 * VLCRadioCountryListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCRadioCountryListViewController.h"
#import "VLCRadioCountryService.h"
#import "VLCRadioCountry.h"
#import "VLCAppCoordinator.h"
#import "VLCNetworkListCell.h"
#import "VLCNetworkServerBrowserViewController.h"

#import "VLC-Swift.h"

@interface VLCRadioCountryListViewController ()
{
    VLCRadioCountryService *_countryService;
    NSArray<VLCRadioCountry *> *_searchResults;
    UIView *_errorView;
}
@end

@implementation VLCRadioCountryListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"ALL_COUNTRIES", nil);
    [self removePlayAllAction];

    _countryService = [[VLCAppCoordinator sharedInstance] radioCountryService];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(radioCountriesDidUpdate:)
                                                 name:VLCRadioCountriesDidUpdateNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [_countryService startCountryDiscoveryIfNeeded];
    [self updateContentState];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [_countryService stopCountryDiscovery];
}

- (void)radioCountriesDidUpdate:(NSNotification *)notification
{
    if ([self isSearching]) {
        [self updateSearchResultsForSearchController:self.searchController];
        return;
    }

    [self updateContentState];
}

- (void)updateContentState
{
    if (_countryService.allCountries.count > 0) {
        [self stopActivityIndicator];
        self.tableView.backgroundView = nil;
    } else if (_countryService.discoveryFailed) {
        [self stopActivityIndicator];
        self.tableView.backgroundView = self.errorView;
    } else {
        self.tableView.backgroundView = nil;
        [self startActivityIndicator];
    }

    [self.tableView reloadData];
}

- (UIView *)errorView
{
    if (_errorView)
        return _errorView;

    ColorPalette *themeColors = PresentationTheme.current.colors;

    UIView *container = [[UIView alloc] init];

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = themeColors.cellDetailTextColor;
    label.font = [UIFont systemFontOfSize:16.0];
    label.text = NSLocalizedString(@"RADIO_COUNTRIES_LOADING_FAILED", nil);
    [container addSubview:label];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.tintColor = themeColors.orangeUI;
    button.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    [button setTitle:NSLocalizedString(@"BUTTON_RETRY", nil) forState:UIControlStateNormal];
    [button addTarget:self action:@selector(retryButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:button];

    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:container.layoutMarginsGuide.leadingAnchor],
        [label.trailingAnchor constraintEqualToAnchor:container.layoutMarginsGuide.trailingAnchor],
        [label.centerYAnchor constraintEqualToAnchor:container.centerYAnchor],
        [button.topAnchor constraintEqualToAnchor:label.bottomAnchor constant:16.0],
        [button.centerXAnchor constraintEqualToAnchor:container.centerXAnchor]
    ]];

    _errorView = container;
    return _errorView;
}

- (void)retryButtonTapped
{
    [_countryService retryCountryDiscovery];
    [self updateContentState];
}

#pragma mark - country access

- (BOOL)isSearching
{
    return self.searchController.isActive && self.searchController.searchBar.text.length > 0;
}

- (VLCRadioCountry *)countryForRow:(NSInteger)row
{
    NSArray<VLCRadioCountry *> *countries = [self isSearching] ? _searchResults : _countryService.allCountries;
    return row < countries.count ? countries[row] : nil;
}

#pragma mark - table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self isSearching] ? _searchResults.count : _countryService.allCountries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCNetworkListCell *cell = (VLCNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:VLCNetworkListCellIdentifier];
    if (cell == nil)
        cell = [VLCNetworkListCell cellWithReuseIdentifier:VLCNetworkListCellIdentifier];

    VLCRadioCountry *country = [self countryForRow:indexPath.row];
    [cell setIsDirectory:YES];
    [cell setTitle:country.localizedName];
    [cell setIcon:country.flagImage];
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

    VLCRadioCountry *country = [self countryForRow:indexPath.row];
    if (!country)
        return;

    [_countryService markCountryVisited:country];

    id<VLCNetworkServerBrowser> serverBrowser = [country makeServerBrowser];
    if (!serverBrowser)
        return;

    VLCNetworkServerBrowserViewController *targetViewController =
        [[VLCNetworkServerBrowserViewController alloc] initWithServerBrowser:serverBrowser
                                                         medialibraryService:[[VLCAppCoordinator sharedInstance] mediaLibraryService]];
    [self.navigationController pushViewController:targetViewController animated:YES];
}

#pragma mark - search

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = searchController.searchBar.text;
    NSArray<VLCRadioCountry *> *countries = _countryService.allCountries;
    NSMutableArray<VLCRadioCountry *> *results = [NSMutableArray arrayWithCapacity:countries.count];

    for (VLCRadioCountry *country in countries) {
        if ([country.localizedName rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [results addObject:country];
        }
    }

    _searchResults = results;
    [self.tableView reloadData];
}

@end
