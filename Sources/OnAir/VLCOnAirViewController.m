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
#import "VLCMetadata.h"
#import "VLCNetworkImageView.h"
#import "VLCPlayerDisplayController.h"
#import "VLCRadioListViewController.h"
#import "VLCRadioService.h"

#import "VLC-Swift.h"

typedef NS_ENUM(NSInteger, VLCOnAirSection) {
    VLCOnAirSectionContinue,
    VLCOnAirSectionRadio,
    VLCOnAirSectionRadioRecent,
    VLCOnAirSectionPodcasts,
    VLCOnAirSectionTV,
    VLCOnAirSectionCount
};

static CGFloat const kVLCOnAirSideMargin = 20.0;
static CGFloat const kVLCOnAirHeaderHeight = 44.0;
static CGFloat const kVLCOnAirRailSpacing = 12.0;

@interface VLCOnAirViewController () <UITableViewDataSource, UITableViewDelegate,
                                      VLCOnAirRailCellDelegate, VLCOnAirPromptCellDelegate,
                                      VLCOnAirContinueCellDelegate>
@end

@implementation VLCOnAirViewController
{
    UITableView *_tableView;
    NSArray<VLCFavorite *> *_radioFavorites;
    NSArray<VLCFavorite *> *_recentStreams;
    NSArray<NSNumber *> *_visibleSections;
    VLCFavorite *_resumeStream;
    PodcastResumeItem *_resumeEpisode;
    BOOL _resumeSuppressed;
    BOOL _radioIsEmpty;
    BOOL _podcastsIsEmpty;
    BOOL _tvIsEmpty;
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
        _recentStreams = @[];
        _visibleSections = @[];
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
    [PodcastsOnAirBridge registerShowsCellWith:_tableView];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    _tableView.refreshControl = refreshControl;

    self.view = _tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = [[VLCAppMenuBarButtonItem alloc] initWithPresenter:self];

    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                  target:self
                                                                                  action:@selector(showSearch)];
    searchButton.accessibilityLabel = NSLocalizedString(@"SEARCH", nil);
    self.navigationItem.rightBarButtonItem = searchButton;

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(updateTheme) name:kVLCThemeDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(favoritesDidChange) name:VLCFavoriteServiceContentDidChange object:nil];
    [notificationCenter addObserver:self selector:@selector(reloadContent) name:VLCRadioRecentStreamsDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(podcastsDidChange) name:NSNotification.VLCPodcastsContentDidChange object:nil];
    [notificationCenter addObserver:self selector:@selector(miniPlayerIsShown) name:VLCPlayerDisplayControllerDisplayMiniPlayer object:nil];
    [notificationCenter addObserver:self selector:@selector(miniPlayerIsHidden) name:VLCPlayerDisplayControllerHideMiniPlayer object:nil];
    [notificationCenter addObserver:self selector:@selector(playbackDidStart) name:VLCPlaybackServicePlaybackDidStart object:nil];
    [notificationCenter addObserver:self selector:@selector(playbackDidStart) name:VLCPlaybackServicePlaybackDidResume object:nil];
    [notificationCenter addObserver:self selector:@selector(playbackDidHalt) name:VLCPlaybackServicePlaybackDidPause object:nil];
    [notificationCenter addObserver:self selector:@selector(playbackDidHalt) name:VLCPlaybackServicePlaybackDidStop object:nil];
    [notificationCenter addObserver:self selector:@selector(playbackDidHalt) name:VLCPlaybackServicePlaybackDidFail object:nil];

    [PodcastsOnAirBridge configureWithMediaLibraryService:[[VLCAppCoordinator sharedInstance] mediaLibraryService]];

    [self updateTheme];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.prefersLargeTitles = NO;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;

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

- (void)podcastsDidChange
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadContent];
    });
}

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
    _recentStreams = [[[VLCAppCoordinator sharedInstance] radioService] recentStreams];
    [self updateResumeItem];

    _radioIsEmpty = (_radioFavorites.count == 0);
    _podcastsIsEmpty = (PodcastsOnAirBridge.numberOfShows == 0);
    // No TV channel data source exists yet, so this section is always empty for now.
    _tvIsEmpty = YES;

    [self rebuildVisibleSections];
}

- (void)rebuildVisibleSections
{
    NSMutableArray<NSNumber *> *sections = [NSMutableArray arrayWithCapacity:VLCOnAirSectionCount];

    if ([self hasResumeItem]) {
        [sections addObject:@(VLCOnAirSectionContinue)];
    }
    [sections addObject:@(VLCOnAirSectionRadio)];
    if (_recentStreams.count > 0) {
        [sections addObject:@(VLCOnAirSectionRadioRecent)];
    }
    [sections addObject:@(VLCOnAirSectionPodcasts)];
    [sections addObject:@(VLCOnAirSectionTV)];

    _visibleSections = sections;
}

- (BOOL)isZeroState
{
    return _radioIsEmpty && _recentStreams.count == 0 && _podcastsIsEmpty && _tvIsEmpty;
}

- (BOOL)onlyResumeSectionChangedFrom:(NSArray<NSNumber *> *)previousSections
                                  to:(NSArray<NSNumber *> *)updatedSections
{
    NSArray<NSNumber *> *longer = previousSections.count > updatedSections.count ? previousSections
                                                                                : updatedSections;
    NSArray<NSNumber *> *shorter = longer == previousSections ? updatedSections : previousSections;

    if (longer.count != shorter.count + 1 || longer.firstObject.integerValue != VLCOnAirSectionContinue) {
        return NO;
    }

    return [[longer subarrayWithRange:NSMakeRange(1, shorter.count)] isEqualToArray:shorter];
}

- (void)updateResumeSectionAnimated
{
    BOOL wasVisible = [self hasResumeItem];
    BOOL wasZeroState = [self isZeroState];
    NSArray<NSNumber *> *previousSections = _visibleSections;

    [self reloadFavorites];

    NSArray<NSNumber *> *updatedSections = _visibleSections;
    if (self.viewIfLoaded.window == nil || wasZeroState != [self isZeroState]
        || ![self onlyResumeSectionChangedFrom:previousSections to:updatedSections]) {
        [self updateTableHeaderView];
        [_tableView reloadData];
        return;
    }

    // the batch update animates from the section count the table view last committed, so it has to
    // see the previous sections and commit them before it runs
    _visibleSections = previousSections;
    [_tableView layoutIfNeeded];

    if (_tableView.numberOfSections != (NSInteger)previousSections.count) {
        _visibleSections = updatedSections;
        [_tableView reloadData];
        return;
    }

    NSIndexSet *resumeSection = [NSIndexSet indexSetWithIndex:0];
    [_tableView performBatchUpdates:^{
        self->_visibleSections = updatedSections;
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
    _resumeStream = nil;
    _resumeEpisode = nil;

    if (_resumeSuppressed) {
        return;
    }

    [self updateResumeItemWithStreams:_radioFavorites];
    [self updateResumeItemWithStreams:_recentStreams];

    PodcastResumeItem *episode = PodcastsOnAirBridge.resumeEpisode;
    if (!episode) {
        return;
    }
    if (_resumeStream && [episode.lastPlayedDate compare:_resumeStream.lastPlayedDate] != NSOrderedDescending) {
        return;
    }

    _resumeStream = nil;
    _resumeEpisode = episode;
}

- (BOOL)hasResumeItem
{
    return _resumeStream != nil || _resumeEpisode != nil;
}

- (void)updateResumeItemWithStreams:(NSArray<VLCFavorite *> *)streams
{
    for (VLCFavorite *stream in streams) {
        NSDate *playedDate = stream.lastPlayedDate;
        if (!playedDate) {
            continue;
        }
        if (!_resumeStream || [playedDate compare:_resumeStream.lastPlayedDate] == NSOrderedDescending) {
            _resumeStream = stream;
        }
    }
}

- (NSString *)resumeMetaTextForDate:(NSDate *)playedDate
{
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
    if (![self isZeroState]) {
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
    return _visibleSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (VLCOnAirSection)sectionAtIndex:(NSInteger)index
{
    if (index < 0 || index >= (NSInteger)_visibleSections.count) {
        return VLCOnAirSectionCount;
    }

    return (VLCOnAirSection)_visibleSections[index].integerValue;
}

- (BOOL)sectionHasRail:(VLCOnAirSection)section
{
    if (section == VLCOnAirSectionRadio) {
        return _radioFavorites.count > 0;
    }
    if (section == VLCOnAirSectionRadioRecent) {
        return _recentStreams.count > 0;
    }
    if (section == VLCOnAirSectionPodcasts) {
        return PodcastsOnAirBridge.numberOfShows > 0;
    }
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCOnAirSection section = [self sectionAtIndex:indexPath.section];

    if (section == VLCOnAirSectionContinue) {
        VLCOnAirContinueCell *cell = [tableView dequeueReusableCellWithIdentifier:VLCOnAirContinueCell.reuseIdentifier
                                                                     forIndexPath:indexPath];
        cell.delegate = self;
        if (_resumeEpisode) {
            [cell configureWithName:_resumeEpisode.title
                         artworkURL:_resumeEpisode.artworkURL
                               meta:[self resumeMetaTextForDate:_resumeEpisode.lastPlayedDate]
                           progress:_resumeEpisode.progress];
        } else {
            [cell configureWithName:_resumeStream.userVisibleName
                         artworkURL:_resumeStream.artworkURL
                               meta:[self resumeMetaTextForDate:_resumeStream.lastPlayedDate]
                           progress:0.0];
        }
        return cell;
    }

    if (section == VLCOnAirSectionRadio && [self sectionHasRail:section]) {
        VLCOnAirRailCell *cell = [tableView dequeueReusableCellWithIdentifier:VLCOnAirRailCell.reuseIdentifier
                                                                 forIndexPath:indexPath];
        cell.delegate = self;
        [cell configureWithFavorites:_radioFavorites showsAddTile:YES];
        return cell;
    }

    if (section == VLCOnAirSectionRadioRecent && [self sectionHasRail:section]) {
        VLCOnAirRailCell *cell = [tableView dequeueReusableCellWithIdentifier:VLCOnAirRailCell.reuseIdentifier
                                                                 forIndexPath:indexPath];
        cell.delegate = self;
        [cell configureWithFavorites:_recentStreams showsAddTile:NO];
        return cell;
    }

    if (section == VLCOnAirSectionPodcasts && [self sectionHasRail:section]) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PodcastsOnAirBridge.showsCellReuseIdentifier
                                                                 forIndexPath:indexPath];
        __weak typeof(self) weakSelf = self;
        [PodcastsOnAirBridge configureShowsCell:cell onSelectShowId:^(NSString *showId) {
            [weakSelf showPodcastShowWithId:showId];
        }];
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
    NSString *title;
    NSString *primaryTitle;
    NSString *secondaryTitle;
    BOOL actionsAvailable = YES;

    switch (section) {
        case VLCOnAirSectionRadio:
            title = NSLocalizedString(@"RADIOVC_DETAILTEXT", nil);
            primaryTitle = NSLocalizedString(@"ONAIR_FIND_STATION", nil);
            break;
        case VLCOnAirSectionPodcasts:
            title = [self isZeroState] ? NSLocalizedString(@"ONAIR_PODCASTS_ZERO_BODY", nil)
                                       : NSLocalizedString(@"ONAIR_PODCASTS_EMPTY_BODY", nil);
            primaryTitle = NSLocalizedString(@"ONAIR_PASTE_RSS", nil);
            break;
        case VLCOnAirSectionTV:
            title = NSLocalizedString(@"ONAIR_TV_EMPTY_BODY", nil);
            primaryTitle = NSLocalizedString(@"ONAIR_OPEN_DIRECTORY", nil);
            secondaryTitle = NSLocalizedString(@"ONAIR_ADD_M3U", nil);
            actionsAvailable = NO;
            break;
        default:
            break;
    }

    [cell configureWithGlyph:[self glyphForSection:section]
                       title:title
                primaryTitle:primaryTitle
              secondaryTitle:secondaryTitle
            actionsAvailable:actionsAvailable];
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
    if ((section == VLCOnAirSectionRadio || section == VLCOnAirSectionRadioRecent) && [self sectionHasRail:section]) {
        return VLCOnAirRailCell.height;
    }

    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    VLCOnAirSection onAirSection = [self sectionAtIndex:section];
    if (onAirSection == VLCOnAirSectionRadioRecent) {
        return kVLCOnAirRailSpacing;
    }
    if (![self sectionHasHeader:onAirSection]) {
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
    VLCOnAirSection onAirSection = [self sectionAtIndex:section];
    if (onAirSection == VLCOnAirSectionRadioRecent) {
        UIView *spacer = [[UIView alloc] init];
        spacer.backgroundColor = [UIColor clearColor];
        return spacer;
    }
    if (![self sectionHasHeader:onAirSection]) {
        return nil;
    }

    return [self sectionHeaderViewWithTitle:[self titleForSection:onAirSection]
                                        tag:section
                                showsSeeAll:[self sectionHasRail:onAirSection]];
}

- (BOOL)sectionHasHeader:(VLCOnAirSection)section
{
    switch (section) {
        case VLCOnAirSectionRadio:
        case VLCOnAirSectionPodcasts:
        case VLCOnAirSectionTV:
            return YES;
        default:
            return NO;
    }
}

- (UIView *)sectionHeaderViewWithTitle:(NSString *)title tag:(NSInteger)tag showsSeeAll:(BOOL)showsSeeAll
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

    if (!showsSeeAll) {
        [NSLayoutConstraint activateConstraints:@[
            [label.leadingAnchor constraintEqualToAnchor:header.safeAreaLayoutGuide.leadingAnchor constant:kVLCOnAirSideMargin],
            [label.trailingAnchor constraintLessThanOrEqualToAnchor:header.safeAreaLayoutGuide.trailingAnchor constant:-kVLCOnAirSideMargin],
            [label.centerYAnchor constraintEqualToAnchor:header.centerYAnchor]
        ]];

        return header;
    }

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
        [self playResumeItem];
    }
}

#pragma mark - cell delegates

- (NSArray<VLCFavorite *> *)itemsForRailCell:(VLCOnAirRailCell *)cell
{
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    if (indexPath && [self sectionAtIndex:indexPath.section] == VLCOnAirSectionRadioRecent) {
        return _recentStreams;
    }

    return _radioFavorites;
}

- (void)railCell:(VLCOnAirRailCell *)cell didSelectItemAtIndex:(NSInteger)index
{
    NSArray<VLCFavorite *> *items = [self itemsForRailCell:cell];
    if (index >= (NSInteger)items.count) {
        return;
    }

    [self playFavorite:items[index]];
}

- (void)railCellDidSelectAddTile:(VLCOnAirRailCell *)cell
{
    [self showRadio];
}

- (void)continueCellDidTapPlay:(VLCOnAirContinueCell *)cell
{
    [self playResumeItem];
}

- (void)playResumeItem
{
    if (_resumeEpisode) {
        [PodcastsOnAirBridge playResumeEpisode:_resumeEpisode];
        return;
    }
    [self playFavorite:_resumeStream];
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
            [self showPodcasts];
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

    [VLCPlaybackService.sharedInstance.metadata prepareArtworkImage:[VLCNetworkImageView cachedImageForURL:favorite.artworkURL]
                                                             forURL:favorite.artworkURL];

    [[[VLCAppCoordinator sharedInstance] favoriteService] playFavorite:favorite];
    [[[VLCAppCoordinator sharedInstance] radioService] markStreamPlayed:favorite];

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
    MediaLibraryService *mediaLibraryService = [[VLCAppCoordinator sharedInstance] mediaLibraryService];
    UIViewController *podcastsViewController = [PodcastsOnAirBridge makePodcastsViewControllerWithMediaLibraryService:mediaLibraryService];
    [self.navigationController pushViewController:podcastsViewController animated:YES];
}

- (void)showPodcastShowWithId:(NSString *)showId
{
    UIViewController *detailViewController = [PodcastsOnAirBridge makeShowDetailViewControllerForShowId:showId];
    if (!detailViewController) {
        return;
    }
    [self.navigationController pushViewController:detailViewController animated:YES];
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

#pragma mark - appearance

- (void)updateTheme
{
    _tableView.backgroundColor = PresentationTheme.current.colors.pageBackground;

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
