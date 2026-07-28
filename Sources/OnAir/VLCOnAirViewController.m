/*****************************************************************************
 * VLCOnAirViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOnAirViewController.h"
#import "VLCOnAirContinueCell.h"
#import "VLCOnAirPromptCell.h"
#import "VLCOnAirRailCell.h"
#import "VLCAppCoordinator.h"
#import "VLCFavoriteService.h"
#import "VLCPlaybackService.h"
#import "VLCPlayerDisplayController.h"
#import "VLCRadioListViewController.h"

#import "VLC-Swift.h"

typedef NS_ENUM(NSInteger, VLCOnAirSection) {
    VLCOnAirSectionContinue,
    VLCOnAirSectionRadio,
    VLCOnAirSectionPodcasts,
    VLCOnAirSectionTV,
    VLCOnAirSectionCount
};

static CGFloat const kVLCOnAirSideMargin = 20.0;
static CGFloat const kVLCOnAirHeaderHeight = 44.0;

@interface VLCOnAirViewController () <UITableViewDataSource, UITableViewDelegate,
                                      VLCOnAirRailCellDelegate, VLCOnAirPromptCellDelegate,
                                      VLCOnAirContinueCellDelegate>
@end

@implementation VLCOnAirViewController
{
    UITableView *_tableView;
    NSArray<VLCFavorite *> *_radioFavorites;
    VLCFavorite *_resumeFavorite;
    BOOL _zeroState;
    BOOL _resumeSuppressed;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"ONAIR", nil);

        UIImage *tabImage;
        if (@available(iOS 13.0, *)) {
            tabImage = [UIImage systemImageNamed:@"dot.radiowaves.right"];
        } else {
            tabImage = [UIImage imageNamed:@"Network"];
        }
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"ONAIR", nil)
                                                        image:tabImage
                                                selectedImage:tabImage];
        self.tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.onAir;

        _radioFavorites = @[];
    }
    return self;
}

- (void)loadView
{
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.estimatedRowHeight = 96.0;
    _tableView.cellLayoutMarginsFollowReadableWidth = NO;
    if (@available(iOS 15.0, *)) {
        _tableView.sectionHeaderTopPadding = 0.0;
    }

    [_tableView registerClass:[VLCOnAirContinueCell class]
       forCellReuseIdentifier:VLCOnAirContinueCell.reuseIdentifier];
    [_tableView registerClass:[VLCOnAirRailCell class]
       forCellReuseIdentifier:VLCOnAirRailCell.reuseIdentifier];
    [_tableView registerClass:[VLCOnAirPromptCell class]
       forCellReuseIdentifier:VLCOnAirPromptCell.reuseIdentifier];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    _tableView.refreshControl = refreshControl;

    self.view = _tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIImage *settingsImage;
    if (@available(iOS 13.0, *)) {
        settingsImage = [UIImage systemImageNamed:@"gearshape"];
    } else {
        settingsImage = [UIImage imageNamed:@"Settings"];
    }
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:settingsImage
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(showSettings)];
    settingsButton.accessibilityLabel = NSLocalizedString(@"Settings", nil);
    settingsButton.accessibilityIdentifier = VLCAccessibilityIdentifier.settings;
    self.navigationItem.leftBarButtonItem = settingsButton;

    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                  target:self
                                                                                  action:@selector(showSearch)];
    searchButton.accessibilityLabel = NSLocalizedString(@"SEARCH", nil);
    self.navigationItem.rightBarButtonItem = searchButton;

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(updateTheme) name:kVLCThemeDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(favoritesDidChange) name:VLCFavoriteServiceContentDidChange object:nil];
    [notificationCenter addObserver:self selector:@selector(miniPlayerIsShown) name:VLCPlayerDisplayControllerDisplayMiniPlayer object:nil];
    [notificationCenter addObserver:self selector:@selector(miniPlayerIsHidden) name:VLCPlayerDisplayControllerHideMiniPlayer object:nil];
    [notificationCenter addObserver:self selector:@selector(playbackDidStart) name:VLCPlaybackServicePlaybackDidStart object:nil];
    [notificationCenter addObserver:self selector:@selector(playbackDidStart) name:VLCPlaybackServicePlaybackDidResume object:nil];
    [notificationCenter addObserver:self selector:@selector(playbackDidHalt) name:VLCPlaybackServicePlaybackDidPause object:nil];
    [notificationCenter addObserver:self selector:@selector(playbackDidHalt) name:VLCPlaybackServicePlaybackDidStop object:nil];
    [notificationCenter addObserver:self selector:@selector(playbackDidHalt) name:VLCPlaybackServicePlaybackDidFail object:nil];

    [self updateTheme];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;

    VLCPlaybackService.sharedInstance.playerDisplayController.isMiniPlayerVisible
    ? [self miniPlayerIsShown] : [self miniPlayerIsHidden];

    _resumeSuppressed = VLCPlaybackService.sharedInstance.isPlaying;
    [self reloadContent];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    [self sizeTableHeaderView];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateTableHeaderView];
        [self->_tableView reloadData];
    }];
}

#pragma mark - content

- (void)favoritesDidChange
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray<VLCFavorite *> *current =
            [[[VLCAppCoordinator sharedInstance] favoriteService] favoritesInGroupWithIdentifier:VLCFavoriteGroupRadio];
        if ([current isEqualToArray:self->_radioFavorites]) {
            return;
        }
        [self reloadContent];
    });
}

- (void)playbackDidStart
{
    [self setResumeSuppressed:YES];
}

- (void)playbackDidHalt
{
    [self setResumeSuppressed:NO];
}

- (void)setResumeSuppressed:(BOOL)suppressed
{
    if (_resumeSuppressed == suppressed) {
        return;
    }

    _resumeSuppressed = suppressed;

    if (self.isViewLoaded) {
        [self updateResumeSectionAnimated];
    }
}

- (void)handleRefresh:(UIRefreshControl *)refreshControl
{
    [self reloadContent];
    [refreshControl endRefreshing];
}

- (void)reloadContent
{
    [self reloadFavorites];
    [self updateTableHeaderView];
    [_tableView reloadData];
}

- (void)reloadFavorites
{
    _radioFavorites = [[[[VLCAppCoordinator sharedInstance] favoriteService] favoritesInGroupWithIdentifier:VLCFavoriteGroupRadio] copy];
    [self updateResumeItem];

    _zeroState = (_radioFavorites.count == 0);
}

- (void)updateResumeSectionAnimated
{
    BOOL wasVisible = (_resumeFavorite != nil);
    BOOL wasZeroState = _zeroState;

    [self reloadFavorites];

    if (wasVisible == (_resumeFavorite != nil) || wasZeroState != _zeroState) {
        [self updateTableHeaderView];
        [_tableView reloadData];
        return;
    }

    NSIndexSet *resumeSection = [NSIndexSet indexSetWithIndex:0];
    [_tableView performBatchUpdates:^{
        if (wasVisible) {
            [self->_tableView deleteSections:resumeSection withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self->_tableView insertSections:resumeSection withRowAnimation:UITableViewRowAnimationFade];
        }
    } completion:^(BOOL finished) {
        [self->_tableView reloadData];
    }];
}

- (void)updateResumeItem
{
    _resumeFavorite = nil;

    if (_resumeSuppressed) {
        return;
    }

    for (VLCFavorite *favorite in _radioFavorites) {
        NSDate *playedDate = favorite.lastPlayedDate;
        if (!playedDate) {
            continue;
        }
        if (!_resumeFavorite || [playedDate compare:_resumeFavorite.lastPlayedDate] == NSOrderedDescending) {
            _resumeFavorite = favorite;
        }
    }
}

- (NSString *)resumeMetaText
{
    NSDate *playedDate = _resumeFavorite.lastPlayedDate;
    if (!playedDate) {
        return nil;
    }

    if (@available(iOS 13.0, *)) {
        NSRelativeDateTimeFormatter *formatter = [[NSRelativeDateTimeFormatter alloc] init];
        formatter.dateTimeStyle = NSRelativeDateTimeFormatterStyleNamed;
        NSString *relative = [formatter localizedStringForDate:playedDate relativeToDate:[NSDate date]];
        return [NSString stringWithFormat:NSLocalizedString(@"ONAIR_CONTINUE_PAUSED", nil), relative];
    }

    return nil;
}

- (void)updateTableHeaderView
{
    if (!_zeroState) {
        _tableView.tableHeaderView = nil;
        return;
    }

    ColorPalette *themeColors = PresentationTheme.current.colors;

    UIView *header = [[UIView alloc] init];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font = [UIFont systemFontOfSize:24.0 weight:UIFontWeightBold];
    titleLabel.numberOfLines = 0;
    titleLabel.textColor = themeColors.cellTextColor;
    titleLabel.text = NSLocalizedString(@"ONAIR_ZERO_TITLE", nil);
    [header addSubview:titleLabel];

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subtitleLabel.font = [UIFont systemFontOfSize:15.0];
    subtitleLabel.numberOfLines = 0;
    subtitleLabel.textColor = themeColors.cellDetailTextColor;
    subtitleLabel.text = NSLocalizedString(@"ONAIR_ZERO_SUBTITLE", nil);
    [header addSubview:subtitleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:header.topAnchor constant:8.0],
        [titleLabel.leadingAnchor constraintEqualToAnchor:header.safeAreaLayoutGuide.leadingAnchor constant:kVLCOnAirSideMargin],
        [titleLabel.trailingAnchor constraintEqualToAnchor:header.safeAreaLayoutGuide.trailingAnchor constant:-kVLCOnAirSideMargin],

        [subtitleLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:10.0],
        [subtitleLabel.leadingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor],
        [subtitleLabel.trailingAnchor constraintEqualToAnchor:titleLabel.trailingAnchor],
        [subtitleLabel.bottomAnchor constraintEqualToAnchor:header.bottomAnchor constant:-16.0]
    ]];

    _tableView.tableHeaderView = header;
    [self sizeTableHeaderView];
}

- (void)sizeTableHeaderView
{
    UIView *header = _tableView.tableHeaderView;
    CGFloat width = CGRectGetWidth(_tableView.bounds);
    if (!header || width <= 0.0) {
        return;
    }

    header.frame = CGRectMake(0.0, 0.0, width, CGRectGetHeight(header.frame));
    [header layoutIfNeeded];

    CGSize size = [header systemLayoutSizeFittingSize:CGSizeMake(width, UILayoutFittingCompressedSize.height)
                       withHorizontalFittingPriority:UILayoutPriorityRequired
                             verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    if (CGRectGetHeight(header.frame) == size.height) {
        return;
    }

    header.frame = CGRectMake(0.0, 0.0, width, size.height);
    _tableView.tableHeaderView = header;
}

#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _resumeFavorite ? VLCOnAirSectionCount : VLCOnAirSectionCount - 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (VLCOnAirSection)sectionAtIndex:(NSInteger)index
{
    return (VLCOnAirSection)(_resumeFavorite ? index : index + 1);
}

- (BOOL)sectionHasRail:(VLCOnAirSection)section
{
    return section == VLCOnAirSectionRadio && _radioFavorites.count > 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCOnAirSection section = [self sectionAtIndex:indexPath.section];

    if (section == VLCOnAirSectionContinue) {
        VLCOnAirContinueCell *cell = [tableView dequeueReusableCellWithIdentifier:VLCOnAirContinueCell.reuseIdentifier
                                                                     forIndexPath:indexPath];
        cell.delegate = self;
        [cell configureWithName:_resumeFavorite.userVisibleName
                     artworkURL:_resumeFavorite.artworkURL
                           meta:[self resumeMetaText]
                       progress:0.0];
        return cell;
    }

    if ([self sectionHasRail:section]) {
        VLCOnAirRailCell *cell = [tableView dequeueReusableCellWithIdentifier:VLCOnAirRailCell.reuseIdentifier
                                                                 forIndexPath:indexPath];
        cell.delegate = self;
        [cell configureWithFavorites:_radioFavorites
                        showsAddTile:YES
                      referenceWidth:CGRectGetWidth(tableView.bounds)];
        return cell;
    }

    VLCOnAirPromptCell *cell = [tableView dequeueReusableCellWithIdentifier:VLCOnAirPromptCell.reuseIdentifier
                                                               forIndexPath:indexPath];
    cell.delegate = self;
    [self configurePromptCell:cell forSection:section];
    return cell;
}

- (void)configurePromptCell:(VLCOnAirPromptCell *)cell forSection:(VLCOnAirSection)section
{
    NSString *title = [self titleForSection:section];
    NSString *body;
    NSString *primaryTitle;
    NSString *secondaryTitle;

    switch (section) {
        case VLCOnAirSectionRadio:
            body = NSLocalizedString(@"RADIOVC_DETAILTEXT", nil);
            primaryTitle = NSLocalizedString(@"ONAIR_FIND_STATION", nil);
            break;
        case VLCOnAirSectionPodcasts:
            if (!_zeroState) {
                title = NSLocalizedString(@"ONAIR_PODCASTS_EMPTY_TITLE", nil);
            }
            body = _zeroState ? NSLocalizedString(@"ONAIR_PODCASTS_ZERO_BODY", nil)
                              : NSLocalizedString(@"ONAIR_PODCASTS_EMPTY_BODY", nil);
            primaryTitle = NSLocalizedString(@"SEARCH", nil);
            secondaryTitle = NSLocalizedString(@"ONAIR_PASTE_RSS", nil);
            break;
        case VLCOnAirSectionTV:
            if (!_zeroState) {
                title = NSLocalizedString(@"ONAIR_TV_EMPTY_TITLE", nil);
            }
            body = NSLocalizedString(@"ONAIR_TV_EMPTY_BODY", nil);
            primaryTitle = NSLocalizedString(@"ONAIR_OPEN_DIRECTORY", nil);
            secondaryTitle = NSLocalizedString(@"ONAIR_ADD_M3U", nil);
            break;
        default:
            break;
    }

    [cell configureWithGlyph:[self glyphForSection:section]
                       title:title
                        body:body
                primaryTitle:primaryTitle
              secondaryTitle:secondaryTitle];
}

- (NSString *)titleForSection:(VLCOnAirSection)section
{
    switch (section) {
        case VLCOnAirSectionRadio:
            return NSLocalizedString(@"RADIO", nil);
        case VLCOnAirSectionPodcasts:
            return NSLocalizedString(@"ONAIR_PODCASTS", nil);
        case VLCOnAirSectionTV:
            return NSLocalizedString(@"ONAIR_TV", nil);
        default:
            return nil;
    }
}

- (UIImage *)glyphForSection:(VLCOnAirSection)section
{
    if (@available(iOS 13.0, *)) {
        switch (section) {
            case VLCOnAirSectionRadio:
                if (@available(iOS 14.0, *)) {
                    return [UIImage systemImageNamed:@"radio"];
                }
                return [UIImage systemImageNamed:@"antenna.radiowaves.left.and.right"];
            case VLCOnAirSectionPodcasts:
                return [UIImage systemImageNamed:@"dot.radiowaves.left.and.right"];
            case VLCOnAirSectionTV:
                return [UIImage systemImageNamed:@"tv"];
            default:
                return nil;
        }
    }

    return nil;
}

#pragma mark - table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCOnAirSection section = [self sectionAtIndex:indexPath.section];
    if ([self sectionHasRail:section]) {
        return [VLCOnAirRailCell heightForWidth:CGRectGetWidth(tableView.bounds)];
    }

    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (_zeroState || [self sectionAtIndex:section] == VLCOnAirSectionContinue) {
        return CGFLOAT_MIN;
    }

    return kVLCOnAirHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (_zeroState || [self sectionAtIndex:section] == VLCOnAirSectionContinue) {
        return nil;
    }

    return [self sectionHeaderViewWithTitle:[self titleForSection:[self sectionAtIndex:section]]
                                        tag:section];
}

- (UIView *)sectionHeaderViewWithTitle:(NSString *)title tag:(NSInteger)tag
{
    ColorPalette *themeColors = PresentationTheme.current.colors;

    UIView *header = [[UIView alloc] init];
    header.backgroundColor = [UIColor clearColor];

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightBold];
    label.textColor = themeColors.cellTextColor;
    label.text = title;
    [header addSubview:label];

    UIButton *seeAllButton = [UIButton buttonWithType:UIButtonTypeSystem];
    seeAllButton.translatesAutoresizingMaskIntoConstraints = NO;
    seeAllButton.tag = tag;
    seeAllButton.tintColor = themeColors.orangeUI;
    seeAllButton.titleLabel.font = [UIFont systemFontOfSize:16.0];
    [seeAllButton setTitle:NSLocalizedString(@"SEE_ALL", nil) forState:UIControlStateNormal];
    [seeAllButton addTarget:self action:@selector(seeAllAction:) forControlEvents:UIControlEventTouchUpInside];
    [seeAllButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [header addSubview:seeAllButton];

    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:header.safeAreaLayoutGuide.leadingAnchor constant:kVLCOnAirSideMargin],
        [label.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],

        [seeAllButton.leadingAnchor constraintGreaterThanOrEqualToAnchor:label.trailingAnchor constant:8.0],
        [seeAllButton.trailingAnchor constraintEqualToAnchor:header.safeAreaLayoutGuide.trailingAnchor constant:-kVLCOnAirSideMargin],
        [seeAllButton.centerYAnchor constraintEqualToAnchor:label.centerYAnchor]
    ]];

    return header;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([self sectionAtIndex:indexPath.section] == VLCOnAirSectionContinue) {
        [self playFavorite:_resumeFavorite];
    }
}

#pragma mark - cell delegates

- (void)railCell:(VLCOnAirRailCell *)cell didSelectItemAtIndex:(NSInteger)index
{
    if (index >= (NSInteger)_radioFavorites.count) {
        return;
    }

    [self playFavorite:_radioFavorites[index]];
}

- (void)railCellDidSelectAddTile:(VLCOnAirRailCell *)cell
{
    [self showRadio];
}

- (void)continueCellDidTapPlay:(VLCOnAirContinueCell *)cell
{
    [self playFavorite:_resumeFavorite];
}

- (void)promptCell:(VLCOnAirPromptCell *)cell didTapButtonAtIndex:(NSInteger)index
{
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    if (!indexPath) {
        return;
    }

    switch ([self sectionAtIndex:indexPath.section]) {
        case VLCOnAirSectionRadio:
            [self showRadio];
            break;
        case VLCOnAirSectionPodcasts:
            index == 0 ? [self showPodcasts] : [self showPodcastFeedEntry];
            break;
        case VLCOnAirSectionTV:
            index == 0 ? [self showTVDirectory] : [self showAddM3U];
            break;
        default:
            break;
    }
}

- (void)seeAllAction:(UIButton *)sender
{
    switch ([self sectionAtIndex:sender.tag]) {
        case VLCOnAirSectionRadio:
            [self showRadio];
            break;
        case VLCOnAirSectionPodcasts:
            [self showPodcasts];
            break;
        case VLCOnAirSectionTV:
            [self showTVDirectory];
            break;
        default:
            break;
    }
}

#pragma mark - playback

- (void)playFavorite:(VLCFavorite *)favorite
{
    if (!favorite) {
        return;
    }

    [[[VLCAppCoordinator sharedInstance] favoriteService] playFavorite:favorite];

    _resumeSuppressed = YES;
    [self updateResumeSectionAnimated];
}

#pragma mark - navigation

- (void)showRadio
{
    [self.navigationController pushViewController:[[VLCRadioListViewController alloc] init] animated:YES];
}

- (void)showPodcasts
{
    APLog(@"On Air: no podcast directory available yet");
}

- (void)showPodcastFeedEntry
{
    APLog(@"On Air: no podcast feed subscription available yet");
}

- (void)showTVDirectory
{
    APLog(@"On Air: no TV channel directory available yet");
}

- (void)showAddM3U
{
    APLog(@"On Air: no M3U channel list import available yet");
}

- (void)showSearch
{
    APLog(@"On Air: no cross-category search available yet");
}

- (void)showSettings
{
    [[ParentalControlCoordinator sharedInstance] authorizeIfParentalControlIsEnabledWithAction:^{
        MediaLibraryService *mediaLibraryService = [[VLCAppCoordinator sharedInstance] mediaLibraryService];
        SettingsController *settingsController = [[SettingsController alloc] initWithMediaLibraryService:mediaLibraryService];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:settingsController];
        [self presentViewController:navigationController animated:YES completion:nil];
    } fail:nil];
}

#pragma mark - appearance

- (void)updateTheme
{
    if (@available(iOS 13.0, *)) {
        _tableView.backgroundColor = UIColor.secondarySystemBackgroundColor;
    } else {
        _tableView.backgroundColor = PresentationTheme.current.colors.background;
    }

    [self updateTableHeaderView];
    [_tableView reloadData];
}

- (void)miniPlayerIsShown
{
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, VLCAudioMiniPlayer.height, 0);
}

- (void)miniPlayerIsHidden
{
    _tableView.contentInset = UIEdgeInsetsZero;
}

@end
