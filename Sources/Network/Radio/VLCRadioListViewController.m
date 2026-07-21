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
#import "VLCRadioFavoritesGridCell.h"
#import "VLCRadioFavoritesListViewController.h"
#import "VLCRadioStationsViewController.h"
#import "VLCFavoriteService.h"
#import "VLCAppCoordinator.h"
#import "VLCNetworkListCell.h"
#import "VLCPlaybackService.h"

#import "VLC-Swift.h"

@interface VLCRadioListViewController () <VLCRadioFavoritesGridCellDelegate>
{
    VLCRadioCountryService *_countryService;
    NSArray<VLCFavorite *> *_radioFavorites;
}
@end

@implementation VLCRadioListViewController

- (UITableViewStyle)tableViewStyle
{
    return UITableViewStyleGrouped;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"RADIO", nil);
    [self removePlayAllAction];
    self.navigationItem.searchController = nil;

    self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0.0;
    }

    [self.tableView registerClass:[VLCRadioFavoritesGridCell class]
           forCellReuseIdentifier:VLCRadioFavoritesGridCell.reuseIdentifier];

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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    // the favorites grid height depends on the available width
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadData];
    }];
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

- (NSInteger)visibleFavoriteCap
{
    return [VLCRadioFavoritesGridCell visibleFavoriteCapForWidth:self.tableView.bounds.size.width];
}

- (NSArray<VLCFavorite *> *)visibleFavorites
{
    NSInteger cap = [self visibleFavoriteCap];
    if (_radioFavorites.count <= cap)
        return _radioFavorites;
    return [_radioFavorites subarrayWithRange:NSMakeRange(0, cap)];
}

- (BOOL)hasMoreFavorites
{
    return _radioFavorites.count > [self visibleFavoriteCap];
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
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != self.countriesSection) {
        VLCRadioFavoritesGridCell *gridCell =
            [tableView dequeueReusableCellWithIdentifier:VLCRadioFavoritesGridCell.reuseIdentifier forIndexPath:indexPath];
        gridCell.delegate = self;
        [gridCell configureWithFavorites:[self visibleFavorites]];
        return gridCell;
    }

    VLCNetworkListCell *cell = (VLCNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:VLCNetworkListCellIdentifier];
    if (cell == nil)
        cell = [VLCNetworkListCell cellWithReuseIdentifier:VLCNetworkListCellIdentifier];

    [self configureCountryCell:cell atRow:indexPath.row];
    return cell;
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
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

#pragma mark - table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != self.countriesSection) {
        return [VLCRadioFavoritesGridCell heightForFavoriteCount:[self visibleFavorites].count
                                                           width:tableView.bounds.size.width];
    }
    return [VLCNetworkListCell heightOfCell];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:(VLCNetworkListCell *)cell forRowAtIndexPath:indexPath];

    if (indexPath.section != self.countriesSection)
        return;

    VLCNetworkListCell *listCell = (VLCNetworkListCell *)cell;
    ColorPalette *themeColors = PresentationTheme.current.colors;
    listCell.folderTitleLabel.textColor = listCell.titleLabel.textColor = themeColors.cellTextColor;
    listCell.thumbnailView.tintColor = themeColors.cellTextColor;
    listCell.subtitleLabel.textColor = themeColors.cellDetailTextColor;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    BOOL isCountries = (section == self.countriesSection);
    NSString *title = isCountries ? NSLocalizedString(@"COUNTRIES", nil)
                                  : NSLocalizedString(@"FAVORITES", nil);
    BOOL showsSeeAll = !isCountries && [self hasMoreFavorites];
    return [self sectionHeaderViewWithTitle:title showsSeeAll:showsSeeAll];
}

- (UIView *)sectionHeaderViewWithTitle:(NSString *)title showsSeeAll:(BOOL)showsSeeAll
{
    ColorPalette *themeColors = PresentationTheme.current.colors;

    UIView *header = [[UIView alloc] init];
    header.backgroundColor = [UIColor clearColor];

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightSemibold];
    label.textColor = themeColors.cellTextColor;
    label.text = title;
    [header addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:header.safeAreaLayoutGuide.leadingAnchor constant:20.0],
        [label.centerYAnchor constraintEqualToAnchor:header.centerYAnchor]
    ]];

    if (showsSeeAll) {
        UIButton *seeAllButton = [UIButton buttonWithType:UIButtonTypeSystem];
        seeAllButton.translatesAutoresizingMaskIntoConstraints = NO;
        seeAllButton.tintColor = themeColors.orangeUI;
        seeAllButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
        [seeAllButton setTitle:NSLocalizedString(@"SEE_ALL", nil) forState:UIControlStateNormal];
        [seeAllButton addTarget:self action:@selector(showAllFavorites) forControlEvents:UIControlEventTouchUpInside];
        [header addSubview:seeAllButton];

        [NSLayoutConstraint activateConstraints:@[
            [seeAllButton.trailingAnchor constraintEqualToAnchor:header.safeAreaLayoutGuide.trailingAnchor constant:-20.0],
            [seeAllButton.centerYAnchor constraintEqualToAnchor:label.centerYAnchor]
        ]];
    }

    return header;
}

- (void)showAllFavorites
{
    VLCRadioFavoritesListViewController *targetViewController = [[VLCRadioFavoritesListViewController alloc] init];
    [self.navigationController pushViewController:targetViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == self.countriesSection) {
        [self didSelectCountryAtRow:indexPath.row];
    }
}

#pragma mark - favorites grid delegate

- (void)favoritesGridCell:(VLCRadioFavoritesGridCell *)cell didSelectFavoriteAtIndex:(NSInteger)index
{
    if (index >= _radioFavorites.count)
        return;

    VLCFavorite *favorite = _radioFavorites[index];
    VLCMedia *media = [VLCMedia mediaWithURL:favorite.url];
    if (!media)
        return;

    media.metaData.title = favorite.userVisibleName;
    if (favorite.artworkURL) {
        media.metaData.artworkURL = favorite.artworkURL;
    }

    VLCMediaList *mediaList = [[VLCMediaList alloc] init];
    [mediaList addMedia:media];
    [[VLCPlaybackService sharedInstance] playMediaList:mediaList firstIndex:0 subtitlesFilePath:nil];

    VLCFavoriteService *favoriteService = [[VLCAppCoordinator sharedInstance] favoriteService];
    [favoriteService moveFavoriteToFront:favorite];
    _radioFavorites = [favoriteService favoritesInGroupWithIdentifier:VLCFavoriteGroupRadio];
    [self.tableView reloadData];
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

    VLCRadioStationsViewController *targetViewController =
        [[VLCRadioStationsViewController alloc] initWithServerBrowser:serverBrowser
                                                 medialibraryService:[[VLCAppCoordinator sharedInstance] mediaLibraryService]];
    [self.navigationController pushViewController:targetViewController animated:YES];
}

@end
