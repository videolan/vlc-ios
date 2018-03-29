/*****************************************************************************
 * VLCLibraryViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Tamas Timar <ttimar.vlc # gmail.com>
 *          Carola Nitz <nitz.carola # gmail.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLibraryViewController.h"

#import "LXReorderableCollectionViewFlowLayout.h"
#import "VLCActivityViewControllerVendor.h"
#import "VLCAppDelegate.h"
#import "VLCBugreporter.h"
#import "VLCFirstStepsViewController.h"
#import "VLCFolderCollectionViewFlowLayout.h"
#import "VLCMediaDataSource.h"
#import "VLCLibrarySearchDisplayDataSource.h"
#import "VLCMovieViewController.h"
#import "VLCPlaylistCollectionViewCell.h"
#import "VLCPlaylistTableViewCell.h"

#import "VLCPlaybackController+MediaLibrary.h"
#import "VLC_iOS-Swift.h"

#import <CoreSpotlight/CoreSpotlight.h>

/* prefs keys */
static NSString *kDisplayedFirstSteps = @"Did we display the first steps tutorial?";
static NSString *kUsingTableViewToShowData = @"UsingTableViewToShowData";

@implementation EmptyLibraryView

- (IBAction)learnMore:(id)sender
{
    UIViewController *firstStepsVC = [[VLCFirstStepsViewController alloc] initWithNibName:nil bundle:nil];
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:firstStepsVC];
    navCon.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.window.rootViewController presentViewController:navCon animated:YES completion:nil];
}

@end

@interface VLCLibraryViewController () <VLCFolderCollectionViewDelegateFlowLayout, LXReorderableCollectionViewDataSource, LXReorderableCollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate, MLMediaLibrary, VLCMediaListDelegate, UISearchResultsUpdating, UISearchControllerDelegate> {
    VLCLibraryMode _libraryMode;
    VLCLibraryMode _previousLibraryMode;
    UIBarButtonItem *_menuButton;
    NSMutableArray *_indexPaths;
    id _folderObject;
    VLCFolderCollectionViewFlowLayout *_folderLayout;
    LXReorderableCollectionViewFlowLayout *_reorderLayout;
    BOOL _inFolder;
    BOOL _isSelected;
    BOOL _deleteFromTableView;
    UILongPressGestureRecognizer *_longPressGestureRecognizer;

    VLCLibrarySearchDisplayDataSource *_searchDataSource;
    VLCMediaDataSource *_mediaDataSource;

    UISearchController *_searchController;

    UIBarButtonItem *_selectAllBarButtonItem;
    UIBarButtonItem *_createFolderBarButtonItem;
    UIBarButtonItem *_shareBarButtonItem;
    UIBarButtonItem *_removeFromFolderBarButtonItem;
    UIBarButtonItem *_deleteSelectedBarButtonItem;
    
    NSObject *dragAndDropManager;
}

@property (nonatomic, strong) UIBarButtonItem *displayModeBarButtonItem;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) EmptyLibraryView *emptyLibraryView;

@end

@implementation VLCLibraryViewController


+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{kDisplayedFirstSteps : [NSNumber numberWithBool:NO]}];
    [defaults registerDefaults:@{kUsingTableViewToShowData : [NSNumber numberWithBool:UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone]}];
}

- (void)loadView
{
    _mediaDataSource = [VLCMediaDataSource new];
    _searchDataSource = [VLCLibrarySearchDisplayDataSource new];
    self.emptyLibraryView = [[[NSBundle mainBundle] loadNibNamed:@"VLCEmptyLibraryView" owner:self options:nil] lastObject];
    _emptyLibraryView.emptyLibraryLongDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _emptyLibraryView.emptyLibraryLongDescriptionLabel.numberOfLines = 0;
    if (@available(iOS 11.0, *)) {
        dragAndDropManager = [VLCDragAndDropManager new];
        ((VLCDragAndDropManager *)dragAndDropManager).delegate = _mediaDataSource;
        UIDropInteraction *dropInteraction = [[UIDropInteraction alloc] initWithDelegate:(VLCDragAndDropManager *)dragAndDropManager];
        [_emptyLibraryView addInteraction:dropInteraction];
    }
    [self setupContentView];
    [self setViewFromDeviceOrientation];
    [self updateViewsForCurrentDisplayMode];
    _libraryMode = VLCLibraryModeAllFiles;
}

- (void)setupContentView
{
    CGRect viewDimensions = [UIApplication sharedApplication].keyWindow.bounds;
    UIView *contentView = [[UIView alloc] initWithFrame:viewDimensions];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    contentView.backgroundColor = [UIColor VLCDarkBackgroundColor];

    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:viewDimensions style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor VLCDarkBackgroundColor];
        CGRect frame = _tableView.bounds;
        frame.origin.y = -frame.size.height;
        UIView *topView = [[UIView alloc] initWithFrame:frame];
        topView.backgroundColor = [UIColor VLCDarkBackgroundColor];
        [_tableView addSubview:topView];
        _tableView.rowHeight = [VLCPlaylistTableViewCell heightOfCell];
        _tableView.separatorColor = [UIColor VLCDarkBackgroundColor];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        if (@available(iOS 11.0, *)) {
            _tableView.dragDelegate = ((VLCDragAndDropManager *)dragAndDropManager);
            _tableView.dropDelegate = ((VLCDragAndDropManager *)dragAndDropManager);
        } else {
            _tableView.tableHeaderView = _searchController.searchBar;
        }
        UINib *nib = [UINib nibWithNibName:@"VLCPlaylistTableViewCell" bundle:nil];
        [_tableView registerNib:nib forCellReuseIdentifier:VLCPlaylistTableViewCell.cellIdentifier];
    }
    _tableView.frame = contentView.bounds;
    [_tableView reloadData];

    if (!_collectionView) {
        _folderLayout = [[VLCFolderCollectionViewFlowLayout alloc] init];
        _reorderLayout = [[LXReorderableCollectionViewFlowLayout alloc] init];
        _collectionView = [[UICollectionView alloc] initWithFrame:viewDimensions collectionViewLayout:_folderLayout];
        _collectionView.alwaysBounceVertical = YES;
        if (@available(iOS 11.0, *)) {
            _collectionView.dragDelegate = ((VLCDragAndDropManager *)dragAndDropManager);
            _collectionView.dropDelegate = ((VLCDragAndDropManager *)dragAndDropManager);
        }
        _collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor VLCDarkBackgroundColor];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_collectionViewHandleLongPressGesture:)];
        [_collectionView addGestureRecognizer:_longPressGestureRecognizer];
        [_collectionView registerNib:[UINib nibWithNibName:@"VLCPlaylistCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:VLCPlaylistCollectionViewCell.cellIdentifier];
    }
    _collectionView.frame = contentView.bounds;
    [_collectionView reloadData];
    if (self.usingTableViewToShowData) {
        [contentView addSubview:_tableView];
        if (@available(iOS 11.0, *))
            [self setSearchBar:YES resetContent:NO];
    } else {
        [contentView addSubview:_collectionView];
        [_searchController setActive:NO];
        if (@available(iOS 11.0, *))
            [self setSearchBar:NO resetContent:NO];
    }
    self.view = contentView;
}

#pragma mark -

- (void)viewWillLayoutSubviews {
    UIScrollView *dataView = self.usingTableViewToShowData ? _tableView : _collectionView;

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    [dataView setContentInset:UIEdgeInsetsZero];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"LIBRARY_ALL_FILES", nil);
    self.navigationItem.leftBarButtonItem = _menuButton;

    self.editButtonItem.title = NSLocalizedString(@"BUTTON_EDIT", nil);
    self.editButtonItem.tintColor = [UIColor whiteColor];

    _selectAllBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_ALL", nil) style:UIBarButtonItemStylePlain target:self action:@selector(handleSelection)];
    _selectAllBarButtonItem.tintColor = [UIColor whiteColor];
    UIFont *font = [UIFont boldSystemFontOfSize:17];
    NSDictionary *attributes = @{NSFontAttributeName: font};
    [_selectAllBarButtonItem setTitleTextAttributes:attributes forState:UIControlStateNormal];

    _emptyLibraryView.emptyLibraryLabel.text = NSLocalizedString(@"EMPTY_LIBRARY", nil);
    _emptyLibraryView.emptyLibraryLongDescriptionLabel.text = NSLocalizedString(@"EMPTY_LIBRARY_LONG", nil);
    [_emptyLibraryView.emptyLibraryLongDescriptionLabel sizeToFit];
    [_emptyLibraryView.learnMoreButton setTitle:NSLocalizedString(@"BUTTON_LEARN_MORE", nil) forState:UIControlStateNormal];
    _createFolderBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(createFolder)];

    // Better visual alignment with the action button
    _createFolderBarButtonItem.imageInsets = UIEdgeInsetsMake(3, 0, -3, 0);
    _createFolderBarButtonItem.landscapeImagePhoneInsets = UIEdgeInsetsMake(2, 0, -2, 0);

    _removeFromFolderBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(removeFromFolder)];
    _removeFromFolderBarButtonItem.imageInsets = UIEdgeInsetsMake(2, 0, -2, 0);
    _removeFromFolderBarButtonItem.landscapeImagePhoneInsets = UIEdgeInsetsMake(1, 0, -1, 0);
    _removeFromFolderBarButtonItem.enabled = NO;

    _shareBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share:)];
    _shareBarButtonItem.enabled = NO;

    _deleteSelectedBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteSelection:)];
    _deleteFromTableView = NO;

    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 20;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        fixedSpace.width *= 2;
    }

    [self setToolbarItems:@[_shareBarButtonItem,
                            fixedSpace,
                            _createFolderBarButtonItem,
                            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            [UIBarButtonItem themedDarkToolbarButtonWithTitle:NSLocalizedString(@"BUTTON_RENAME", nil) target:self andSelector:@selector(renameSelection)],
                            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            _removeFromFolderBarButtonItem,
                            fixedSpace,
                            _deleteSelectedBarButtonItem]];
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    self.navigationController.toolbar.tintColor = [UIColor whiteColor];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;

    self.edgesForExtendedLayout = UIRectEdgeNone;

    [self setupSearchController];
}

- (void)setupSearchController
{
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.dimsBackgroundDuringPresentation = NO;
    _searchController.delegate = self;
    [self setSearchBar:YES resetContent:YES];
    if (!self.usingTableViewToShowData) {
        if (@available(iOS 11.0, *))
            [self setSearchBar:NO resetContent:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self setViewFromDeviceOrientation];
    [self updateViewsForCurrentDisplayMode];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![[defaults objectForKey:kDisplayedFirstSteps] boolValue]) {
        [self.emptyLibraryView performSelector:@selector(learnMore:) withObject:nil afterDelay:1.];
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:kDisplayedFirstSteps];
    }

    if ([_mediaDataSource numberOfFiles] < 1)
        [self updateViewContents];
    [[MLMediaLibrary sharedMediaLibrary] performSelector:@selector(libraryDidAppear) withObject:nil afterDelay:1.];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[MLMediaLibrary sharedMediaLibrary] libraryDidDisappear];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
        [[VLCBugreporter sharedInstance] handleBugreportRequest];
}

- (void)openMediaObject:(NSManagedObject *)mediaObject
{
    if ([mediaObject isKindOfClass:[MLAlbum class]] || [mediaObject isKindOfClass:[MLShow class]]) {
        [_mediaDataSource updateContentsForSelection:mediaObject];
        BOOL isAlbum = [mediaObject isKindOfClass:[MLAlbum class]];

        self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(backToAllItems:)];
        if (_libraryMode == VLCLibraryModeAllFiles)
            self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"BUTTON_BACK", nil);
        else
            [self.navigationItem.leftBarButtonItem setTitle: isAlbum ? NSLocalizedString(@"LIBRARY_MUSIC", nil) : NSLocalizedString(@"LIBRARY_SERIES", nil)];
        self.title = [(MLAlbum*)mediaObject name];
        [self reloadViews];
    } else if ([mediaObject isKindOfClass:[MLLabel class]]) {
        [_mediaDataSource updateContentsForSelection:mediaObject];
        _inFolder = YES;
        if (!self.usingTableViewToShowData) {
            if (@available(iOS 11.0, *)) {
            } else {
                if (![self.collectionView.collectionViewLayout isEqual:_reorderLayout]) {
                    for (UIGestureRecognizer *recognizer in _collectionView.gestureRecognizers) {
                        if (recognizer == _folderLayout.panGestureRecognizer || recognizer == _folderLayout.longPressGestureRecognizer || recognizer == _longPressGestureRecognizer)
                            [self.collectionView removeGestureRecognizer:recognizer];
                    }
                    //reloadData before setting a new layout avoids a crash deep in UIKits UICollectionViewData layoutattributs
                    [self.collectionView reloadData];
                    [self.collectionView setCollectionViewLayout:_reorderLayout animated:NO];
                }
            }
        }
        _libraryMode = VLCLibraryModeFolder;

        self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(backToAllItems:)];
        self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"BUTTON_BACK", nil);
        self.title = [(MLLabel*)mediaObject name];

        _removeFromFolderBarButtonItem.enabled = YES;
        _createFolderBarButtonItem.enabled = NO;

        [self reloadViews];
        return;
    } else {
        VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
        [vpc playMediaLibraryObject:mediaObject];

        [self createSpotlightItem:mediaObject];
    }
}

- (void)createSpotlightItem:(nonnull NSManagedObject *)mediaObject
{
    if (![VLCKeychainCoordinator passcodeLockEnabled]) {
        self.userActivity = [[NSUserActivity alloc] initWithActivityType:kVLCUserActivityPlaying];

        MLFile *file = nil;
        if ([mediaObject isKindOfClass:[MLAlbumTrack class]]) {
            file = [(MLAlbumTrack *)mediaObject anyFileFromTrack];
        } else if ([mediaObject isKindOfClass:[MLShowEpisode class]]) {
            file = [(MLShowEpisode *)mediaObject anyFileFromEpisode];
        } else if ([mediaObject isKindOfClass:[MLFile class]]){
            file = (MLFile *)mediaObject;
        }
        self.userActivity.title = file.title;
        self.userActivity.contentAttributeSet = file.coreSpotlightAttributeSet;
        self.userActivity.userInfo = @{@"playingmedia":mediaObject.objectID.URIRepresentation};

        self.userActivity.eligibleForSearch = YES;
        self.userActivity.eligibleForHandoff = YES;
        //self.userActivity.contentUserAction = NSUserActivityContentUserActionPlay;
        [self.userActivity becomeCurrent];
    }
}

- (void)removeMediaObject:(id)managedObject updateDatabase:(BOOL)updateDB
{
    [_mediaDataSource removeMediaObject:managedObject];

    if (updateDB) {
        [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
        [self updateViewContents];
    }
}

- (void)_displayEmptyLibraryViewIfNeeded
{
    if (self.emptyLibraryView.superview)
        [self.emptyLibraryView removeFromSuperview];

    if ([_mediaDataSource numberOfFiles] == 0) {
        _inFolder = (_libraryMode == VLCLibraryModeFolder || _libraryMode == VLCLibraryModeCreateFolder);
        self.emptyLibraryView.emptyLibraryLabel.text = _inFolder ? NSLocalizedString(@"FOLDER_EMPTY", nil) : NSLocalizedString(@"EMPTY_LIBRARY", nil);
        self.emptyLibraryView.emptyLibraryLongDescriptionLabel.text = _inFolder ? NSLocalizedString(@"FOLDER_EMPTY_LONG", nil) : NSLocalizedString(@"EMPTY_LIBRARY_LONG", nil);
        self.emptyLibraryView.learnMoreButton.hidden = _inFolder;
        self.emptyLibraryView.frame = self.view.bounds;
        [self.view addSubview:self.emptyLibraryView];
        self.navigationItem.rightBarButtonItems = nil;
    } else {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            UIBarButtonItem *toggleDisplayedView = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tableViewIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleDisplayedView:)];
            self.navigationItem.rightBarButtonItems = @[toggleDisplayedView, self.editButtonItem];
            self.displayModeBarButtonItem = toggleDisplayedView;
        } else {
            self.navigationItem.rightBarButtonItem = self.editButtonItem;
        }
    }
    if (self.usingTableViewToShowData) {
        _tableView.separatorStyle = [_mediaDataSource numberOfFiles] > 0 ? UITableViewCellSeparatorStyleSingleLine:
                                                             UITableViewCellSeparatorStyleNone;
    } else {
        [self.collectionView.collectionViewLayout invalidateLayout];
    }
    [self updateViewsForCurrentDisplayMode];
}

- (void)setViewFromDeviceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        BOOL isPortrait = YES;

        if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact)
            isPortrait = NO;

        [self setUsingTableViewToShowData:isPortrait];
        [self _displayEmptyLibraryViewIfNeeded];
    }
}

- (void)setSearchBar:(BOOL)enable resetContent:(BOOL)resetContent
{
    if (@available(iOS 11.0, *)) {
        _searchController.dimsBackgroundDuringPresentation = NO;
        [_searchController.searchBar sizeToFit];

        // search bar text field background color
        UITextField *searchTextField = [_searchController.searchBar valueForKey:@"searchField"];
        UIView *backgroundView = searchTextField.subviews.firstObject;
        backgroundView.backgroundColor = UIColor.whiteColor;
        backgroundView.layer.cornerRadius = 10;
        backgroundView.clipsToBounds = YES;

        _searchController.hidesNavigationBarDuringPresentation = NO;
        _searchController.obscuresBackgroundDuringPresentation = NO;
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
        self.navigationItem.searchController = enable ? _searchController : nil;
        self.definesPresentationContext = YES;
    } else {
        _tableView.tableHeaderView = enable ? _searchController.searchBar : nil;
        if (resetContent) {
            CGPoint contentOffset = _tableView.contentOffset;
            contentOffset.y += CGRectGetHeight(_tableView.tableHeaderView.frame);
            _tableView.contentOffset = contentOffset;
        }
    }
}

- (void)libraryUpgradeComplete
{
    self.title = NSLocalizedString(@"LIBRARY_ALL_FILES", nil);
    self.navigationItem.leftBarButtonItem = _menuButton;
    self.emptyLibraryView.emptyLibraryLongDescriptionLabel.hidden = NO;
    self.emptyLibraryView.emptyLibraryLabel.text = NSLocalizedString(@"EMPTY_LIBRARY", nil);
    [self.emptyLibraryView.activityIndicator stopAnimating];
    [self.emptyLibraryView removeFromSuperview];

    [self updateViewContents];
}

- (void)updateViewContents
{
    self.navigationItem.leftBarButtonItem = _menuButton;
    [_mediaDataSource updateContentsForSelection:nil];
    _removeFromFolderBarButtonItem.enabled = NO;

    switch (_libraryMode) {
        case VLCLibraryModeAllAlbums: {
            self.title = NSLocalizedString(@"LIBRARY_MUSIC", nil);
            _createFolderBarButtonItem.enabled = NO;
            [_mediaDataSource addAlbumsInAllAlbumMode:YES];
        } break;
        case VLCLibraryModeAllSeries: {
            self.title = NSLocalizedString(@"LIBRARY_SERIES", nil);
            _createFolderBarButtonItem.enabled = NO;
            [_mediaDataSource addAllShows];
        } break;
        //TODO: I'm not sure if updateViewContents should be called in VLCLibraryModeFolder
        //Here should maybe be an NSAssert to prevent this but for now due to refactoring these calls would've been made in that case
        case VLCLibraryModeAllFiles:
        case VLCLibraryModeFolder:
        case VLCLibraryModeCreateFolder: {
            self.title = NSLocalizedString(@"LIBRARY_ALL_FILES", nil);
            _createFolderBarButtonItem.enabled = YES;

            [_mediaDataSource addAlbumsInAllAlbumMode:NO];
            [_mediaDataSource addAllShows];
            [_mediaDataSource addAllFolders];
            [_mediaDataSource addRemainingFiles];
        }
    }
    [self reloadViews];
}

- (void)reloadViews
{
    // Since this gets can get called at any point and wipe away the selections, we update the actionBarButtonItem here because this can happen if you tap "Save Video" in the UIActivityController and a media access alert view takes away focus (the corresponding 'became active' notification of UIApplication will call this). Or simply try bringing down the notification center to trigger this. Any existing UIActivityViewController session should be safe as it would have copies of the selected file references.
    if (self.usingTableViewToShowData) {
        [self.tableView reloadData];
        [self updateActionBarButtonItemStateWithSelectedIndexPaths:[self.tableView indexPathsForSelectedRows]];
        _isSelected = NO;
    } else {
        [self.collectionView reloadData];

        [self updateActionBarButtonItemStateWithSelectedIndexPaths:[self.collectionView indexPathsForSelectedItems]];
        if (_libraryMode == VLCLibraryModeAllFiles) {
            if (self.collectionView.collectionViewLayout != _folderLayout) {
                for (UIGestureRecognizer *recognizer in _collectionView.gestureRecognizers) {
                    if (recognizer == _reorderLayout.panGestureRecognizer ||
                        recognizer == _reorderLayout.longPressGestureRecognizer) {
                        [self.collectionView removeGestureRecognizer:recognizer];
                    }
                }
                [self.collectionView setCollectionViewLayout:_folderLayout animated:NO];
                [self.collectionView addGestureRecognizer:_longPressGestureRecognizer];
            }
        }
    }

    [self _displayEmptyLibraryViewIfNeeded];
}

#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_mediaDataSource numberOfFiles];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaylistTableViewCell *cell = (VLCPlaylistTableViewCell *)[tableView dequeueReusableCellWithIdentifier:VLCPlaylistTableViewCell.cellIdentifier];

    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRightOnTableViewCellGestureAction:)];
    [swipeRight setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [cell addGestureRecognizer:swipeRight];

    cell.mediaObject = [_mediaDataSource objectAtIndex:indexPath.row];

    return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [_mediaDataSource moveObjectFromIndex:fromIndexPath.item toIndex:toIndexPath.item];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (@available(iOS 11.0, *)) {
        return true;
    }
    return _inFolder;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (@available(iOS 11.0, *)) {
        return true;
    }
    return _inFolder;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor VLCDarkBackgroundColor];
    cell.multipleSelectionBackgroundView.backgroundColor = cell.backgroundColor;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSInteger row = indexPath.row;
        _deleteFromTableView = YES;
        if (row < [_mediaDataSource numberOfFiles])
            [self deleteSelection:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.isEditing) {
        [self updateActionBarButtonItemStateWithSelectedIndexPaths:[tableView indexPathsForSelectedRows]];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaylistTableViewCell *playlistTableViewCell = (VLCPlaylistTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    if ([playlistTableViewCell isExpanded]) {
        [playlistTableViewCell collapsWithAnimation:YES];
        return;
    }

    for (VLCPlaylistTableViewCell *cell in [tableView visibleCells]) {
        if ([cell isExpanded])
            [cell collapsWithAnimation:NO];
    }

    if (tableView.isEditing) {
        if (_libraryMode == VLCLibraryModeCreateFolder) {
            _folderObject = [_mediaDataSource objectAtIndex:indexPath.row];
            _libraryMode = _previousLibraryMode;
            [self updateViewContents];
            [self createFolderWithName:nil];
        } else {
            [self updateActionBarButtonItemStateWithSelectedIndexPaths:[tableView indexPathsForSelectedRows]];
        }
        return;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    [self openMediaObject:playlistTableViewCell.mediaObject];
}

#pragma mark - Gesture Action
- (void)swipeRightOnTableViewCellGestureAction:(UIGestureRecognizer *)recognizer
{
    [self setEditing:!self.tableView.isEditing animated:YES];
    if (!self.tableView.isEditing) {
        NSIndexPath *path = [self.tableView indexPathForRowAtPoint:[recognizer locationInView:self.tableView]];
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:path.row inSection:path.section]
                                animated:YES
                          scrollPosition:UITableViewScrollPositionNone];
        [self updateActionBarButtonItemStateWithSelectedIndexPaths:[self.tableView indexPathsForSelectedRows]];
    }
}

- (void)swipeRightOnCollectionViewCellGestureAction:(UIGestureRecognizer *)recognizer
{
    NSIndexPath *path = [self.collectionView indexPathForItemAtPoint:[recognizer locationInView:self.collectionView]];
    VLCPlaylistCollectionViewCell *cell = (VLCPlaylistCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:path];
    [cell showMetadata:!cell.showsMetaData];
}

#pragma mark - Collection View
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_mediaDataSource numberOfFiles];
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaylistCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:VLCPlaylistCollectionViewCell.cellIdentifier forIndexPath:indexPath];

    cell.mediaObject = [_mediaDataSource objectAtIndex:indexPath.row];

    cell.collectionView = _collectionView;

    [cell setEditing:self.editing animated:NO];

    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRightOnCollectionViewCellGestureAction:)];
    [swipeRight setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [cell addGestureRecognizer:swipeRight];

    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    const CGFloat maxCellWidth = [UIScreen mainScreen].bounds.size.width / 3;
    const CGFloat aspectRatio = 9.0/16.0;

    CGRect windowFrame = [UIApplication sharedApplication].keyWindow.frame;
    CGFloat windowWidth = windowFrame.size.width;

    int numberOfCellsPerRow = ceil(windowWidth/maxCellWidth);
    CGFloat cellWidth = windowWidth/numberOfCellsPerRow;
    cellWidth -= 5;

    return CGSizeMake(cellWidth, cellWidth * aspectRatio);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(5, 5, 5, 5);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 2.5;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing) {
        if (_libraryMode == VLCLibraryModeCreateFolder) {
            _folderObject = [_mediaDataSource objectAtIndex:indexPath.item];
            [self updateViewContents];
            [self createFolderWithName:nil];
             _libraryMode = _previousLibraryMode;
        } else {
            [self updateActionBarButtonItemStateWithSelectedIndexPaths:[collectionView indexPathsForSelectedItems]];
        }
        [(VLCPlaylistCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath] selectionUpdate];
        return;
    }

    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    NSArray *visibleCells = [[collectionView visibleCells] copy];
    NSUInteger cellCount = visibleCells.count;

    for (NSUInteger x = 0; x < cellCount; x++) {
        VLCPlaylistCollectionViewCell *cell = visibleCells[x];
        if ([cell showsMetaData])
            [cell showMetadata:NO];
    }

    NSManagedObject *selectedObject = [_mediaDataSource objectAtIndex:indexPath.row];

    if (selectedObject != nil)
        [self openMediaObject:selectedObject];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing) {
        [self updateActionBarButtonItemStateWithSelectedIndexPaths:[collectionView indexPathsForSelectedItems]];
    }

    [(VLCPlaylistCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath] selectionUpdate];
}

- (void)collectionView:(UICollectionView *)collectionView removeItemFromFolderAtIndexPathIfNeeded:(NSIndexPath *)indexPath
{
    id mediaObject = [_mediaDataSource objectAtIndex:indexPath.item];

    [_mediaDataSource removeMediaObjectFromFolder:mediaObject];

    [self backToAllItems:nil];
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath
{
    [_mediaDataSource moveObjectFromIndex:fromIndexPath.item toIndex:toIndexPath.item];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSpringLoadItemAtIndexPath:(NSIndexPath *)indexPath withContext:(id<UISpringLoadedInteractionContext>)context NS_AVAILABLE_IOS(11.0)
{
    id mediaObject = [_mediaDataSource objectAtIndex:indexPath.item];
    return [mediaObject isKindOfClass:[MLLabel class]];
}

- (void)collectionView:(UICollectionView *)collectionView requestToMoveItemAtIndexPath:(NSIndexPath *)itemPath intoFolderAtIndexPath:(NSIndexPath *)folderPath
{
    id folderPathItem = [_mediaDataSource objectAtIndex:folderPath.item];
    id itemPathItem = [_mediaDataSource objectAtIndex:itemPath.item];

    BOOL validFileTypeAtFolderPath = ([folderPathItem isKindOfClass:[MLFile class]] || [folderPathItem isKindOfClass:[MLLabel class]]) && [itemPathItem isKindOfClass:[MLFile class]];

    if (!validFileTypeAtFolderPath) {
        VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"FOLDER_INVALID_TYPE_TITLE", nil) message:NSLocalizedString(@"FOLDER_INVALID_TYPE_MESSAGE", nil) cancelButtonTitle:nil otherButtonTitles:@[NSLocalizedString(@"BUTTON_OK", nil)]];

        alert.completion = ^(BOOL cancelled, NSInteger buttonIndex) {
            [self updateViewContents];
        };
        [alert show];
        return;
    }

    BOOL isFolder = [folderPathItem isKindOfClass:[MLLabel class]];

    if (isFolder){
        MLLabel *folder = folderPathItem;
        MLFile *file = itemPathItem;
        [file setLabels:[[NSSet alloc] initWithObjects:folder, nil]];
        file.folderTrackNumber = @([folder.files count] - 1);
        [_mediaDataSource removeObjectAtIndex:itemPath.item];
        [self updateViewContents];
    } else {
        _folderObject = folderPathItem;
        _indexPaths = [NSMutableArray arrayWithArray:@[itemPath]];
        [self showCreateFolderAlert];
    }
}

#pragma mark - collection/tableView helper
- (NSArray *)selectedIndexPaths
{
    NSArray *indexPaths;
    if (self.usingTableViewToShowData)
        indexPaths = [self.tableView indexPathsForSelectedRows];
    else
        indexPaths = [self.collectionView indexPathsForSelectedItems];

    return indexPaths ?: [NSArray array];
}
#pragma mark - Folder implementation

- (void)showCreateFolderAlert
{
    VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"FOLDER_CHOOSE_NAME_TITLE", nil) message:NSLocalizedString(@"FOLDER_CHOOSE_NAME_MESSAGE", nil) cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:@[NSLocalizedString(@"BUTTON_SAVE", nil)]];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    UITextField *zeroTextField = [alert textFieldAtIndex:0];
    [zeroTextField setText:NSLocalizedString(@"FOLDER_NAME_PLACEHOLDER", nil)];
    [zeroTextField setClearButtonMode:UITextFieldViewModeAlways];

    __weak VLCAlertView *weakAlert = alert;
    alert.completion = ^(BOOL cancelled, NSInteger buttonIndex) {
        if (cancelled)
            [self updateViewContents];
        else
            [self createFolderWithName:[weakAlert textFieldAtIndex:0].text];
    };
    [alert show];
}

- (void)createFolder
{
    if (_libraryMode == VLCLibraryModeCreateFolder) {
        _libraryMode = _previousLibraryMode;
        [self updateViewContents];
        [self showCreateFolderAlert];
        return;
    }

    _indexPaths = [NSMutableArray arrayWithArray:[self selectedIndexPaths]];

    for (NSInteger i = _indexPaths.count - 1; i >=0; i--) {
        NSIndexPath *path = _indexPaths[i];
        id mediaObject = [_mediaDataSource objectAtIndex:path.row];
        if ([mediaObject isKindOfClass:[MLLabel class]])
            [_indexPaths removeObject:path];
    }

    if ([_indexPaths count] != 0) {
        NSArray *folder = [MLLabel allLabels];
        //if we already have folders display them
        if ([folder count] > 0) {
            [_mediaDataSource updateContentsForSelection:nil];
            [_mediaDataSource addAllFolders];
            self.title = NSLocalizedString(@"SELECT_FOLDER", nil);
            _previousLibraryMode = _libraryMode;
            _libraryMode = VLCLibraryModeCreateFolder;
            [self reloadViews];
            return;
        }
    }
    //no selected items or no existing folder ask for foldername
    [self showCreateFolderAlert];
}

- (void)removeFromFolder
{
    _indexPaths = [NSMutableArray arrayWithArray:[self selectedIndexPaths]];

    [_indexPaths sortUsingSelector:@selector(compare:)];

    for (NSInteger i = [_indexPaths count] - 1; i >= 0; i--) {
        NSIndexPath *path = _indexPaths[i];
        id item = [_mediaDataSource objectAtIndex:path.row];

        [_mediaDataSource removeMediaObjectFromFolder:item];
        [_mediaDataSource removeObjectAtIndex:path.row];
    }
    [self reloadViews];
}

- (void)createFolderWithName:(NSString *)folderName
{
    NSArray *labels = [MLLabel allLabels];
    for (MLLabel *label in labels){
        if ([label.name isEqualToString:folderName]) {
            _folderObject = nil;
            _indexPaths = nil;
            VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"FOLDER_NAME_DUPLICATE_TITLE", nil) message:NSLocalizedString(@"FOLDER_NAME_DUPLICATE_MESSAGE", nil) cancelButtonTitle:nil otherButtonTitles:@[NSLocalizedString(@"BUTTON_OK", nil)]];

            alert.completion = ^(BOOL cancelled, NSInteger buttonIndex) {
                [self updateViewContents];
            };
            [alert show];
            return;
        }
    }

    if (_folderObject != nil) {
        id mediaObject;
        NSUInteger folderIndex = [_mediaDataSource indexOfObject:_folderObject];
        if (folderIndex != NSNotFound) {
            mediaObject = [_mediaDataSource objectAtIndex:folderIndex];
        }

        //item got dragged onto item
        if ([mediaObject isKindOfClass:[MLFile class]]) {
            MLFile *file = (MLFile *)mediaObject;
            MLLabel *label = [[MLMediaLibrary sharedMediaLibrary] createObjectForEntity:@"Label"];
            label.name = folderName;

            file.labels = [NSSet setWithObjects:label,nil];
            NSNumber *folderTrackNumber = [NSNumber numberWithInt:(int)[label files].count - 1];
            file.folderTrackNumber = folderTrackNumber;

            [_mediaDataSource removeObjectAtIndex:folderIndex];
            [_mediaDataSource insertObject:label atIndex:folderIndex];
            id item = [_mediaDataSource objectAtIndex:((NSIndexPath *)_indexPaths[0]).item];

            if (![item isKindOfClass:[MLFile class]])
                return;

            MLFile *itemFile = (MLFile *)item;
            itemFile.labels = file.labels;
            [_mediaDataSource removeObjectAtIndex:((NSIndexPath *)_indexPaths[0]).item];

            itemFile.folderTrackNumber = @([label files].count - 1);
        } else {
            //item got dragged onto folder or items should be added to folder
            id label = [_mediaDataSource objectAtIndex:folderIndex];
            if (![label isKindOfClass:[MLLabel class]])
                return;

            [_indexPaths sortUsingSelector:@selector(compare:)];

            NSUInteger count = [_mediaDataSource numberOfFiles];
            for (NSInteger i = [_indexPaths count] - 1; i >= 0; i--) {
                NSIndexPath *path = _indexPaths[i];
                if (path.row >= count)
                    continue;
                id object = [_mediaDataSource objectAtIndex:path.row];
                if (_libraryMode != VLCLibraryModeCreateFolder && ![object isKindOfClass:[MLFile class]])
                    continue;
                if (_libraryMode == VLCLibraryModeCreateFolder)
                    [self updateViewContents];

                id item = [_mediaDataSource objectAtIndex:path.row];

                if (![item isKindOfClass:[MLFile class]])
                    continue;

                MLFile *file = (MLFile *)item;
                file.labels = [NSSet setWithObjects:label, nil];
                [_mediaDataSource removeObjectAtIndex:path.row];

                file.folderTrackNumber = @([label files].count - 1);
            }
        }
        _folderObject = nil;
    } else {
        //create new folder
        MLLabel *label = [[MLMediaLibrary sharedMediaLibrary] createObjectForEntity:@"Label"];
        label.name = folderName;

        //if items were selected
        if ([_indexPaths count] != 0) {
            [_indexPaths sortUsingSelector:@selector(compare:)];

            for (NSInteger i = [_indexPaths count] - 1; i >= 0; i--) {
                NSIndexPath *path = _indexPaths[i];
                NSUInteger index = self.usingTableViewToShowData ? path.row : path.item;
                if (index < [_mediaDataSource numberOfFiles]) {
                    id item = [_mediaDataSource objectAtIndex:index];
                    if (![item isKindOfClass:[MLFile class]])
                        continue;

                    MLFile *file = (MLFile *)item;
                    file.labels = [NSSet setWithObjects:label, nil];
                    file.folderTrackNumber = @([label files].count - 1);
                    [_mediaDataSource removeObjectAtIndex:index];
                }
            }
        }
    }
    _indexPaths = nil;
    [self setEditing:NO];
    [self updateViewContents];
}

- (void)_collectionViewHandleLongPressGesture:(UIGestureRecognizer *) sender
{
    if (sender.state == UIGestureRecognizerStateBegan && !self.isEditing)
        [self setEditing:YES animated:YES];
}

#pragma mark - UI implementation
- (void)handleSelection
{
    if (self.usingTableViewToShowData) {
        NSInteger numberOfSections = [self.tableView numberOfSections];

        for (NSInteger section = 0; section < numberOfSections; section++) {
            NSInteger numberOfRowInSection = [self.tableView numberOfRowsInSection:section];

            for (NSInteger row = 0; row < numberOfRowInSection; row++) {
                if (!_isSelected)
                    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section] animated:NO scrollPosition:UITableViewScrollPositionNone];
                else
                    [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section] animated:NO];
            }
        }
    } else {
        NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];

        for (NSInteger item = 0; item < numberOfItems; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:item inSection:0];

            if (!_isSelected)
                [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            else
                [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
            [(VLCPlaylistCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath] selectionUpdate];
        }
    }
    _isSelected = !_isSelected;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    _isSelected = NO;

    UIBarButtonItem *editButton = self.editButtonItem;
    editButton.tintColor = [UIColor whiteColor];

    if (!editing && self.navigationItem.rightBarButtonItems.lastObject == _selectAllBarButtonItem)
        [self.navigationItem setRightBarButtonItems: [self.navigationItem.rightBarButtonItems subarrayWithRange:NSMakeRange(0, self.navigationItem.rightBarButtonItems.count - 1)]];
    else
        [self.navigationItem setRightBarButtonItems:editing ? [self.navigationItem.rightBarButtonItems arrayByAddingObject:_selectAllBarButtonItem] : [self.navigationItem rightBarButtonItems] animated:YES];

    [self setSearchBar:!editing resetContent:!editing];
    self.tableView.allowsMultipleSelectionDuringEditing = editing;
    [self.tableView setEditing:editing animated:YES];

    NSArray *visibleCells = self.collectionView.visibleCells;
    [visibleCells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        VLCPlaylistCollectionViewCell *aCell = (VLCPlaylistCollectionViewCell*)obj;
        [aCell setEditing:editing animated:animated];
    }];

    self.collectionView.allowsMultipleSelection = editing;

    /* UIKit doesn't clear the selection automagically if we leave the editing mode
     * so we need to do so manually */
    if (!editing) {
        [self.collectionView addGestureRecognizer:_longPressGestureRecognizer];
        NSArray *selectedItems = [self.collectionView indexPathsForSelectedItems];
        NSUInteger count = selectedItems.count;

        for (NSUInteger x = 0; x < count; x++)
            [self.collectionView deselectItemAtIndexPath:selectedItems[x] animated:NO];
    } else
        [self.collectionView removeGestureRecognizer:_longPressGestureRecognizer];

    if (_libraryMode == VLCLibraryModeCreateFolder) {
        _libraryMode = _previousLibraryMode;
        _indexPaths = nil;
        [self updateViewContents];
    }

    [self.navigationController setToolbarHidden:!editing animated:YES];

    [UIView performWithoutAnimation:^{
        [editButton setTitle:editing ? NSLocalizedString(@"BUTTON_CANCEL", nil) : NSLocalizedString(@"BUTTON_EDIT", nil)];
    }];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        NSMutableArray *rightBarButtonItems = [self.navigationItem.rightBarButtonItems mutableCopy];
        UIBarButtonItem *toggleDisplayedView = rightBarButtonItems[0];
        toggleDisplayedView.enabled = !editing;
        rightBarButtonItems[0] = toggleDisplayedView;
        self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    }
}

- (void)toggleDisplayedView:(UIBarButtonItem *)button
{
    self.usingTableViewToShowData = !self.usingTableViewToShowData;
    UIImage *newButtonImage = [UIImage imageNamed: self.usingTableViewToShowData ? @"collectionViewIcon" : @"tableViewIcon"];
    [button setImage:newButtonImage];
    [self updateViewsForCurrentDisplayMode];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (IBAction)leftButtonAction:(id)sender
{
    if (self.isEditing)
        [self setEditing:NO animated:YES];
}

- (IBAction)backToAllItems:(id)sender
{
    _inFolder = NO;
    NSMutableArray *toolbarItems = [self.toolbarItems mutableCopy];
    toolbarItems[2] = _createFolderBarButtonItem;
    self.toolbarItems = toolbarItems;
    [self setLibraryMode:_previousLibraryMode];
    if (!self.isEditing) {
        [self setSearchBar:YES resetContent:NO];
    }
    [self updateViewContents];
}

- (void)_endEditingWithHardReset:(BOOL)hardReset
{
    [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
    if (hardReset)
        [self updateViewContents];
    else
        [self reloadViews];

    [self setEditing:NO animated:YES];
}

- (void)deleteSelection:(id)sender
{
    NSArray *indexPaths = [self usingTableViewToShowData] ? [self.tableView indexPathsForSelectedRows] : [self.collectionView indexPathsForSelectedItems];

    if ((!indexPaths || [indexPaths count] == 0) && !_deleteFromTableView) {
        UIAlertController *invalidSelection = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"DELETE_INVALID_TITLE", nil) message:NSLocalizedString(@"DELETE_INVALID_MESSAGE", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *doneAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil) style:UIAlertActionStyleDefault handler:nil];

        [invalidSelection addAction:doneAction];
        [self presentViewController:invalidSelection animated:YES completion:nil];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"DELETE_TITLE", nil) message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_DELETE", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            if (_deleteFromTableView) {
                NSIndexPath *indexPath = (NSIndexPath *)sender;
                if (indexPath && indexPath.row < [_mediaDataSource numberOfFiles])
                    [self removeMediaObject:[_mediaDataSource objectAtIndex:indexPath.row] updateDatabase:YES];
            } else
                [self deletionAfterConfirmation];
            _deleteFromTableView = NO;
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            _deleteFromTableView ? [self setEditing:NO animated:YES] : [self reloadViews];
            _deleteFromTableView = NO;
        }];
        [alert addAction:deleteAction];
        [alert addAction:cancelAction];

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            CGRect tmpBounds = self.view.bounds;
            [alert setTitle:NSLocalizedString(@"DELETE_TITLE", nil)];
            [alert setMessage:NSLocalizedString(@"DELETE_MESSAGE", nil)];
            [alert.popoverPresentationController setPermittedArrowDirections:0];
            [alert.popoverPresentationController setSourceView:self.view];
            [alert.popoverPresentationController setSourceRect:CGRectMake(tmpBounds.size.width / 2.0, tmpBounds.size.height / 2.0, 1.0, 1.0)];
        }
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)deletionAfterConfirmation
{
    NSArray *indexPaths;
    if (self.usingTableViewToShowData) {
        indexPaths = [self.tableView indexPathsForSelectedRows];
    } else {
        indexPaths = [self.collectionView indexPathsForSelectedItems];
    }

    NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:indexPaths.count];

    for (NSIndexPath *indexPath in indexPaths)
        [objects addObject:[_mediaDataSource objectAtIndex:indexPath.row]];

    for (id object in objects)
        [self removeMediaObject:object updateDatabase:NO];

    [self _endEditingWithHardReset:YES];
}

- (void)renameSelection
{
    NSArray *indexPaths = [self selectedIndexPaths];

    if (indexPaths.count < 1) {
        [self _endEditingWithHardReset:NO];
        return;
    }

    NSString *itemName;
    if (self.usingTableViewToShowData)
        itemName = [(VLCPlaylistTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPaths[0]] titleLabel].text;
    else
        itemName = [(VLCPlaylistCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPaths[0]] titleLabel].text;

    VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"RENAME_MEDIA_TO", nil), itemName] message:nil cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:@[NSLocalizedString(@"BUTTON_RENAME", nil)]];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[alert textFieldAtIndex:0] setText:itemName];
    [[alert textFieldAtIndex:0] setClearButtonMode:UITextFieldViewModeAlways];

    __weak VLCAlertView *weakAlert = alert;
    alert.completion = ^(BOOL cancelled, NSInteger buttonIndex) {
        if (cancelled)
            [self _endEditingWithHardReset:NO];
        else
            [self renameMediaObjectTo:[weakAlert textFieldAtIndex:0].text];

    };
    [alert show];
}

- (void)renameMediaObjectTo:(NSString*)newName
{
    NSArray *indexPaths = [self selectedIndexPaths];
    if (indexPaths.count < 1)
        return;

    NSUInteger row = [indexPaths[0] row];
    id mediaObject = [_mediaDataSource objectAtIndex:row];

    if (!mediaObject) return;

    if ([mediaObject isKindOfClass:[MLAlbum class]] || [mediaObject isKindOfClass:[MLShowEpisode class]] || [mediaObject isKindOfClass:[MLShow class]] || [mediaObject isKindOfClass:[MLLabel class]] )
        [mediaObject setName:newName];
    else
        [mediaObject setTitle:newName];

    if (self.usingTableViewToShowData)
        [self.tableView deselectRowAtIndexPath:indexPaths[0] animated:YES];
    else
        [self.collectionView deselectItemAtIndexPath:indexPaths[0] animated:YES];

    if (indexPaths.count > 1)
        [self renameSelection];
    else
        [self _endEditingWithHardReset:NO];
}

- (void)updateViewsForCurrentDisplayMode
{
    UIImage *newButtonImage = [UIImage imageNamed: self.usingTableViewToShowData ? @"collectionViewIcon" : @"tableViewIcon"];
    [self.displayModeBarButtonItem setImage:newButtonImage];
}

#pragma mark - Sharing

// We take the array of index paths (instead of a count) to actually examine if the content is shareable. Selecting a single folder should not enable the share button.
- (void)updateActionBarButtonItemStateWithSelectedIndexPaths:(NSArray *)indexPaths
{
    NSUInteger count = [indexPaths count];
    if (!indexPaths || count == 0) {
        _shareBarButtonItem.enabled = NO;
    } else {
        // Look for at least one MLFile
        for (NSIndexPath *indexPath in indexPaths) {
            id mediaItem = [_mediaDataSource objectAtIndex:[indexPath row]];

            if ([mediaItem isKindOfClass:[MLFile class]] || [mediaItem isKindOfClass:[MLAlbumTrack class]] | [mediaItem isKindOfClass:[MLShowEpisode class]]) {
                _shareBarButtonItem.enabled = YES;
                return;
            }
        }
    }
}

- (NSArray *)fileURLsFromSelection
{
    NSArray *indexPaths = [self selectedIndexPaths];

    if (indexPaths.count == 0) return nil;

    NSMutableArray<NSURL*> *fileURLObjects = [[NSMutableArray alloc] initWithCapacity:indexPaths.count];

    for (NSIndexPath *indexpath in indexPaths) {
        id mediaItem = [_mediaDataSource objectAtIndex:[indexpath row]];
        NSURL *fileURL;

        if ([mediaItem isKindOfClass:[MLFile class]]) {
            fileURL = [(MLFile *) mediaItem url];
        } else if ([mediaItem isKindOfClass:[MLAlbumTrack class]]) {
            fileURL = [[(MLAlbumTrack *) mediaItem anyFileFromTrack] url];
        } else if ([mediaItem isKindOfClass:[MLShowEpisode class]]) {
            fileURL = [[(MLShowEpisode *) mediaItem anyFileFromEpisode] url];
        }
        if ([fileURL isFileURL]) {
            [fileURLObjects addObject:fileURL];
        }
    }
    return [fileURLObjects copy];
}

- (void)share:(UIBarButtonItem *)barButtonItem
{
    NSParameterAssert(barButtonItem);
    if (!barButtonItem) {
        APLog(@"Missing a UIBarButtonItem to present from");
        return;
    }
    //disable any possible changes to selection (or exit from this screen)
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];

    UIActivityViewController *controller = [VLCActivityViewControllerVendor activityViewControllerForFiles:[self fileURLsFromSelection] presentingButton:barButtonItem presentingViewController:self];
    if (!controller) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    } else {

        controller.popoverPresentationController.sourceView = self.navigationController.toolbar;

        [self.navigationController presentViewController:controller animated:YES completion:^{
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        }];
    }
}

#pragma mark - properties

- (void)setLibraryMode:(VLCLibraryMode)mode
{
    _libraryMode = mode;
    [self updateViewContents];

    if (mode == VLCLibraryModeAllAlbums ||
        mode == VLCLibraryModeAllSeries ||
        mode == VLCLibraryModeAllFiles) {
        _previousLibraryMode = mode;
    }
}

- (BOOL)usingTableViewToShowData
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kUsingTableViewToShowData];
}

- (void)setUsingTableViewToShowData:(BOOL)usingTableViewToShowData
{
    [[NSUserDefaults standardUserDefaults] setBool:usingTableViewToShowData forKey:kUsingTableViewToShowData];
    [self updateViewsForCurrentDisplayMode];
    [self setupContentView];
}

#pragma mark - autorotation

// RootController is responsible for supporting interface orientation(iOS6.0+), i.e. navigation controller
// so this will not work as intended without "voodoo magic"(UINavigationController category, subclassing, etc)
/* introduced in iOS 6 */
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;

    return ([_mediaDataSource numberOfFiles] > 0)? UIInterfaceOrientationMaskAllButUpsideDown:
    UIInterfaceOrientationMaskPortrait;
}

/* introduced in iOS 6 */
- (BOOL)shouldAutorotate
{
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) || ([_mediaDataSource numberOfFiles] > 0);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self setViewFromDeviceOrientation];
    NSArray *visibleCells = [self.tableView visibleCells];
    NSUInteger cellCount = visibleCells.count;
    for (NSUInteger x = 0; x < cellCount; x++) {
        if ([visibleCells[x] isExpanded])
            [visibleCells[x] metaDataLabel].hidden = YES;
    }
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setViewFromDeviceOrientation];
        [self.collectionView.collectionViewLayout invalidateLayout];
    } completion:nil];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([_searchController.searchBar isFirstResponder])
        [_searchController.searchBar resignFirstResponder];
}

#pragma mark - SearchController Delegate

- (void)didPresentSearchController:(UISearchController *)searchController
{
    _tableView.dataSource = _searchDataSource;
}

- (void)didDismissSearchController:(UISearchController *)searchController
{
    _tableView.dataSource = self;
}

#pragma mark - Search Research Updater

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    [_searchDataSource shouldReloadTableForSearchString:searchController.searchBar.text searchableFiles:[_mediaDataSource allObjects]];
    [_tableView reloadData];
}

#pragma mark - handoff

- (void)restoreUserActivityState:(NSUserActivity *)activity
{
    NSString *userActivityType = activity.activityType;
    if([userActivityType isEqualToString:kVLCUserActivityLibraryMode] ||
       [userActivityType isEqualToString:kVLCUserActivityLibrarySelection]) {

        NSDictionary *dict = activity.userInfo;
        NSString *folderPath = dict[@"folder"];
        if (!folderPath) return;
        NSURL *folderURL = [NSURL URLWithString:folderPath];

        NSUInteger count = [_mediaDataSource numberOfFiles];
        for (NSUInteger i = 0; i < count; i++) {
            NSManagedObject *object = [_mediaDataSource objectAtIndex:i];

            if([object.objectID.URIRepresentation isEqual:folderURL]) {
                [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
    }
}

@end
