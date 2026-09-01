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
#import "VLCRadioService.h"
#import "VLCRadioCountry.h"
#import "VLCRadioFavoritesGridCell.h"
#import "VLCRadioFavoriteMenu.h"
#import "VLCRadioStationsViewController.h"
#import "VLCFavoriteService.h"
#import "VLCAppCoordinator.h"
#import "VLCNetworkListCell.h"

#import "VLC-Swift.h"

@interface VLCRadioListViewController () <VLCRadioFavoritesGridCellDelegate>
{
    VLCRadioService *_radioService;
    NSArray<VLCFavorite *> *_radioFavorites;
    NSArray<VLCFavorite *> *_recentStreams;
    NSSet<NSURL *> *_favoritesWithAlarms;
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
    self.tableView.backgroundColor = PresentationTheme.current.colors.pageBackground;
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0.0;
    }

    [self.tableView registerClass:[VLCRadioFavoritesGridCell class]
           forCellReuseIdentifier:VLCRadioFavoritesGridCell.reuseIdentifier];

    _radioService = [[VLCAppCoordinator sharedInstance] radioService];
    _radioFavorites = @[];
    _recentStreams = @[];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(radioCountriesDidUpdate:)
                               name:VLCRadioCountriesDidUpdateNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(recentStreamsDidChange)
                               name:VLCRadioRecentStreamsDidChangeNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(themeDidChange)
                               name:kVLCThemeDidChangeNotification
                             object:nil];
}

- (void)themeDidChange
{
    self.tableView.backgroundColor = PresentationTheme.current.colors.pageBackground;
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;

    _recentStreams = _radioService.recentStreams;
    [self reloadFavorites];

    [_radioService startCountryDiscoveryIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    self.navigationController.navigationBar.prefersLargeTitles = NO;

    [_radioService stopCountryDiscovery];
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

- (void)recentStreamsDidChange
{
    _recentStreams = _radioService.recentStreams;
    [self.tableView reloadData];
}

- (void)reloadFavorites
{
    _radioFavorites = [[[VLCAppCoordinator sharedInstance] favoriteService] favoritesInGroupWithIdentifier:VLCFavoriteGroupRadio];
    [self reloadAlarmState];
    [self.tableView reloadData];
}

- (void)reloadAlarmState
{
    [VLCRadioAlarmService.shared urlsWithAlarmsForFavorites:_radioFavorites
                                                completion:^(NSSet<NSURL *> *urls) {
        if (urls.count == 0 && self->_favoritesWithAlarms.count == 0)
            return;

        self->_favoritesWithAlarms = urls;
        [self.tableView reloadData];
    }];
}

#pragma mark - section layout

- (BOOL)favoritesSectionVisible
{
    return _radioFavorites.count > 0;
}

- (BOOL)recentsSectionVisible
{
    return _recentStreams.count > 0;
}

- (NSInteger)recentsSection
{
    return self.recentsSectionVisible ? (self.favoritesSectionVisible ? 1 : 0) : NSNotFound;
}

- (NSInteger)countriesSection
{
    return (self.favoritesSectionVisible ? 1 : 0) + (self.recentsSectionVisible ? 1 : 0);
}

- (NSArray<VLCFavorite *> *)streamsInSection:(NSInteger)section
{
    return section == self.recentsSection ? _recentStreams : _radioFavorites;
}

- (BOOL)gridCellShowsRecents:(VLCRadioFavoritesGridCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    return indexPath != nil && indexPath.section == self.recentsSection;
}

- (NSArray<VLCFavorite *> *)streamsForGridCell:(VLCRadioFavoritesGridCell *)cell
{
    return [self gridCellShowsRecents:cell] ? _recentStreams : _radioFavorites;
}

#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.countriesSection + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == self.countriesSection) {
        return _radioService.visitedCountries.count + 1;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != self.countriesSection) {
        BOOL isRecents = indexPath.section == self.recentsSection;
        VLCRadioFavoritesGridCell *gridCell =
            [tableView dequeueReusableCellWithIdentifier:VLCRadioFavoritesGridCell.reuseIdentifier forIndexPath:indexPath];
        gridCell.delegate = self;
        gridCell.removalActionTitle = isRecents ? NSLocalizedString(@"REMOVE_FROM_RECENT_STREAMS", nil) : nil;
        gridCell.removalActionGlyphName = isRecents ? @"xmark.circle" : nil;
        [gridCell configureWithFavorites:[self streamsInSection:indexPath.section]];
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

    NSArray<VLCRadioCountry *> *visited = _radioService.visitedCountries;
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
        return [VLCRadioFavoritesGridCell heightForFavoriteCount:[self streamsInSection:indexPath.section].count
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
    NSString *title;
    if (section == self.countriesSection) {
        title = NSLocalizedString(@"COUNTRIES", nil);
    } else if (section == self.recentsSection) {
        title = NSLocalizedString(@"RECENT_STREAMS", nil);
    } else {
        title = NSLocalizedString(@"FAVORITES", nil);
    }
    return [self sectionHeaderViewWithTitle:title];
}

- (UIView *)sectionHeaderViewWithTitle:(NSString *)title
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

    return header;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == self.countriesSection) {
        [self didSelectCountryAtRow:indexPath.row];
    }
}

#pragma mark - favorites grid delegate

- (NSArray<UIMenuElement *> *)favoritesGridCell:(VLCRadioFavoritesGridCell *)cell menuElementsForFavoriteAtIndex:(NSInteger)index
{
    if ([self gridCellShowsRecents:cell] || index >= _radioFavorites.count)
        return nil;

    __weak typeof(self) weakSelf = self;
    return [VLCRadioFavoriteMenu alarmActionsForFavorite:_radioFavorites[index]
                                presentingViewController:self
                                               didChange:^{
        [weakSelf reloadFavorites];
    }];
}

- (BOOL)favoritesGridCell:(VLCRadioFavoritesGridCell *)cell hasAlarmForFavoriteAtIndex:(NSInteger)index
{
    if ([self gridCellShowsRecents:cell] || index >= _radioFavorites.count)
        return NO;

    return [_favoritesWithAlarms containsObject:_radioFavorites[index].url];
}

- (void)favoritesGridCell:(VLCRadioFavoritesGridCell *)cell didSelectFavoriteAtIndex:(NSInteger)index
{
    NSArray<VLCFavorite *> *streams = [self streamsForGridCell:cell];
    if (index >= streams.count)
        return;

    VLCFavorite *stream = streams[index];
    VLCFavoriteService *favoriteService = [[VLCAppCoordinator sharedInstance] favoriteService];
    [favoriteService playFavorite:stream];
    [_radioService markStreamPlayed:stream];

    _radioFavorites = [favoriteService favoritesInGroupWithIdentifier:VLCFavoriteGroupRadio];
    [self.tableView reloadData];
}

- (void)favoritesGridCell:(VLCRadioFavoritesGridCell *)cell didRequestRemovalOfFavoriteAtIndex:(NSInteger)index
{
    NSArray<VLCFavorite *> *streams = [self streamsForGridCell:cell];
    if (index >= streams.count)
        return;

    if ([self gridCellShowsRecents:cell]) {
        [_radioService removeRecentStream:streams[index]];
        return;
    }

    VLCFavoriteService *favoriteService = [[VLCAppCoordinator sharedInstance] favoriteService];
    [favoriteService removeFavorite:streams[index]];
    _radioFavorites = [favoriteService favoritesInGroupWithIdentifier:VLCFavoriteGroupRadio];
    [self.tableView reloadData];
}

- (void)didSelectCountryAtRow:(NSInteger)row
{
    NSArray<VLCRadioCountry *> *visited = _radioService.visitedCountries;
    if (row >= visited.count) {
        VLCRadioCountryListViewController *targetViewController = [[VLCRadioCountryListViewController alloc] init];
        [self.navigationController pushViewController:targetViewController animated:YES];
        return;
    }

    VLCRadioCountry *country = visited[row];
    [_radioService markCountryVisited:country];

    id<VLCNetworkServerBrowser> serverBrowser = [country makeServerBrowser];
    if (!serverBrowser)
        return;

    VLCRadioStationsViewController *targetViewController =
        [[VLCRadioStationsViewController alloc] initWithServerBrowser:serverBrowser
                                                 medialibraryService:[[VLCAppCoordinator sharedInstance] mediaLibraryService]];
    [self.navigationController pushViewController:targetViewController animated:YES];
}

@end
