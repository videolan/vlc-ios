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
#import "VLCRadioCountryListViewController.h"
#import "VLCRadioCountryService.h"
#import "VLCRadioCountry.h"
#import "VLCFavoriteService.h"
#import "VLCAppCoordinator.h"
#import "VLCNetworkListCell.h"
#import "VLCNetworkServerBrowserViewController.h"
#import "VLCPlaybackService.h"

#import "VLC-Swift.h"

@interface VLCRadioListViewController ()
{
    VLCRadioCountryService *_countryService;
    NSArray<VLCFavorite *> *_radioFavorites;
}
@end

@implementation VLCRadioListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"RADIO", nil);
    [self removePlayAllAction];
    self.navigationItem.searchController = nil;

    _countryService = [[VLCAppCoordinator sharedInstance] radioCountryService];
    _radioFavorites = @[];

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

    _radioFavorites = [[[VLCAppCoordinator sharedInstance] favoriteService] favoritesInGroupWithIdentifier:VLCFavoriteGroupRadio];
    [self.tableView reloadData];

    [_countryService startCountryDiscoveryIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    self.navigationController.navigationBar.prefersLargeTitles = NO;

    [_countryService stopCountryDiscovery];
}

- (void)radioCountriesDidUpdate:(NSNotification *)notification
{
    [self.tableView reloadData];
}

#pragma mark - section layout

- (BOOL)favoritesSectionVisible
{
    return _radioFavorites.count > 0;
}

- (NSInteger)countriesSection
{
    return self.favoritesSectionVisible ? 1 : 0;
}

#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.favoritesSectionVisible ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == self.countriesSection) {
        return _countryService.visitedCountries.count + 1;
    }
    return _radioFavorites.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCNetworkListCell *cell = (VLCNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:VLCNetworkListCellIdentifier];
    if (cell == nil)
        cell = [VLCNetworkListCell cellWithReuseIdentifier:VLCNetworkListCellIdentifier];

    if (indexPath.section == self.countriesSection) {
        [self configureCountryCell:cell atRow:indexPath.row];
    } else {
        [self configureFavoriteCell:cell atRow:indexPath.row];
    }

    return cell;
}

- (void)configureFavoriteCell:(VLCNetworkListCell *)cell atRow:(NSInteger)row
{
    VLCFavorite *favorite = _radioFavorites[row];

    [cell setIsDirectory:NO];
    [cell setTitleLabelCentered:favorite.mediaDescription.length == 0];
    [cell setTitle:favorite.userVisibleName];
    [cell setSubtitle:favorite.mediaDescription];
    if (favorite.artworkURL) {
        [cell setIconURL:favorite.artworkURL];
    } else if (@available(iOS 13.0, *)) {
        [cell setIcon:[UIImage systemImageNamed:@"antenna.radiowaves.left.and.right"]];
    }
}

- (void)configureCountryCell:(VLCNetworkListCell *)cell atRow:(NSInteger)row
{
    [cell setIsDirectory:YES];

    NSArray<VLCRadioCountry *> *visited = _countryService.visitedCountries;
    if (row < visited.count) {
        VLCRadioCountry *country = visited[row];
        [cell setTitle:country.localizedName];
        [cell setIcon:country.flagImage];
    } else {
        [cell setTitle:NSLocalizedString(@"ALL_COUNTRIES", nil)];
        if (@available(iOS 14.2, *)) {
            [cell setIcon:[UIImage systemImageNamed:@"globe.europe.africa"]];
        } else if (@available(iOS 13.0, *)) {
            [cell setIcon:[UIImage systemImageNamed:@"globe"]];
        }
    }
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(VLCNetworkListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];

    ColorPalette *themeColors = PresentationTheme.current.colors;
    cell.titleLabel.textColor = cell.folderTitleLabel.textColor = cell.thumbnailView.tintColor = themeColors.cellTextColor;
    cell.subtitleLabel.textColor = themeColors.cellDetailTextColor;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = (section == self.countriesSection) ? NSLocalizedString(@"COUNTRIES", nil)
                                                         : NSLocalizedString(@"FAVORITES", nil);
    return [self sectionHeaderViewWithTitle:title];
}

- (UIView *)sectionHeaderViewWithTitle:(NSString *)title
{
    ColorPalette *themeColors = PresentationTheme.current.colors;

    UIView *header = [[UIView alloc] init];
    header.backgroundColor = themeColors.background;

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    label.textColor = themeColors.cellTextColor;
    label.text = title;
    [header addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:header.safeAreaLayoutGuide.leadingAnchor constant:20.0],
        [label.centerYAnchor constraintEqualToAnchor:header.centerYAnchor]
    ]];

    return header;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == self.countriesSection) {
        [self didSelectCountryAtRow:indexPath.row];
    } else {
        [self playFavoriteAtRow:indexPath.row];
    }
}

- (void)playFavoriteAtRow:(NSInteger)row
{
    VLCFavorite *favorite = _radioFavorites[row];
    VLCMedia *media = [VLCMedia mediaWithURL:favorite.url];
    if (!media)
        return;

    VLCMediaList *mediaList = [[VLCMediaList alloc] init];
    [mediaList addMedia:media];
    [[VLCPlaybackService sharedInstance] playMediaList:mediaList firstIndex:0 subtitlesFilePath:nil];
}

- (void)didSelectCountryAtRow:(NSInteger)row
{
    NSArray<VLCRadioCountry *> *visited = _countryService.visitedCountries;
    if (row >= visited.count) {
        VLCRadioCountryListViewController *targetViewController = [[VLCRadioCountryListViewController alloc] init];
        [self.navigationController pushViewController:targetViewController animated:YES];
        return;
    }

    VLCRadioCountry *country = visited[row];
    [_countryService markCountryVisited:country];

    id<VLCNetworkServerBrowser> serverBrowser = [country makeServerBrowser];
    if (!serverBrowser)
        return;

    VLCNetworkServerBrowserViewController *targetViewController =
        [[VLCNetworkServerBrowserViewController alloc] initWithServerBrowser:serverBrowser
                                                         medialibraryService:[[VLCAppCoordinator sharedInstance] mediaLibraryService]];
    [self.navigationController pushViewController:targetViewController animated:YES];
}

@end
