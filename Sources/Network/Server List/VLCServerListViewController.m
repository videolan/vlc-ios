/*****************************************************************************
 * VLCServerListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2026 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *          Vincent L. Cone <vincent.l.cone # tuta.io>
 *          Carola Nitz <caro # videolan.org>
 *          Diogo Simao Marques <dogo@videolabs.io>
 *          Eshan Singh <eeeshan789@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCServerListViewController.h"
#import "VLCLocalServerDiscoveryController.h"

#import "VLCPlaybackService.h"
#import "VLCPlayerDisplayController.h"
#import "VLCNetworkLoginViewController.h"
#import "VLCNetworkServerBrowserViewController.h"
#import "VLCNetworkServerBrowserFactory.h"

#import "VLCNetworkServerLoginInformation+Keychain.h"

#import "VLCNetworkServerBrowserVLCMedia.h"

#import "VLCLocalNetworkServiceBrowserUPnP.h"
#import "VLCLocalNetworkServiceBrowserPlex.h"
#import "VLCLocalNetworkServiceBrowserHTTP.h"
#import "VLCLocalNetworkServiceBrowserDSM.h"
#import "VLCLocalNetworkServiceBrowserNFS.h"
#import "VLCLocalNetworkServiceBrowserBonjour.h"

#import "VLCArtworkTile.h"
#import "VLCAddTile.h"
#import "VLCBrowseSectionHeader.h"
#import "VLCBrowseChipCell.h"
#import "VLCBrowseSharingCell.h"
#import "VLCBrowseSharingBandCell.h"

#import "VLCAppCoordinator.h"
#import "VLCFavoriteService.h"
#import "VLCSavedServerList.h"
#import "VLCHTTPUploaderController.h"
#import "VLCDocumentPickerController.h"
#import "VLCTransferViewController.h"
#import "VLCOpenNetworkStreamViewController.h"
#if TARGET_OS_IOS
#import "VLCPhotoLibraryController.h"
#import "VLCCloudServicesTableViewController.h"
#import "VLCCloudServiceFactory.h"
#endif

#import "VLC-Swift.h"

typedef NS_ENUM(NSInteger, VLCBrowseSection) {
    VLCBrowseSectionNetwork,
    VLCBrowseSectionFavorites,
    VLCBrowseSectionOpen,
    VLCBrowseSectionCount
};

typedef NS_ENUM(NSInteger, VLCBrowseChip) {
    VLCBrowseChipLocalFiles,
    VLCBrowseChipPhotos,
    VLCBrowseChipCloud,
    VLCBrowseChipNetworkStream,
    VLCBrowseChipDownloads,
    VLCBrowseChipWiFiSharing
};

static NSTimeInterval const kVLCBrowseReloadDebounceInterval = 0.1;

static CGFloat const kVLCBrowseGutter = 20.0;
static CGFloat const kVLCBrowseTileGap = 9.0;
static CGFloat const kVLCBrowseChipGap = 7.0;
static CGFloat const kVLCBrowseMinTileWidth = 105.0;
static CGFloat const kVLCBrowseMinChipWidth = 163.0;
static NSInteger const kVLCBrowseChipColumnsCompact = 2;
static NSInteger const kVLCBrowseChipColumnsRegular = 4;
static CGFloat const kVLCBrowseCaptionArea = 28.0;
static CGFloat const kVLCBrowseChipHeight = 44.0;
static CGFloat const kVLCBrowseTileCornerRadius = 14.0;
static CGFloat const kVLCBrowseSectionSpacing = 16.0;

@interface VLCServerListViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
                                           VLCLocalServerDiscoveryControllerDelegate,
                                           VLCNetworkLoginViewControllerDelegate,
                                           VLCBrowseSectionHeaderDelegate,
                                           VLCBrowseSharingCellDelegate,
                                           VLCArtworkTileDelegate>
@end

@implementation VLCServerListViewController
{
    UICollectionView *_collectionView;
    UIRefreshControl *_refreshControl;

    VLCLocalServerDiscoveryController *_discoveryController;
    NSArray<Class> *_browserClasses;
    NSArray<id<VLCLocalNetworkService>> *_discoveredServices;
    NSArray<NSString *> *_discoveredPills;
    BOOL _reloadScheduled;

    NSArray<NSString *> *_manualServers;
    NSArray<VLCFavorite *> *_favoriteFolders;
    NSArray<NSNumber *> *_chips;
    BOOL _sharingExpanded;
    NSUserActivity *_sharingActivity;

    MediaLibraryService *_medialibraryService;
    VLCFavoriteService *_favoriteService;
    VLCSavedServerList *_savedServerList;
    VLCHTTPUploaderController *_httpUploaderController;
    NSObject *_photoLibraryController;
}

- (instancetype)initWithMedialibraryService:(MediaLibraryService *)medialibraryService
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _medialibraryService = medialibraryService;
        _discoveredServices = @[];
        _discoveredPills = @[];
        _manualServers = @[];
        _favoriteFolders = @[];
        _chips = [self availableChips];
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    self.title = NSLocalizedString(@"BROWSE", nil);
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"BROWSE", nil)
                                                    image:[UIImage imageNamed:@"Network"]
                                            selectedImage:[UIImage imageNamed:@"Network"]];
    self.tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.localNetwork;
}

- (NSArray<NSNumber *> *)availableChips
{
    NSMutableArray<NSNumber *> *chips = [NSMutableArray array];

    [chips addObject:@(VLCBrowseChipLocalFiles)];
#if TARGET_OS_IOS
    if (@available(iOS 14.0, *)) {
        [chips addObject:@(VLCBrowseChipPhotos)];
    }
    [chips addObject:@(VLCBrowseChipCloud)];
#endif
    [chips addObject:@(VLCBrowseChipNetworkStream)];
    [chips addObject:@(VLCBrowseChipDownloads)];
    [chips addObject:@(VLCBrowseChipWiFiSharing)];

    return chips;
}

#pragma mark - view lifecycle

- (void)loadView
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionHeadersPinToVisibleBounds = NO;

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.alwaysBounceVertical = YES;

    [_collectionView registerClass:[VLCArtworkTile class]
        forCellWithReuseIdentifier:VLCArtworkTile.reuseIdentifier];
    [_collectionView registerClass:[VLCAddTile class]
        forCellWithReuseIdentifier:VLCAddTile.reuseIdentifier];
    [_collectionView registerClass:[VLCBrowseChipCell class]
        forCellWithReuseIdentifier:VLCBrowseChipCell.reuseIdentifier];
    [_collectionView registerClass:[VLCBrowseSharingCell class]
        forCellWithReuseIdentifier:VLCBrowseSharingCell.reuseIdentifier];
    [_collectionView registerClass:[VLCBrowseSharingBandCell class]
        forCellWithReuseIdentifier:VLCBrowseSharingBandCell.reuseIdentifier];
    [_collectionView registerClass:[VLCBrowseSectionHeader class]
        forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
               withReuseIdentifier:VLCBrowseSectionHeader.reuseIdentifier];

    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    _collectionView.refreshControl = _refreshControl;

    self.view = _collectionView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _favoriteService = [[VLCAppCoordinator sharedInstance] favoriteService];
    _savedServerList = [[VLCAppCoordinator sharedInstance] savedServerList];
    _httpUploaderController = [[VLCAppCoordinator sharedInstance] httpUploaderController];

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

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(themeDidChange) name:kVLCThemeDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(contentSizeDidChange) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(favoritesDidChange) name:VLCFavoriteServiceContentDidChange object:nil];
    [notificationCenter addObserver:self selector:@selector(favoritesDidChange) name:VLCSavedServerListDidChange object:nil];
    [notificationCenter addObserver:self selector:@selector(miniPlayerIsShown) name:VLCPlayerDisplayControllerDisplayMiniPlayer object:nil];
    [notificationCenter addObserver:self selector:@selector(miniPlayerIsHidden) name:VLCPlayerDisplayControllerHideMiniPlayer object:nil];

    _browserClasses = @[
        [VLCLocalNetworkServiceBrowserUPnP class],
        [VLCLocalNetworkServiceBrowserPlex class],
        [VLCLocalNetworkServiceBrowserHTTP class],
        [VLCLocalNetworkServiceBrowserDSM class],
        [VLCLocalNetworkServiceBrowserBonjour class],
        [VLCLocalNetworkServiceBrowserNFS class],
    ];

    _discoveryController = [[VLCLocalServerDiscoveryController alloc] initWithServiceBrowserClasses:_browserClasses];
    _discoveryController.delegate = self;

    [self themeDidChange];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.prefersLargeTitles = NO;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;

    VLCPlaybackService.sharedInstance.playerDisplayController.isMiniPlayerVisible
    ? [self miniPlayerIsShown] : [self miniPlayerIsHidden];

    _sharingExpanded = _httpUploaderController.isReachable && _httpUploaderController.isServerRunning;
    [self updateSharingHandoff];
    [self rebuildFavorites];
    [_collectionView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_discoveryController startDiscovery];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_discoveryController stopDiscovery];

    [_sharingActivity invalidate];
    _sharingActivity = nil;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    /* the number of chip columns changes with the width, so the sharing chip and its band
     * need to re-evaluate whether they still form one shape */
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self->_collectionView.collectionViewLayout invalidateLayout];
        [self->_collectionView reloadData];
    }];
}

#if TARGET_OS_IOS
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    /* the event handler in TabBarCoordinator cannot listen to the system because the movie view controller blocks the event
     * Therefore, we need to check the current theme ourselves */
    if (@available(iOS 13.0, *)) {
        if (previousTraitCollection.userInterfaceStyle == self.traitCollection.userInterfaceStyle) {
            return;
        }

        if ([[NSUserDefaults standardUserDefaults] integerForKey:kVLCSettingAppTheme] == kVLCSettingAppThemeSystem) {
            [PresentationTheme themeDidUpdate];
        }
        [self themeDidChange];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return PresentationTheme.current.colors.statusBarStyle;
}
#endif

#pragma mark - content

- (NSString *)pillTitleForBrowserClass:(Class)browserClass
{
    if (browserClass == [VLCLocalNetworkServiceBrowserUPnP class]) {
        return NSLocalizedString(@"UPNP_SHORT", nil);
    }
    if (browserClass == [VLCLocalNetworkServiceBrowserPlex class]) {
        return NSLocalizedString(@"PLEX_SHORT", nil);
    }
    if (browserClass == [VLCLocalNetworkServiceBrowserHTTP class]) {
        return NSLocalizedString(@"SHARED_VLC_IOS_LIBRARY_SHORT", nil);
    }
    if (browserClass == [VLCLocalNetworkServiceBrowserDSM class]) {
        return NSLocalizedString(@"SMB_CIFS_FILE_SERVERS_SHORT", nil);
    }
    if (browserClass == [VLCLocalNetworkServiceBrowserNFS class]) {
        return NSLocalizedString(@"NFS_SHORT", nil);
    }

    return nil;
}

- (NSString *)pillTitleForConnectionProtocol:(NSString *)connectionProtocol
{
    if (connectionProtocol.length == 0) {
        return nil;
    }

    NSString *identifier = connectionProtocol.uppercaseString;

    if ([identifier isEqualToString:@"SMB"]) {
        return NSLocalizedString(@"SMB_CIFS_FILE_SERVERS_SHORT", nil);
    }
    if ([identifier isEqualToString:@"NFS"]) {
        return NSLocalizedString(@"NFS_SHORT", nil);
    }
    if ([identifier isEqualToString:@"FTP"]) {
        return NSLocalizedString(@"FTP_SHORT", nil);
    }
    if ([identifier isEqualToString:@"SFTP"]) {
        return NSLocalizedString(@"SFTP_SHORT", nil);
    }
    if ([identifier isEqualToString:@"DAV"] || [identifier isEqualToString:@"DAVS"]) {
        return NSLocalizedString(@"WEBDAV_SHORT", nil);
    }
    if ([identifier isEqualToString:@"UPNP"]) {
        return NSLocalizedString(@"UPNP_SHORT", nil);
    }

    return identifier;
}

- (void)rebuildDiscoveredServices
{
    NSMutableArray<id<VLCLocalNetworkService>> *services = [NSMutableArray array];
    NSMutableArray<NSString *> *pills = [NSMutableArray array];
    NSUInteger sectionCount = _discoveryController.numberOfSections;

    for (NSUInteger section = 0; section < sectionCount; section++) {
        NSString *browserPill = section < _browserClasses.count ? [self pillTitleForBrowserClass:_browserClasses[section]] : nil;
        NSUInteger itemCount = [_discoveryController numberOfItemsInSection:section];
        for (NSUInteger item = 0; item < itemCount; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:item inSection:section];
            id<VLCLocalNetworkService> service = [_discoveryController networkServiceForIndexPath:indexPath];
            if (!service) {
                continue;
            }

            /* browsers that speak a single protocol name it themselves, Bonjour finds many */
            NSString *pill = browserPill;
            if (!pill && [service respondsToSelector:@selector(connectionProtocol)]) {
                pill = [self pillTitleForConnectionProtocol:service.connectionProtocol];
            }

            [services addObject:service];
            [pills addObject:pill ?: @""];
        }
    }

    _discoveredServices = services;
    _discoveredPills = pills;
}

- (void)rebuildFavorites
{
    _manualServers = _savedServerList.serverIdentifiers;

    NSMutableArray<VLCFavorite *> *folders = [NSMutableArray array];
    NSInteger serverCount = _favoriteService.numberOfFavoritedServers;

    for (NSInteger server = 0; server < serverCount; server++) {
        NSInteger favoriteCount = [_favoriteService numberOfFavoritesOfServerAtIndex:server];
        for (NSInteger index = 0; index < favoriteCount; index++) {
            VLCFavorite *favorite = [_favoriteService favoriteOfServerWithIndex:server atIndex:index];
            if (!favorite || [favorite.groupIdentifier isEqualToString:VLCFavoriteGroupRadio]) {
                continue;
            }
            [folders addObject:favorite];
        }
    }

    _favoriteFolders = folders;
}

- (void)favoritesDidChange
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self rebuildFavorites];
        [self->_collectionView reloadSections:[NSIndexSet indexSetWithIndex:VLCBrowseSectionFavorites]];
    });
}

- (void)discoveryFoundSomethingNew
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->_reloadScheduled) {
            return;
        }

        self->_reloadScheduled = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kVLCBrowseReloadDebounceInterval * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            self->_reloadScheduled = NO;
            [self reloadDiscoveredSectionIfVisible];
        });
    });
}

- (void)reloadDiscoveredSectionIfVisible
{
    if (!self.isViewLoaded || self.view.window == nil) {
        return;
    }

    [self rebuildDiscoveredServices];
    [_collectionView reloadSections:[NSIndexSet indexSetWithIndex:VLCBrowseSectionNetwork]];
}

- (void)handleRefresh
{
    if ([_discoveryController refreshDiscoveredData]) {
        [self reloadDiscoveredSectionIfVisible];
    }

    [_refreshControl endRefreshing];
}

#pragma mark - layout metrics

- (CGFloat)availableWidth
{
    UIEdgeInsets insets = _collectionView.adjustedContentInset;
    return CGRectGetWidth(_collectionView.bounds) - insets.left - insets.right - 2 * kVLCBrowseGutter;
}

- (NSInteger)tileColumns
{
    CGFloat available = [self availableWidth];
    NSInteger columns = (NSInteger)floor((available + kVLCBrowseTileGap) / (kVLCBrowseMinTileWidth + kVLCBrowseTileGap));
    return MAX(3, columns);
}

- (CGFloat)tileWidth
{
    NSInteger columns = [self tileColumns];
    return floor(([self availableWidth] - kVLCBrowseTileGap * (columns - 1)) / columns);
}

/* the column count follows the size classes rather than the current width, so the chips widen with
 * the window instead of reflowing into a different arrangement. Only a regular height keeps the wide
 * count, which excludes the large phones reporting a regular width in landscape. A window too narrow
 * for the class still falls back to fewer columns. */
- (NSInteger)chipColumns
{
    UITraitCollection *traits = self.traitCollection;
    BOOL isWide = traits.horizontalSizeClass == UIUserInterfaceSizeClassRegular
                  && traits.verticalSizeClass == UIUserInterfaceSizeClassRegular;
    NSInteger columns = isWide ? kVLCBrowseChipColumnsRegular : kVLCBrowseChipColumnsCompact;
    CGFloat available = [self availableWidth];
    NSInteger fitting = (NSInteger)floor((available + kVLCBrowseChipGap) / (kVLCBrowseMinChipWidth + kVLCBrowseChipGap));

    return MAX(kVLCBrowseChipColumnsCompact, MIN(columns, fitting));
}

- (CGFloat)chipWidth
{
    NSInteger columns = [self chipColumns];
    return floor(([self availableWidth] - kVLCBrowseChipGap * (columns - 1)) / columns);
}

/* the L shape only reads as one shape when the sharing chip sits in the trailing column */
- (BOOL)sharingChipIsTrailing
{
    NSInteger columns = [self chipColumns];
    return ((NSInteger)_chips.count - 1) % columns == columns - 1;
}

- (NSArray<NSString *> *)sharingAddresses
{
    return [_httpUploaderController serverAddresses];
}

#pragma mark - collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return VLCBrowseSectionCount;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    switch ((VLCBrowseSection)section) {
        case VLCBrowseSectionNetwork:
            return _discoveredServices.count + 1;
        case VLCBrowseSectionFavorites:
            return _manualServers.count + _favoriteFolders.count;
        case VLCBrowseSectionOpen:
            return _chips.count + (_sharingExpanded ? 1 : 0);
        default:
            return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    switch ((VLCBrowseSection)indexPath.section) {
        case VLCBrowseSectionNetwork:
            return [self discoveredCellForCollectionView:collectionView indexPath:indexPath];
        case VLCBrowseSectionFavorites:
            return [self favoriteCellForCollectionView:collectionView indexPath:indexPath];
        case VLCBrowseSectionOpen:
            return [self openCellForCollectionView:collectionView indexPath:indexPath];
        default:
            return [[UICollectionViewCell alloc] init];
    }
}

- (UICollectionViewCell *)discoveredCellForCollectionView:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath
{
    if ((NSUInteger)indexPath.item >= _discoveredServices.count) {
        VLCAddTile *addTile = [collectionView dequeueReusableCellWithReuseIdentifier:VLCAddTile.reuseIdentifier
                                                                        forIndexPath:indexPath];
        addTile.outlineCornerRadius = kVLCBrowseTileCornerRadius;
        [addTile configureWithTitle:NSLocalizedString(@"BROWSE_ADD_SERVER", nil)];
        return addTile;
    }

    VLCArtworkTile *tile = [collectionView dequeueReusableCellWithReuseIdentifier:VLCArtworkTile.reuseIdentifier
                                                                     forIndexPath:indexPath];
    id<VLCLocalNetworkService> service = _discoveredServices[indexPath.item];

    tile.artworkCornerRadius = kVLCBrowseTileCornerRadius;
    tile.badge = VLCArtworkTileBadgeNone;
    tile.delegate = nil;
    tile.pillText = _discoveredPills[indexPath.item];

    /* never touch service.icon here, it downloads synchronously for VLCMedia backed services */
    NSURL *iconURL = nil;
    if ([service respondsToSelector:@selector(iconURL)]) {
        iconURL = service.iconURL;
    }
    [tile configureWithName:service.title artworkURL:iconURL];

    return tile;
}

- (UICollectionViewCell *)favoriteCellForCollectionView:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath
{
    VLCArtworkTile *tile = [collectionView dequeueReusableCellWithReuseIdentifier:VLCArtworkTile.reuseIdentifier
                                                                     forIndexPath:indexPath];

    tile.artworkCornerRadius = kVLCBrowseTileCornerRadius;
    tile.pillText = nil;
    tile.badgeImage = nil;
    tile.delegate = self;

    NSUInteger item = indexPath.item;
    if (item < _manualServers.count) {
        tile.badge = VLCArtworkTileBadgeServer;
        tile.removalActionTitle = NSLocalizedString(@"BUTTON_DELETE", nil);
        [tile configureWithName:[self titleForManualServerAtIndex:item] artworkURL:nil];
    } else {
        VLCFavorite *favorite = _favoriteFolders[item - _manualServers.count];
        tile.badge = VLCArtworkTileBadgeFolder;
#if TARGET_OS_IOS
        tile.badgeImage = [VLCCloudServiceFactory iconForService:[VLCCloudServiceFactory serviceForURL:favorite.url]];
#endif
        tile.removalActionTitle = NSLocalizedString(@"REMOVE_FAVORITE", nil);
        [tile configureWithName:favorite.userVisibleName artworkURL:favorite.artworkURL];
    }

    return tile;
}

- (UICollectionViewCell *)openCellForCollectionView:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath
{
    if ((NSUInteger)indexPath.item >= _chips.count) {
        VLCBrowseSharingBandCell *band = [collectionView dequeueReusableCellWithReuseIdentifier:VLCBrowseSharingBandCell.reuseIdentifier
                                                                                  forIndexPath:indexPath];
        [band configureWithAddresses:[self sharingAddresses] joinedToChip:[self sharingChipIsTrailing]];
        return band;
    }

    VLCBrowseChip chip = (VLCBrowseChip)_chips[indexPath.item].integerValue;
    if (chip == VLCBrowseChipWiFiSharing) {
        VLCBrowseSharingCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:VLCBrowseSharingCell.reuseIdentifier
                                                                              forIndexPath:indexPath];
        cell.delegate = self;
        [cell configureJoinedToBand:_sharingExpanded && [self sharingChipIsTrailing]];
        return cell;
    }

    VLCBrowseChipCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:VLCBrowseChipCell.reuseIdentifier
                                                                       forIndexPath:indexPath];
    cell.accessibilityIdentifier = [self accessibilityIdentifierForChip:chip];
    [cell configureWithTitle:[self titleForChip:chip] image:[self imageForChip:chip]];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    VLCBrowseSectionHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                       withReuseIdentifier:VLCBrowseSectionHeader.reuseIdentifier
                                                                              forIndexPath:indexPath];
    header.delegate = self;
    [header configureWithTitle:[self titleForSection:(VLCBrowseSection)indexPath.section]
                showsAddButton:indexPath.section == VLCBrowseSectionNetwork];
    return header;
}

#pragma mark - collection view layout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    switch ((VLCBrowseSection)indexPath.section) {
        case VLCBrowseSectionNetwork:
        case VLCBrowseSectionFavorites: {
            CGFloat width = [self tileWidth];
            return CGSizeMake(width, width + kVLCBrowseCaptionArea);
        }
        case VLCBrowseSectionOpen: {
            if ((NSUInteger)indexPath.item >= _chips.count) {
                CGFloat height = [VLCBrowseSharingBandCell heightForAddressCount:[self sharingAddresses].count
                                                                    joinedToChip:[self sharingChipIsTrailing]];
                return CGSizeMake([self availableWidth], height);
            }
            return CGSizeMake([self chipWidth], kVLCBrowseChipHeight);
        }
        default:
            return CGSizeZero;
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    if ([self collectionView:collectionView numberOfItemsInSection:section] == 0) {
        return UIEdgeInsetsZero;
    }

    return UIEdgeInsetsMake(0.0, kVLCBrowseGutter, kVLCBrowseSectionSpacing, kVLCBrowseGutter);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return section == VLCBrowseSectionOpen ? kVLCBrowseChipGap : kVLCBrowseTileGap;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return section == VLCBrowseSectionOpen ? kVLCBrowseChipGap : kVLCBrowseTileGap;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section
{
    if ([self collectionView:collectionView numberOfItemsInSection:section] == 0) {
        return CGSizeZero;
    }

    return CGSizeMake(CGRectGetWidth(collectionView.bounds), VLCBrowseSectionHeader.height);
}

#pragma mark - collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [[ParentalControlCoordinator sharedInstance] authorizeIfParentalControlIsEnabledWithAction:^{
        [self handleSelectionAtIndexPath:indexPath];
    } fail:nil];
}

- (void)handleSelectionAtIndexPath:(NSIndexPath *)indexPath
{
    switch ((VLCBrowseSection)indexPath.section) {
        case VLCBrowseSectionNetwork:
            [self openDiscoveredServiceAtIndex:indexPath.item];
            break;
        case VLCBrowseSectionFavorites:
            [self openFavoriteAtIndex:indexPath.item];
            break;
        case VLCBrowseSectionOpen:
            [self openChipAtIndexPath:indexPath];
            break;
        default:
            break;
    }
}

#pragma mark - discovered servers

- (void)openDiscoveredServiceAtIndex:(NSUInteger)index
{
    if (index >= _discoveredServices.count) {
        [self connectToServer];
        return;
    }

    id<VLCLocalNetworkService> service = _discoveredServices[index];

    if ([service respondsToSelector:@selector(serverBrowser)]) {
        id<VLCNetworkServerBrowser> serverBrowser = [service serverBrowser];
        if (serverBrowser) {
            [self pushBrowser:serverBrowser];
            return;
        }
    }

    if ([service respondsToSelector:@selector(directPlaybackURL)]) {
        NSURL *playbackURL = [service directPlaybackURL];
        if (playbackURL) {
            VLCMediaList *medialist = [[VLCMediaList alloc] init];
            [medialist addMedia:[VLCMedia mediaWithURL:playbackURL]];
            [[VLCPlaybackService sharedInstance] playMediaList:medialist firstIndex:0 subtitlesFilePath:nil];
            return;
        }
    }

    VLCNetworkServerLoginInformation *login = nil;
    if ([service respondsToSelector:@selector(loginInformation)]) {
        login = (VLCNetworkServerLoginInformation *)[service loginInformation];
    }

    if (!login) {
        [VLCAlertViewController alertViewManagerWithTitle:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_TITLE", nil)
                                             errorMessage:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_MESSAGE", nil)
                                           viewController:self];
        return;
    }

    /* UPnP does not support authentication, so skip this step */
    if ([login.protocolIdentifier isEqualToString:VLCNetworkServerProtocolIdentifierUPnP]) {
        [self pushBrowser:[VLCNetworkServerBrowserFactory browserForLogin:login]];
        return;
    }

    NSError *error = nil;
    if (![login loadLoginInformationFromKeychainWithError:&error]) {
        [self showKeychainLoadError:error];
        return;
    }

    [self presentLoginViewControllerWithLogin:login];
}

#pragma mark - favorites

- (NSString *)titleForManualServerAtIndex:(NSUInteger)index
{
    NSURL *url = [NSURL URLWithString:_manualServers[index]];
    if (!url.host) {
        return _manualServers[index];
    }

    if (url.path.length > 0) {
        return [NSString stringWithFormat:@"%@%@", url.host, url.path];
    }

    return url.host;
}

- (void)openFavoriteAtIndex:(NSUInteger)index
{
    if (index < _manualServers.count) {
        NSError *error = nil;
        VLCNetworkServerLoginInformation *login = [_savedServerList loginAtIndex:index error:&error];
        if (!login) {
            [self showKeychainLoadError:error];
            return;
        }

        [self pushBrowser:[VLCNetworkServerBrowserFactory browserForLogin:login]];
        return;
    }

    NSUInteger folderIndex = index - _manualServers.count;
    if (folderIndex >= _favoriteFolders.count) {
        return;
    }

    VLCFavorite *favorite = _favoriteFolders[folderIndex];

    if (favorite.playable) {
        VLCMediaList *mediaList = [[VLCMediaList alloc] init];
        VLCMedia *media = [VLCMedia mediaWithURL:favorite.url];
        if (media) {
            [mediaList addMedia:media];
            [[VLCPlaybackService sharedInstance] playMediaList:mediaList firstIndex:0 subtitlesFilePath:nil];
        }
        return;
    }

#if TARGET_OS_IOS
    UIViewController *cloudBrowser = [VLCCloudServiceFactory browserForURL:favorite.url];
    if (cloudBrowser) {
        [self pushViewController:cloudBrowser];
        return;
    }
#endif

    VLCNetworkServerLoginInformation *login = favorite.loginInformation;
    id<VLCNetworkServerBrowser> browser = nil;

    if ([favorite.protocolIdentifier isEqualToString:VLCNetworkServerProtocolIdentifierUPnP]) {
        browser = [VLCNetworkServerBrowserVLCMedia UPnPNetworkServerBrowserWithURL:favorite.url options:@{}];
    } else if (login) {
        browser = [VLCNetworkServerBrowserFactory browserForLogin:login];
    } else {
        VLCMedia *media = [VLCMedia mediaWithURL:favorite.url];
        if (media) {
            browser = [[VLCNetworkServerBrowserVLCMedia alloc] initWithMedia:media options:@{}];
        }
    }

    [self pushBrowser:browser];
}

- (void)artworkTileDidRequestRemoval:(VLCArtworkTile *)tile
{
    NSIndexPath *indexPath = [_collectionView indexPathForCell:tile];
    if (!indexPath || indexPath.section != VLCBrowseSectionFavorites) {
        return;
    }

    NSUInteger item = indexPath.item;
    if (item < _manualServers.count) {
        [_savedServerList removeServerAtIndex:item error:nil];
    } else {
        [_favoriteService removeFavorite:_favoriteFolders[item - _manualServers.count]];
    }

    [self rebuildFavorites];
    [_collectionView reloadSections:[NSIndexSet indexSetWithIndex:VLCBrowseSectionFavorites]];
}

#pragma mark - open something

- (NSString *)titleForSection:(VLCBrowseSection)section
{
    switch (section) {
        case VLCBrowseSectionNetwork:
            return NSLocalizedString(@"LOCAL_NETWORK", nil);
        case VLCBrowseSectionFavorites:
            return NSLocalizedString(@"FAVORITES", nil);
        case VLCBrowseSectionOpen:
            return NSLocalizedString(@"BROWSE_SECTION_OPEN", nil);
        default:
            return nil;
    }
}

- (NSString *)titleForChip:(VLCBrowseChip)chip
{
    switch (chip) {
        case VLCBrowseChipLocalFiles:
            return NSLocalizedString(@"FILES_APP_CELL_TITLE", nil);
        case VLCBrowseChipPhotos:
            return NSLocalizedString(@"BROWSE_PHOTOS", nil);
        case VLCBrowseChipCloud:
            return NSLocalizedString(@"BROWSE_CLOUD", nil);
        case VLCBrowseChipNetworkStream:
            return NSLocalizedString(@"BROWSE_NETWORK_STREAM", nil);
        case VLCBrowseChipDownloads:
            return NSLocalizedString(@"BROWSE_DOWNLOADS", nil);
        case VLCBrowseChipWiFiSharing:
            return NSLocalizedString(@"BROWSE_WIFI_SHARING", nil);
    }
}

- (UIImage *)imageForChip:(VLCBrowseChip)chip
{
    switch (chip) {
        case VLCBrowseChipLocalFiles:
            return [UIImage imageNamed:@"homeLocalFiles"];
        case VLCBrowseChipPhotos:
            if (@available(iOS 13.0, *)) {
                return [UIImage systemImageNamed:@"photo.on.rectangle"];
            }
            return nil;
        case VLCBrowseChipCloud:
            return [UIImage imageNamed:@"iCloudIcon"];
        case VLCBrowseChipNetworkStream:
            return [UIImage imageNamed:@"OpenNetStream"];
        case VLCBrowseChipDownloads:
            return [UIImage imageNamed:@"Downloads"];
        case VLCBrowseChipWiFiSharing:
            return nil;
    }
}

- (NSString *)accessibilityIdentifierForChip:(VLCBrowseChip)chip
{
    switch (chip) {
        case VLCBrowseChipLocalFiles:
            return VLCAccessibilityIdentifier.local;
        case VLCBrowseChipPhotos:
            return VLCAccessibilityIdentifier.photos;
        case VLCBrowseChipCloud:
            return VLCAccessibilityIdentifier.cloud;
        case VLCBrowseChipNetworkStream:
            return VLCAccessibilityIdentifier.stream;
        case VLCBrowseChipDownloads:
            return VLCAccessibilityIdentifier.downloads;
        case VLCBrowseChipWiFiSharing:
            return nil;
    }
}

- (void)openChipAtIndexPath:(NSIndexPath *)indexPath
{
    if ((NSUInteger)indexPath.item >= _chips.count) {
        return;
    }

    VLCBrowseChip chip = (VLCBrowseChip)_chips[indexPath.item].integerValue;

    switch (chip) {
        case VLCBrowseChipLocalFiles:
            [[VLCDocumentPickerController new] presentFromViewController:self initialDirectory:nil];
            break;
#if TARGET_OS_IOS
        case VLCBrowseChipPhotos:
            if (@available(iOS 14.0, *)) {
                VLCPhotoLibraryController *controller = [[VLCPhotoLibraryController alloc] init];
                _photoLibraryController = controller;
                [controller showPhotoLibraryPicker:[_collectionView cellForItemAtIndexPath:indexPath]];
            }
            break;
        case VLCBrowseChipCloud:
            [self pushViewController:[[VLCCloudServicesTableViewController alloc] initWithNibName:@"VLCCloudServicesTableViewController"
                                                                                           bundle:[NSBundle mainBundle]]];
            break;
#endif
        case VLCBrowseChipNetworkStream:
            [self pushViewController:[[VLCOpenNetworkStreamViewController alloc] init]];
            break;
        case VLCBrowseChipDownloads:
            [self pushViewController:[[VLCTransferViewController alloc] init]];
            break;
        case VLCBrowseChipWiFiSharing: {
            VLCBrowseSharingCell *cell = (VLCBrowseSharingCell *)[_collectionView cellForItemAtIndexPath:indexPath];
            [cell toggleSharing];
            break;
        }
        default:
            break;
    }
}

- (void)sharingCellDidChangeState:(VLCBrowseSharingCell *)cell
{
    [self updateSharingHandoff];

    BOOL expanded = cell.isSharingEnabled;
    if (expanded == _sharingExpanded) {
        return;
    }

    _sharingExpanded = expanded;

    /* the chip keeps its position and only changes its corners, so the L reads as one growing shape */
    [cell configureJoinedToBand:expanded && [self sharingChipIsTrailing]];

    NSIndexPath *bandIndexPath = [NSIndexPath indexPathForItem:_chips.count inSection:VLCBrowseSectionOpen];
    [_collectionView performBatchUpdates:^{
        if (expanded) {
            [self->_collectionView insertItemsAtIndexPaths:@[bandIndexPath]];
        } else {
            [self->_collectionView deleteItemsAtIndexPaths:@[bandIndexPath]];
        }
    } completion:^(BOOL finished) {
        if (expanded) {
            [self->_collectionView scrollToItemAtIndexPath:bandIndexPath
                                          atScrollPosition:UICollectionViewScrollPositionBottom
                                                  animated:YES];
        }
    }];
}

- (void)updateSharingHandoff
{
    BOOL running = _httpUploaderController.isReachable && _httpUploaderController.isServerRunning;
    NSURL *address = running ? [NSURL URLWithString:[_httpUploaderController addressToCopy]] : nil;

    if (!address) {
        [_sharingActivity invalidate];
        _sharingActivity = nil;
        return;
    }

    if ([_sharingActivity.webpageURL isEqual:address]) {
        return;
    }

    [_sharingActivity invalidate];

    _sharingActivity = [[NSUserActivity alloc] initWithActivityType:[[NSBundle mainBundle] bundleIdentifier]];
    _sharingActivity.webpageURL = address;
    _sharingActivity.eligibleForSearch = YES;
    _sharingActivity.eligibleForPublicIndexing = YES;
    _sharingActivity.eligibleForHandoff = YES;
    [_sharingActivity becomeCurrent];
}

#pragma mark - navigation

- (void)pushViewController:(UIViewController *)viewController
{
    if (!viewController || self.navigationController.topViewController == viewController) {
        return;
    }

    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)pushBrowser:(id<VLCNetworkServerBrowser>)browser
{
    if (!browser) {
        return;
    }

    VLCNetworkServerBrowserViewController *controller =
        [[VLCNetworkServerBrowserViewController alloc] initWithServerBrowser:browser
                                                        medialibraryService:_medialibraryService];
    [self pushViewController:controller];
}

- (void)sectionHeaderDidTriggerAction:(VLCBrowseSectionHeader *)header
{
    [self connectToServer];
}

- (void)connectToServer
{
    VLCNetworkServerLoginInformation *login = [[VLCNetworkServerLoginInformation alloc] init];
    [self presentLoginViewControllerWithLogin:login];
}

- (void)presentLoginViewControllerWithLogin:(VLCNetworkServerLoginInformation *)login
{
    VLCNetworkLoginViewController *loginViewController =
        [[VLCNetworkLoginViewController alloc] initWithNibName:@"VLCNetworkLoginViewController" bundle:nil];
    loginViewController.loginInformation = login;
    loginViewController.delegate = self;

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    if (@available(iOS 26.0, *)) {
    } else {
        [navigationController.navigationBar setTranslucent:NO];
    }

    if (loginViewController.navigationItem.leftBarButtonItem == nil) {
        loginViewController.navigationItem.leftBarButtonItem =
            [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                             style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(dismissLogin)];
    }

    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)dismissLogin
{
    if ([self.navigationController presentedViewController]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)loginWithLoginViewController:(VLCNetworkLoginViewController *)loginViewController
                           loginInfo:(VLCNetworkServerLoginInformation *)loginInformation
{
    [self pushBrowser:[VLCNetworkServerBrowserFactory browserForLogin:loginInformation]];
}

- (void)showKeychainLoadError:(NSError *)error
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription
                                                                            message:error.localizedFailureReason
                                                                     preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
        [self connectToServer];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showSettings
{
    [[ParentalControlCoordinator sharedInstance] authorizeIfParentalControlIsEnabledWithAction:^{
        SettingsController *settingsController = [[SettingsController alloc] initWithMediaLibraryService:self->_medialibraryService];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:settingsController];
        [self presentViewController:navigationController animated:YES completion:nil];
    } fail:nil];
}

#pragma mark - appearance

- (void)themeDidChange
{
    _collectionView.backgroundColor = PresentationTheme.current.colors.pageBackground;
    self.navigationController.view.backgroundColor = PresentationTheme.current.colors.pageBackground;

    if (@available(iOS 26.0, *)) {
    } else if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *navigationBarAppearance = [VLCAppearanceManager navigationbarAppearance];
        self.navigationController.navigationBar.standardAppearance = navigationBarAppearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = navigationBarAppearance;
    }

    [_collectionView reloadData];

#if TARGET_OS_IOS
    [self setNeedsStatusBarAppearanceUpdate];
#endif
}

- (void)contentSizeDidChange
{
    [_collectionView.collectionViewLayout invalidateLayout];
    [_collectionView reloadData];
}

- (void)miniPlayerIsShown
{
    _collectionView.contentInset = UIEdgeInsetsMake(0, 0, VLCAudioMiniPlayer.height, 0);
}

- (void)miniPlayerIsHidden
{
    _collectionView.contentInset = UIEdgeInsetsZero;
}

@end
