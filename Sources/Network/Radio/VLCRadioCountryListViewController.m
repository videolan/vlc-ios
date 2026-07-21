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
#import "VLCRadioErrorView.h"
#import "VLCAppCoordinator.h"
#import "VLCNetworkListCell.h"
#import "VLCRadioStationsViewController.h"

#import "VLC-Swift.h"

@interface VLCRadioCountryListViewController ()
{
    VLCRadioCountryService *_countryService;
    NSArray<VLCRadioCountry *> *_searchResults;
    NSArray<NSString *> *_sectionTitles;
    NSArray<NSArray<VLCRadioCountry *> *> *_sectionedCountries;
    UIView *_errorView;
}
@end

@implementation VLCRadioCountryListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"ALL_COUNTRIES", nil);
    [self removePlayAllAction];

    self.tableView.sectionIndexColor = PresentationTheme.current.colors.orangeUI;

    _countryService = [[VLCAppCoordinator sharedInstance] radioCountryService];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(radioCountriesDidUpdate:)
                                                 name:VLCRadioCountriesDidUpdateNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;

    [_countryService startCountryDiscoveryIfNeeded];
    [self updateContentState];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    self.navigationController.navigationBar.prefersLargeTitles = NO;

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

    [self rebuildSections];
    [self.tableView reloadData];
}

- (void)rebuildSections
{
    NSArray<VLCRadioCountry *> *sorted = [_countryService.allCountries sortedArrayUsingComparator:^NSComparisonResult(VLCRadioCountry *a, VLCRadioCountry *b) {
        return [a.localizedName localizedCaseInsensitiveCompare:b.localizedName];
    }];

    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    NSMutableArray<NSMutableArray<VLCRadioCountry *> *> *sections = [NSMutableArray array];

    for (VLCRadioCountry *country in sorted) {
        NSString *initial = [self sectionTitleForName:country.localizedName];
        if (titles.count == 0 || ![titles.lastObject isEqualToString:initial]) {
            [titles addObject:initial];
            [sections addObject:[NSMutableArray array]];
        }
        [sections.lastObject addObject:country];
    }

    _sectionTitles = titles;
    _sectionedCountries = sections;
}

- (NSString *)sectionTitleForName:(NSString *)name
{
    if (name.length == 0)
        return @"#";

    NSString *initial = [[name substringToIndex:1] stringByFoldingWithOptions:NSDiacriticInsensitiveSearch
                                                                        locale:[NSLocale currentLocale]];
    initial = initial.uppercaseString;
    if (initial.length == 0)
        return @"#";

    unichar character = [initial characterAtIndex:0];
    if (character < 'A' || character > 'Z')
        return @"#";

    return [initial substringToIndex:1];
}

- (UIView *)errorView
{
    if (_errorView)
        return _errorView;

    _errorView = [[VLCRadioErrorView alloc] initWithMessage:NSLocalizedString(@"RADIO_COUNTRIES_LOADING_FAILED", nil)
                                                retryTarget:self
                                                retryAction:@selector(retryButtonTapped)];
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

- (VLCRadioCountry *)countryForIndexPath:(NSIndexPath *)indexPath
{
    if ([self isSearching]) {
        return indexPath.row < _searchResults.count ? _searchResults[indexPath.row] : nil;
    }

    if (indexPath.section >= _sectionedCountries.count)
        return nil;

    NSArray<VLCRadioCountry *> *countries = _sectionedCountries[indexPath.section];
    return indexPath.row < countries.count ? countries[indexPath.row] : nil;
}

#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self isSearching] ? 1 : _sectionTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self isSearching])
        return _searchResults.count;

    return section < _sectionedCountries.count ? _sectionedCountries[section].count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCNetworkListCell *cell = (VLCNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:VLCNetworkListCellIdentifier];
    if (cell == nil)
        cell = [VLCNetworkListCell cellWithReuseIdentifier:VLCNetworkListCellIdentifier];

    VLCRadioCountry *country = [self countryForIndexPath:indexPath];
    [cell setIsDirectory:YES];
    [cell setTitle:country.localizedName];
    [cell setIcon:country.flagImage];
    [cell setTitleLabelCentered:YES];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self isSearching])
        return nil;

    return section < _sectionTitles.count ? _sectionTitles[section] : nil;
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [self isSearching] ? nil : _sectionTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return index;
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

    VLCRadioCountry *country = [self countryForIndexPath:indexPath];
    if (!country)
        return;

    [_countryService markCountryVisited:country];

    id<VLCNetworkServerBrowser> serverBrowser = [country makeServerBrowser];
    if (!serverBrowser)
        return;

    VLCRadioStationsViewController *targetViewController =
        [[VLCRadioStationsViewController alloc] initWithServerBrowser:serverBrowser
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
