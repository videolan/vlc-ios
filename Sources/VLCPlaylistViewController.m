/*****************************************************************************
 * VLCPlaylistViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Gleb Pinigin <gpinigin # gmail.com>
 *          Tamas Timar <ttimar.vlc # gmail.com>
 *          Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCPlaylistViewController.h"
#import "VLCMovieViewController.h"
#import "VLCPlaylistTableViewCell.h"
#import "VLCPlaylistCollectionViewCell.h"
#import "UINavigationController+Theme.h"
#import "NSString+SupportedMedia.h"
#import "VLCBugreporter.h"
#import "VLCAppDelegate.h"
#import "UIBarButtonItem+Theme.h"
#import "VLCFirstStepsViewController.h"
#import "VLCFolderCollectionViewFlowLayout.h"
#import "LXReorderableCollectionViewFlowLayout.h"
#import "VLCAlertView.h"
#import "VLCOpenInActivity.h"

#import <AssetsLibrary/AssetsLibrary.h>

/* prefs keys */
static NSString *kDisplayedFirstSteps = @"Did we display the first steps tutorial?";

@implementation EmptyLibraryView

- (IBAction)learnMore:(id)sender
{
    UIViewController *firstStepsVC = [[VLCFirstStepsViewController alloc] initWithNibName:nil bundle:nil];
    UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:firstStepsVC];
    navCon.modalPresentationStyle = UIModalPresentationFormSheet;
    [navCon loadTheme];
    [self.window.rootViewController presentViewController:navCon animated:YES completion:nil];
}

@end

@interface VLCPlaylistViewController () <VLCFolderCollectionViewDelegateFlowLayout, LXReorderableCollectionViewDataSource, LXReorderableCollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate, MLMediaLibrary, VLCMediaListDelegate, UISearchBarDelegate, UISearchDisplayDelegate> {
    NSMutableArray *_foundMedia;
    VLCLibraryMode _libraryMode;
    VLCLibraryMode _previousLibraryMode;
    UIBarButtonItem *_menuButton;
    NSMutableArray *_indexPaths;
    id _folderObject;
    VLCFolderCollectionViewFlowLayout *_folderLayout;
    LXReorderableCollectionViewFlowLayout *_reorderLayout;
    BOOL inFolder;
    UILongPressGestureRecognizer *_longPressGestureRecognizer;
    NSInteger _mediaToPlayIndex;
    VLCMediaList *_list;
    NSArray *_tracks;

    NSMutableArray *_searchData;
    UISearchBar *_searchBar;
    UISearchDisplayController *_searchDisplayController;

    BOOL _usingTableViewToShowData;

    UIBarButtonItem *_actionBarButtonItem;
    VLCOpenInActivity *_openInActivity;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) EmptyLibraryView *emptyLibraryView;

@end

@implementation VLCPlaylistViewController

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{kDisplayedFirstSteps : [NSNumber numberWithBool:NO]}];
}

- (void)loadView
{
    _usingTableViewToShowData = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    [self setupContentViewWithContentInset:NO];
    _libraryMode = VLCLibraryModeAllFiles;

    self.emptyLibraryView = [[[NSBundle mainBundle] loadNibNamed:@"VLCEmptyLibraryView" owner:self options:nil] lastObject];
    _emptyLibraryView.emptyLibraryLongDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _emptyLibraryView.emptyLibraryLongDescriptionLabel.numberOfLines = 0;
}

- (void)setupContentViewWithContentInset:(BOOL)setInset
{
    if (_usingTableViewToShowData) {
        if(!_tableView) {
            _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
            _tableView.backgroundColor = [UIColor VLCDarkBackgroundColor];
            _tableView.rowHeight = [VLCPlaylistTableViewCell heightOfCell];
            _tableView.separatorColor = [UIColor VLCDarkBackgroundColor];
            _tableView.delegate = self;
            _tableView.dataSource = self;
            _tableView.opaque = YES;
            _tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        }
        self.view = _tableView;
        [_tableView reloadData];
    } else {
        if (!_collectionView) {
            _folderLayout = [[VLCFolderCollectionViewFlowLayout alloc] init];
            _collectionView = [[UICollectionView alloc] initWithFrame:[UIScreen mainScreen].bounds collectionViewLayout:_folderLayout];
            _collectionView.alwaysBounceVertical = YES;
            _collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
            _collectionView.delegate = self;
            _collectionView.dataSource = self;
            _collectionView.opaque = YES;
            _collectionView.backgroundColor = [UIColor VLCDarkBackgroundColor];
            _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_collectionViewHandleLongPressGesture:)];
            [_collectionView addGestureRecognizer:_longPressGestureRecognizer];
            if (SYSTEM_RUNS_IOS7_OR_LATER)
                [_collectionView registerNib:[UINib nibWithNibName:@"VLCFuturePlaylistCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"PlaylistCell"];
            else
                [_collectionView registerNib:[UINib nibWithNibName:@"VLCPlaylistCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"PlaylistCell"];
            self.view.backgroundColor = [UIColor VLCDarkBackgroundColor];
        }
        self.view = _collectionView;
        [_collectionView reloadData];
    }

    if (setInset) {
        CGSize statusBarSize = [UIApplication sharedApplication].statusBarFrame.size;
        // Status bar frame doesn't change correctly on rotation
        CGFloat statusBarHeight = MIN(statusBarSize.height, statusBarSize.width);
        CGFloat originY = self.navigationController.navigationBar.frame.size.height + statusBarHeight;

        if (_usingTableViewToShowData)
            _tableView.contentInset = UIEdgeInsetsMake(originY, 0, 0, 0);
    }

    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"LIBRARY_ALL_FILES", nil);
    _menuButton = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(leftButtonAction:)];
    self.navigationItem.leftBarButtonItem = _menuButton;

    if (SYSTEM_RUNS_IOS7_OR_LATER)
        self.editButtonItem.tintColor = [UIColor whiteColor];
    else {
        [self.editButtonItem setBackgroundImage:[UIImage imageNamed:@"button"]
                                       forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [self.editButtonItem setBackgroundImage:[UIImage imageNamed:@"buttonHighlight"]
                                       forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    }

    _emptyLibraryView.emptyLibraryLabel.text = NSLocalizedString(@"EMPTY_LIBRARY", nil);
    _emptyLibraryView.emptyLibraryLongDescriptionLabel.text = NSLocalizedString(@"EMPTY_LIBRARY_LONG", nil);
    [_emptyLibraryView.emptyLibraryLongDescriptionLabel sizeToFit];
    [_emptyLibraryView.learnMoreButton setTitle:NSLocalizedString(@"BUTTON_LEARN_MORE", nil) forState:UIControlStateNormal];
    UIBarButtonItem *createFolderItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(createFolder)];

    // Better visual alignment with the action button
    UIEdgeInsets insets = UIEdgeInsetsMake(4, 0, 0, 0);
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        insets.top += 1;
    }
    createFolderItem.imageInsets = insets;

    _actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actOnSelection:)];
    _actionBarButtonItem.enabled = NO;

    // If you find strange issues with multiple Edit/Cancel actions causing UIToolbar spacing corruption, use a flexible space instead of a fixed space.
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 20;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        fixedSpace.width *= 2;
    }

    [self setToolbarItems:@[_actionBarButtonItem, fixedSpace, createFolderItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], [UIBarButtonItem themedDarkToolbarButtonWithTitle:NSLocalizedString(@"BUTTON_RENAME", nil) target:self andSelector:@selector(renameSelection)], [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteSelection)]]];
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;

    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        self.navigationController.toolbar.tintColor = [UIColor whiteColor];
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    } else
        [self.navigationController.toolbar setBackgroundImage:[UIImage imageNamed:@"bottomBlackBar"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    UINavigationBar *navBar = self.navigationController.navigationBar;
    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        _searchBar.barTintColor = navBar.barTintColor;
        // cancel button tint color of UISearchBar with white color
        [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    }
    _searchBar.tintColor = navBar.tintColor;
    _searchBar.translucent = navBar.translucent;
    _searchBar.opaque = navBar.opaque;
    _searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
    _searchDisplayController.delegate = self;
    _searchDisplayController.searchResultsDataSource = self;
    _searchDisplayController.searchResultsDelegate = self;
    _searchDisplayController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _searchDisplayController.searchResultsTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    _searchBar.delegate = self;
    _searchBar.hidden = YES;

    UITapGestureRecognizer *tapTwiceGesture = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(tapTwiceGestureAction:)];
    [tapTwiceGesture setNumberOfTapsRequired:2];
    [self.navigationController.navigationBar addGestureRecognizer:tapTwiceGesture];

    _searchData = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self _displayEmptyLibraryViewIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![[defaults objectForKey:kDisplayedFirstSteps] boolValue]) {
        [self.emptyLibraryView performSelector:@selector(learnMore:) withObject:nil afterDelay:1.];
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:kDisplayedFirstSteps];
        [defaults synchronize];
    }

    if ([[MLMediaLibrary sharedMediaLibrary] libraryNeedsUpgrade]) {
        self.navigationItem.rightBarButtonItem = nil;
        self.navigationItem.leftBarButtonItem = nil;
        self.title = @"";
        self.emptyLibraryView.emptyLibraryLabel.text = NSLocalizedString(@"UPGRADING_LIBRARY", nil);
        self.emptyLibraryView.emptyLibraryLongDescriptionLabel.hidden = YES;
        [self.emptyLibraryView.activityIndicator startAnimating];
        self.emptyLibraryView.frame = self.view.bounds;
        [self.view addSubview:self.emptyLibraryView];

        [[MLMediaLibrary sharedMediaLibrary] setDelegate: self];
        [[MLMediaLibrary sharedMediaLibrary] performSelectorInBackground:@selector(upgradeLibrary) withObject:nil];
        return;
    }

    if (_foundMedia.count < 1)
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
    if ([mediaObject isKindOfClass:[MLAlbum class]]) {
        _foundMedia = [NSMutableArray arrayWithArray:[(MLAlbum *)mediaObject sortedTracks]];
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(backToAllItems:)];
        if (_libraryMode == VLCLibraryModeAllFiles)
            self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"BUTTON_BACK", nil);
        else
            [self.navigationItem.leftBarButtonItem setTitle:NSLocalizedString(@"LIBRARY_MUSIC", nil)];
        self.title = [(MLAlbum*)mediaObject name];
        [self reloadViews];
    } else if ([mediaObject isKindOfClass:[MLShow class]]) {
        _foundMedia = [NSMutableArray arrayWithArray:[(MLShow *)mediaObject sortedEpisodes]];
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(backToAllItems:)];
        if (_libraryMode == VLCLibraryModeAllFiles)
            self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"BUTTON_BACK", nil);
        else
            [self.navigationItem.leftBarButtonItem setTitle:NSLocalizedString(@"LIBRARY_SERIES", nil)];
        self.title = [(MLShow*)mediaObject name];
        [self reloadViews];
    } else if ([mediaObject isKindOfClass:[MLLabel class]]) {
        MLLabel *folder = (MLLabel*) mediaObject;
        inFolder = YES;
        if (!_usingTableViewToShowData) {
            if (![self.collectionView.collectionViewLayout isEqual:_reorderLayout]) {
                for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers) {
                    if (recognizer == _folderLayout.panGestureRecognizer || recognizer == _folderLayout.longPressGestureRecognizer || recognizer == _longPressGestureRecognizer)
                        [self.collectionView removeGestureRecognizer:recognizer];
                }
                _reorderLayout = [[LXReorderableCollectionViewFlowLayout alloc] init];
                [self.collectionView setCollectionViewLayout:_reorderLayout animated:NO];
            }
        }
        _foundMedia = [NSMutableArray arrayWithArray:[folder sortedFolderItems]];
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(backToAllItems:)];
        self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"BUTTON_BACK", nil);
        self.title = [folder name];

        UIBarButtonItem *removeFromFolder = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(removeFromFolder)];
        NSMutableArray *toolbarItems = [self.toolbarItems mutableCopy];
        toolbarItems[2] = removeFromFolder;
        self.toolbarItems = toolbarItems;

        [self reloadViews];
        return;
    } else
        [(VLCAppDelegate*)[UIApplication sharedApplication].delegate openMediaFromManagedObject:mediaObject];
}

- (void)removeMediaObject:(id)managedObject updateDatabase:(BOOL)updateDB
{
        // delete all tracks from an album
    if ([managedObject isKindOfClass:[MLAlbum class]]) {
        MLAlbum *album = managedObject;
        NSSet *iterAlbumTrack = [NSSet setWithSet:album.tracks];

        for (MLAlbumTrack *track in iterAlbumTrack) {
            NSSet *iterFiles = [NSSet setWithSet:track.files];

            for (MLFile *file in iterFiles)
                [self _deleteMediaObject:file];
        }
        // delete all episodes from a show
    } else if ([managedObject isKindOfClass:[MLShow class]]) {
        MLShow *show = managedObject;
        NSSet *iterShowEpisodes = [NSSet setWithSet:show.episodes];

        for (MLShowEpisode *episode in iterShowEpisodes) {
            NSSet *iterFiles = [NSSet setWithSet:episode.files];

            for (MLFile *file in iterFiles)
                [self _deleteMediaObject:file];
        }
        // delete all files from an episode
    } else if ([managedObject isKindOfClass:[MLShowEpisode class]]) {
        MLShowEpisode *episode = managedObject;
        NSSet *iterFiles = [NSSet setWithSet:episode.files];

        for (MLFile *file in iterFiles)
            [self _deleteMediaObject:file];
        // delete all files from a track
    } else if ([managedObject isKindOfClass:[MLAlbumTrack class]]) {
        MLAlbumTrack *track = managedObject;
        NSSet *iterFiles = [NSSet setWithSet:track.files];

        for (MLFile *file in iterFiles)
            [self _deleteMediaObject:file];
    } else if ([managedObject isKindOfClass:[MLLabel class]]) {
        MLLabel *folder = managedObject;
        NSSet *iterFiles = [NSSet setWithSet:folder.files];
        [folder removeFiles:folder.files];
        for (MLFile *file in iterFiles)
            [self _deleteMediaObject:file];
        [[MLMediaLibrary sharedMediaLibrary] removeObject:folder];
    }
    else
        [self _deleteMediaObject:managedObject];

    if (updateDB) {
        [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
        [self updateViewContents];
    }
}

- (void)_deleteMediaObject:(MLFile *)mediaObject
{
    if (inFolder)
        [self rearrangeFolderTrackNumbersForRemovedItem:mediaObject];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folderLocation = [[[NSURL URLWithString:mediaObject.url] path] stringByDeletingLastPathComponent];
    NSArray *allfiles = [fileManager contentsOfDirectoryAtPath:folderLocation error:nil];
    NSString *fileName = [[[[NSURL URLWithString:mediaObject.url] path] lastPathComponent] stringByDeletingPathExtension];
    NSIndexSet *indexSet = [allfiles indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
       return ([obj rangeOfString:fileName].location != NSNotFound);
    }];
    NSUInteger count = indexSet.count;
    NSString *additionalFilePath;
    NSUInteger currentIndex = [indexSet firstIndex];
    for (unsigned int x = 0; x < count; x++) {
        additionalFilePath = allfiles[currentIndex];
        if ([additionalFilePath isSupportedSubtitleFormat])
            [fileManager removeItemAtPath:[folderLocation stringByAppendingPathComponent:additionalFilePath] error:nil];
        currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
    [fileManager removeItemAtPath:[[NSURL URLWithString:mediaObject.url] path] error:nil];
}

- (void)_displayEmptyLibraryViewIfNeeded
{
    if (self.emptyLibraryView.superview)
        [self.emptyLibraryView removeFromSuperview];

    if (_foundMedia.count == 0) {
        self.emptyLibraryView.emptyLibraryLabel.text = inFolder ? NSLocalizedString(@"FOLDER_EMPTY", nil) : NSLocalizedString(@"EMPTY_LIBRARY", nil);
        self.emptyLibraryView.emptyLibraryLongDescriptionLabel.text = inFolder ? NSLocalizedString(@"FOLDER_EMPTY_LONG", nil) : NSLocalizedString(@"EMPTY_LIBRARY_LONG", nil);
        self.emptyLibraryView.learnMoreButton.hidden = inFolder;
        self.emptyLibraryView.frame = self.view.bounds;
        [self.view addSubview:self.emptyLibraryView];
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            UIBarButtonItem *toggleDisplayedView = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tableViewIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleDisplayedView:)];
            self.navigationItem.rightBarButtonItems = @[toggleDisplayedView, self.editButtonItem];
        } else {
            self.navigationItem.rightBarButtonItem = self.editButtonItem;
        }
    }
    if (_usingTableViewToShowData)
        _tableView.separatorStyle = (_foundMedia.count > 0)? UITableViewCellSeparatorStyleSingleLine:
                                                             UITableViewCellSeparatorStyleNone;
    else
        [self.collectionView.collectionViewLayout invalidateLayout];
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

- (void)libraryWasUpdated
{
    [self updateViewContents];
}

- (void)updateViewContents
{
    _foundMedia = [[NSMutableArray alloc] init];

    self.navigationItem.leftBarButtonItem = _menuButton;
    if (_libraryMode == VLCLibraryModeAllAlbums)
        self.title = NSLocalizedString(@"LIBRARY_MUSIC", nil);
    else if( _libraryMode == VLCLibraryModeAllSeries)
        self.title = NSLocalizedString(@"LIBRARY_SERIES", nil);
    else
        self.title = NSLocalizedString(@"LIBRARY_ALL_FILES", nil);

    /* add all albums */
    if (_libraryMode != VLCLibraryModeAllSeries) {
        NSArray *rawAlbums = [MLAlbum allAlbums];
        for (MLAlbum *album in rawAlbums) {
            if (album.name.length > 0 && album.tracks.count > 1)
                [_foundMedia addObject:album];
        }
    }
    if (_libraryMode == VLCLibraryModeAllAlbums) {
        [self reloadViews];
        return;
    }

    /* add all shows */
    NSArray *rawShows = [MLShow allShows];
    for (MLShow *show in rawShows) {
        if (show.name.length > 0 && show.episodes.count > 1)
            [_foundMedia addObject:show];
    }
    if (_libraryMode == VLCLibraryModeAllSeries) {
        [self reloadViews];
        return;
    }

    /* add all folders*/
    NSArray *allFolders = [MLLabel allLabels];
    for (MLLabel *folder in allFolders)
        [_foundMedia addObject:folder];

    /* add all remaining files */
    NSArray *allFiles = [MLFile allFiles];
    for (MLFile *file in allFiles) {
        if (file.labels.count > 0) continue;

        if (!file.isShowEpisode && !file.isAlbumTrack)
            [_foundMedia addObject:file];
        else if (file.isShowEpisode) {
            if (file.showEpisode.show.episodes.count < 2)
                [_foundMedia addObject:file];

            /* older MediaLibraryKit versions don't send a show name in a popular
             * corner case. hence, we need to work-around here and force a reload
             * afterwards as this could lead to the 'all my shows are gone' 
             * syndrome (see #10435, #10464, #10432 et al) */
            if (file.showEpisode.show.name.length == 0) {
                file.showEpisode.show.name = NSLocalizedString(@"UNTITLED_SHOW", nil);
                [self performSelector:@selector(updateViewContents) withObject:nil afterDelay:0.1];
            }
        } else if (file.isAlbumTrack) {
            if (file.albumTrack.album.tracks.count < 2)
                [_foundMedia addObject:file];
        }
    }

    [self reloadViews];
}

- (void)reloadViews
{
    // Since this gets can get called at any point and wipe away the selections, we update the actionBarButtonItem here because this can happen if you tap "Save Video" in the UIActivityController and a media access alert view takes away focus (the corresponding 'became active' notification of UIApplication will call this). Or simply try bringing down the notification center to trigger this. Any existing UIActivityViewController session should be safe as it would have copies of the selected file references.
    if (_usingTableViewToShowData) {
        [self.tableView reloadData];
        [self updateActionBarButtonItemStateWithSelectedIndexPaths:[self.tableView indexPathsForSelectedRows]];
    } else {
        [self.collectionView reloadData];
        [self updateActionBarButtonItemStateWithSelectedIndexPaths:[self.collectionView indexPathsForSelectedItems]];
    }

    [self _displayEmptyLibraryViewIfNeeded];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return _searchData.count;

    return _foundMedia.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PlaylistCell";

    VLCPlaylistTableViewCell *cell = (VLCPlaylistTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCPlaylistTableViewCell cellWithReuseIdentifier:CellIdentifier];
    else
        [cell collapsWithAnimation:NO];

    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRightOnTableViewCellGestureAction:)];
    [swipeRight setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [cell addGestureRecognizer:swipeRight];

    NSInteger row = indexPath.row;

    if (tableView == self.searchDisplayController.searchResultsTableView)
        cell.mediaObject = _searchData[row];
    else
        cell.mediaObject = _foundMedia[row];

    return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    MLFile* object = [_foundMedia objectAtIndex:fromIndexPath.item];
    [_foundMedia removeObjectAtIndex:fromIndexPath.item];
    [_foundMedia insertObject:object atIndex:toIndexPath.item];
    object.folderTrackNumber = @(toIndexPath.item - 1);
    object = [_foundMedia objectAtIndex:fromIndexPath.item];
    object.folderTrackNumber = @(fromIndexPath.item - 1);
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return inFolder;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor VLCDarkBackgroundColor];
    cell.multipleSelectionBackgroundView.backgroundColor = cell.backgroundColor;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
        [self removeMediaObject: _foundMedia[indexPath.row] updateDatabase:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.isEditing) {
        [self updateActionBarButtonItemStateWithSelectedIndexPaths:[tableView indexPathsForSelectedRows]];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([(VLCPlaylistTableViewCell *)[tableView cellForRowAtIndexPath:indexPath] isExpanded]) {
        [(VLCPlaylistTableViewCell *)[tableView cellForRowAtIndexPath:indexPath] collapsWithAnimation:YES];
        return;
    }

    NSArray *visibleCells = [tableView visibleCells];
    NSUInteger cellCount = visibleCells.count;
    for (NSUInteger x = 0; x < cellCount; x++) {
        if ([visibleCells[x] isExpanded])
            [visibleCells[x] collapsWithAnimation:NO];
    }

    if (tableView.isEditing) {
        if (_libraryMode == VLCLibraryModeCreateFolder) {
            _folderObject = _foundMedia[indexPath.row];
            _libraryMode = _previousLibraryMode;
            [self updateViewContents];
            [self createFolderWithName:nil];
        } else {
            [self updateActionBarButtonItemStateWithSelectedIndexPaths:[tableView indexPathsForSelectedRows]];
        }
        return;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSManagedObject *selectedObject;

    if (tableView == self.searchDisplayController.searchResultsTableView)
        selectedObject = _searchData[indexPath.row];
    else
        selectedObject = _foundMedia[indexPath.row];

    if ([selectedObject isKindOfClass:[MLAlbumTrack class]]) {
        _tracks = [[(MLAlbumTrack*)selectedObject album] sortedTracks];
        NSUInteger count = _tracks.count;
        _list = [[VLCMediaList alloc] init];
        _list.delegate = self;
        MLFile *file;
        VLCMedia *media;
        for (NSInteger x = count - 1; x > -1; x--) {
            file = [(MLAlbumTrack*)_tracks[x] files].anyObject;
            media = [VLCMedia mediaWithURL: [NSURL URLWithString:file.url]];
            [media parse];
            [_list addMedia:media];
        }
        _mediaToPlayIndex = indexPath.row;
    } else if ([selectedObject isKindOfClass:[MLFile class]] && [((MLFile *)selectedObject).labels count] > 0) {
        MLLabel *folder = [((MLFile *)selectedObject).labels anyObject];
        _tracks = [folder sortedFolderItems];
        NSUInteger count = _tracks.count;
        _list = [[VLCMediaList alloc] init];
        _list.delegate = self;
        MLFile *file;
        for (NSInteger x = count - 1; x > -1; x--) {
            file = (MLFile *)_tracks[x];
            [_list addMedia:[VLCMedia mediaWithURL:[NSURL URLWithString:file.url]]];
        }
        _mediaToPlayIndex = indexPath.row;
    } else {
        if (_searchDisplayController.active == YES)
            [_searchDisplayController setActive:NO animated:NO];
        [self openMediaObject:selectedObject];
    }
}

#pragma mark - VLCMedialistDelegate
- (void)mediaList:(VLCMediaList *)aMediaList mediaAdded:(VLCMedia *)media atIndex:(NSInteger)index
{
    if (index == _tracks.count - 1) {
        NSManagedObject *selectedObject = _foundMedia[_mediaToPlayIndex];
        [(VLCAppDelegate *)[UIApplication sharedApplication].delegate openMediaList:_list atIndex:(int)[_tracks indexOfObject:selectedObject]];
    }
}

#pragma mark - Gesture Action
- (void)swipeRightOnTableViewCellGestureAction:(UIGestureRecognizer *)recognizer
{
    if ([[self.editButtonItem title] isEqualToString:NSLocalizedString(@"BUTTON_CANCEL", nil)])
        [self setEditing:NO animated:YES];
    else {
        [self setEditing:YES animated:YES];

        NSIndexPath *path = [(UITableView *)self.view indexPathForRowAtPoint:[recognizer locationInView:self.view]];
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:path.row inSection:path.section]
                                    animated:YES
                              scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)swipeRightOnCollectionViewCellGestureAction:(UIGestureRecognizer *)recognizer
{
    NSLog(@"swipeRightOnCollectionViewCellGestureAction");
    NSIndexPath *path = [self.collectionView indexPathForItemAtPoint:[recognizer locationInView:self.collectionView]];
    VLCPlaylistCollectionViewCell *cell = (VLCPlaylistCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:path];
    [cell showMetadata:!cell.showsMetaData];
}

- (void)tapTwiceGestureAction:(UIGestureRecognizer *)recognizer
{
    if (!_usingTableViewToShowData)
        return;

    _searchBar.hidden = !_searchBar.hidden;

    if (_searchBar.hidden)
        self.tableView.tableHeaderView = nil;
    else
        self.tableView.tableHeaderView = _searchBar;

    [self.tableView setContentOffset:CGPointMake(0.0f, -self.tableView.contentInset.top) animated:NO];
}

#pragma mark - Collection View
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _foundMedia.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VLCPlaylistCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PlaylistCell" forIndexPath:indexPath];
    cell.mediaObject = _foundMedia[indexPath.row];
    cell.collectionView = _collectionView;

    [cell setEditing:self.editing animated:NO];

    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRightOnCollectionViewCellGestureAction:)];
    [swipeRight setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [cell addGestureRecognizer:swipeRight];

    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
            return CGSizeMake(341., 190.);
        else
            return CGSizeMake(384., 216.);
    }

    return CGSizeMake(298.0, 220.0);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        return UIEdgeInsetsZero;
    return UIEdgeInsetsMake(0.0, 34.0, 0.0, 34.0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        return 0.;
    return 10.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        return 0.;
    return 10.0;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *visibleCells = [collectionView visibleCells];
    NSUInteger cellCount = visibleCells.count;

    if (self.editing) {
        if (_libraryMode == VLCLibraryModeCreateFolder) {
            _folderObject = _foundMedia[indexPath.item];
            [self createFolderWithName:nil];
             _libraryMode = _previousLibraryMode;
        } else {
            [self updateActionBarButtonItemStateWithSelectedIndexPaths:[collectionView indexPathsForSelectedItems]];
        }
        [(VLCPlaylistCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath] selectionUpdate];
        return;
    }

    for (NSUInteger x = 0; x < cellCount; x++) {
        VLCPlaylistCollectionViewCell *cell = visibleCells[x];
        if ([cell showsMetaData])
            [cell showMetadata:NO];
    }

    NSManagedObject *selectedObject = _foundMedia[indexPath.row];
    if ([selectedObject isKindOfClass:[MLAlbumTrack class]]) {
        VLCMediaList *list;
        NSArray *tracks = [[(MLAlbumTrack*)selectedObject album] sortedTracks];
        NSUInteger count = tracks.count;
        list = [[VLCMediaList alloc] init];

        MLFile *file;
        for (NSInteger x = count - 1; x > -1; x--) {
            file = [(MLAlbumTrack*)tracks[x] files].anyObject;
            [list addMedia:[VLCMedia mediaWithURL: [NSURL URLWithString:file.url]]];
        }
        [(VLCAppDelegate*)[UIApplication sharedApplication].delegate openMediaList:list atIndex:(int)[tracks indexOfObject:selectedObject]];
    } else if ([selectedObject isKindOfClass:[MLFile class]] && [((MLFile *)selectedObject).labels count] > 0) {
        VLCMediaList *list;
        MLLabel *folder = [((MLFile *)selectedObject).labels anyObject];
        NSArray *folderTracks = [folder sortedFolderItems];
        NSUInteger count = folderTracks.count;
        list = [[VLCMediaList alloc] init];

        MLFile *file;
        for (NSInteger x = count - 1; x > -1; x--) {
            file = (MLFile *)folderTracks[x];
            [list addMedia:[VLCMedia mediaWithURL:[NSURL URLWithString:file.url]]];
        }
        [(VLCAppDelegate *)[UIApplication sharedApplication].delegate openMediaList:list atIndex:(int)[folderTracks indexOfObject:selectedObject]];
    } else
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
    MLFile *mediaObject = (MLFile *)_foundMedia[indexPath.item];
    [self rearrangeFolderTrackNumbersForRemovedItem:mediaObject];
    mediaObject.labels = nil;
    mediaObject.folderTrackNumber = nil;

    [self backToAllItems:nil];
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath
{
    MLFile* object = [_foundMedia objectAtIndex:fromIndexPath.item];
    [_foundMedia removeObjectAtIndex:fromIndexPath.item];
    [_foundMedia insertObject:object atIndex:toIndexPath.item];
    object.folderTrackNumber = @(toIndexPath.item - 1);
    object = [_foundMedia objectAtIndex:fromIndexPath.item];
    object.folderTrackNumber = @(fromIndexPath.item - 1);
}

- (void)collectionView:(UICollectionView *)collectionView requestToMoveItemAtIndexPath:(NSIndexPath *)itemPath intoFolderAtIndexPath:(NSIndexPath *)folderPath
{
    BOOL validFileTypeAtFolderPath = ([_foundMedia[folderPath.item] isKindOfClass:[MLFile class]] || [_foundMedia[folderPath.item] isKindOfClass:[MLLabel class]]) && [_foundMedia[itemPath.item] isKindOfClass:[MLFile class]];

    if (!validFileTypeAtFolderPath) {
        VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"FOLDER_INVALID_TYPE_TITLE", nil) message:NSLocalizedString(@"FOLDER_INVALID_TYPE_MESSAGE", nil) cancelButtonTitle:nil otherButtonTitles:@[NSLocalizedString(@"BUTTON_OK", nil)]];

        alert.completion = ^(BOOL cancelled, NSInteger buttonIndex) {
            [self updateViewContents];
        };
        [alert show];
        return;
    }

    BOOL isFolder = [_foundMedia[folderPath.item] isKindOfClass:[MLLabel class]];

    if (isFolder){
        MLLabel *folder = _foundMedia[folderPath.item];
        MLFile *file = _foundMedia[itemPath.item];
        [file setLabels:[[NSSet alloc] initWithObjects:folder, nil]];
        file.folderTrackNumber = @([folder.files count] - 1);
        [_foundMedia removeObjectAtIndex:itemPath.item];
        [self updateViewContents];
    } else {
        _folderObject = _foundMedia[folderPath.item];
        _indexPaths = [NSMutableArray arrayWithArray:@[itemPath]];
        [self showCreateFolderAlert];
    }
}

#pragma mark - Folder implementation

- (void)rearrangeFolderTrackNumbersForRemovedItem:(MLFile *) mediaObject
{
    MLLabel *label = [mediaObject.labels anyObject];
    NSSet *allFiles = label.files;
    for (MLFile *file in allFiles) {
        if (file.folderTrackNumber > mediaObject.folderTrackNumber) {
            int value = [file.folderTrackNumber intValue];
            file.folderTrackNumber = [NSNumber numberWithInt:value - 1];
        }
    }
}

- (void)showCreateFolderAlert
{
    VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"FOLDER_CHOOSE_NAME_TITLE", nil) message:NSLocalizedString(@"FOLDER_CHOOSE_NAME_MESSAGE", nil) cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:@[NSLocalizedString(@"BUTTON_SAVE", nil)]];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[alert textFieldAtIndex:0] setText:NSLocalizedString(@"FOLDER_NAME_PLACEHOLDER", nil)];
    [[alert textFieldAtIndex:0] setClearButtonMode:UITextFieldViewModeAlways];

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
    if (!_usingTableViewToShowData)
        _indexPaths = [NSMutableArray arrayWithArray:[self.collectionView indexPathsForSelectedItems]];
    else
        _indexPaths = [NSMutableArray arrayWithArray:[self.tableView indexPathsForSelectedRows]];

    for (NSInteger i = _indexPaths.count - 1; i >=0; i--) {
        NSIndexPath *path = _indexPaths[i];
        id mediaObject;
        if (!_usingTableViewToShowData)
            mediaObject = _foundMedia[path.item];
        else
            mediaObject = _foundMedia[path.row];
        if ([mediaObject isKindOfClass:[MLLabel class]])
            [_indexPaths removeObject:path];
    }

    if ([_indexPaths count] != 0) {
        NSArray *folder = [MLLabel allLabels];
        //if we already have folders display them
        if ([folder count] > 0) {
            _foundMedia = [NSMutableArray arrayWithArray:folder];
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
    if (!_usingTableViewToShowData)
        _indexPaths = [NSMutableArray arrayWithArray:[self.collectionView indexPathsForSelectedItems]];
    else
        _indexPaths = [NSMutableArray arrayWithArray:[self.tableView indexPathsForSelectedRows]];

    [_indexPaths sortUsingSelector:@selector(compare:)];

    for (NSInteger i = [_indexPaths count] - 1; i >= 0; i--) {
        NSIndexPath *path = _indexPaths[i];
        MLFile *file = (MLFile *)_foundMedia[_usingTableViewToShowData ? path.row : path.item];

        MLLabel *folder = [file.labels anyObject];
        [self rearrangeFolderTrackNumbersForRemovedItem:file];
        file.labels = nil;
        file.folderTrackNumber = nil;
        [_foundMedia removeObject:file];

        if ([folder.files count] == 0) {
            [self removeMediaObject:folder updateDatabase:YES];
            [self setEditing:NO];
            [self backToAllItems:nil];
        }
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
        NSUInteger folderIndex = [_foundMedia indexOfObject:_folderObject];
        //item got dragged onto item
        if ([_foundMedia[folderIndex] isKindOfClass:[MLFile class]]) {
            MLFile *file = _foundMedia[folderIndex];
            MLLabel *label = [[MLMediaLibrary sharedMediaLibrary] createObjectForEntity:@"Label"];
            label.name = folderName;

            file.labels = [NSSet setWithObjects:label,nil];
            NSNumber *folderTrackNumber = [NSNumber numberWithInt:(int)[label files].count - 1];
            file.folderTrackNumber = folderTrackNumber;

            [_foundMedia removeObjectAtIndex:folderIndex];
            [_foundMedia insertObject:label atIndex:folderIndex];
            MLFile *itemFile = _foundMedia[((NSIndexPath *)_indexPaths[0]).item];
            itemFile.labels = file.labels;
            [_foundMedia removeObjectAtIndex:((NSIndexPath *)_indexPaths[0]).item];
            itemFile.folderTrackNumber = @([label files].count - 1);
        } else {
            //item got dragged onto folder or items should be added to folder
            MLLabel *label = _foundMedia[folderIndex];
            [_indexPaths sortUsingSelector:@selector(compare:)];

            for (NSInteger i = [_indexPaths count] - 1; i >= 0; i--) {
                NSIndexPath *path = _indexPaths[i];
                if (_libraryMode != VLCLibraryModeCreateFolder && ![_foundMedia[path.row] isKindOfClass:[MLFile class]])
                    continue;
                if (_libraryMode == VLCLibraryModeCreateFolder)
                    [self updateViewContents];

                MLFile *file = _foundMedia[path.row];
                file.labels = [NSSet setWithObjects:label, nil];
                [_foundMedia removeObjectAtIndex:path.row];
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
                if (!_usingTableViewToShowData) {
                    MLFile *file = _foundMedia[path.item];
                    file.labels = [NSSet setWithObjects:label, nil];
                    file.folderTrackNumber = @([label files].count - 1);
                    [_foundMedia removeObjectAtIndex:path.item];
                } else {
                    MLFile *file = _foundMedia[path.row];
                    file.labels = [NSSet setWithObjects:label, nil];
                    file.folderTrackNumber = @([label files].count - 1);
                    [_foundMedia removeObjectAtIndex:path.row];
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
    [self setEditing:YES animated:YES];
}

#pragma mark - UI implementation
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    UIBarButtonItem *editButton = self.editButtonItem;
    NSString *editImage = editing? @"doneButton": @"button";
    NSString *editImageHighlight = editing? @"doneButtonHighlight": @"buttonHighlight";
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        editButton.tintColor = [UIColor whiteColor];
    else {
        [editButton setBackgroundImage:[UIImage imageNamed:editImage] forState:UIControlStateNormal
                                     barMetrics:UIBarMetricsDefault];
        [editButton setBackgroundImage:[UIImage imageNamed:editImageHighlight]
                                       forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
        [editButton setTitleTextAttributes: editing ? @{UITextAttributeTextShadowColor : [UIColor whiteColor], UITextAttributeTextColor : [UIColor blackColor]} : @{UITextAttributeTextShadowColor : [UIColor VLCDarkTextShadowColor], UITextAttributeTextColor : [UIColor whiteColor]} forState:UIControlStateNormal];
    }

    if (!_usingTableViewToShowData) {
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
    } else {
        self.tableView.allowsMultipleSelectionDuringEditing = editing;
        [self.tableView setEditing:editing animated:YES];
        [self.editButtonItem setTitle:editing ? NSLocalizedString(@"BUTTON_CANCEL", nil) : NSLocalizedString(@"BUTTON_EDIT", nil)];
    }

    if (_libraryMode == VLCLibraryModeCreateFolder) {
        _libraryMode = _previousLibraryMode;
        _indexPaths = nil;
        [self updateViewContents];
    }

    self.navigationController.toolbarHidden = !editing;
}

- (void)toggleDisplayedView:(UIBarButtonItem *)button
{
    _usingTableViewToShowData = !_usingTableViewToShowData;
    UIImage *newButtonImage = [UIImage imageNamed: _usingTableViewToShowData ? @"collectionViewIcon" : @"tableViewIcon"];
    [button setImage:newButtonImage];
    [self setupContentViewWithContentInset:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (IBAction)leftButtonAction:(id)sender
{
    [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController] toggleSidebar:![(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController].sidebarShowing duration:kGHRevealSidebarDefaultAnimationDuration];

    if (self.isEditing)
        [self setEditing:NO animated:YES];
}

- (IBAction)backToAllItems:(id)sender
{
    if (!_usingTableViewToShowData) {
        if (self.editing)
            [self setEditing:NO animated:NO];
    }
    inFolder = NO;
    UIBarButtonItem *createFolderItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(createFolder)];
    NSMutableArray *toolbarItems = [self.toolbarItems mutableCopy];
    toolbarItems[2] = createFolderItem;
    self.toolbarItems = toolbarItems;
    [self setLibraryMode:_libraryMode];
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

- (void)deleteSelection
{
    NSArray *indexPaths;
    if (!_usingTableViewToShowData)
        indexPaths = [self.collectionView indexPathsForSelectedItems];
    else
        indexPaths = [self.tableView indexPathsForSelectedRows];
    NSUInteger count = indexPaths.count;
    NSMutableArray *objects = [[NSMutableArray alloc] initWithCapacity:count];

    for (NSUInteger x = 0; x < count; x++)
        [objects addObject:_foundMedia[[indexPaths[x] row]]];

    for (NSUInteger x = 0; x < count; x++)
        [self removeMediaObject:objects[x] updateDatabase:NO];

    [self _endEditingWithHardReset:YES];
}

- (void)renameSelection
{
    NSArray *indexPaths;
    if (!_usingTableViewToShowData)
        indexPaths = [self.collectionView indexPathsForSelectedItems];
    else
        indexPaths = [self.tableView indexPathsForSelectedRows];

    if (indexPaths.count < 1) {
        [self _endEditingWithHardReset:NO];
        return;
    }

    NSString *itemName;
    if (!_usingTableViewToShowData)
        itemName = [(VLCPlaylistCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPaths[0]] titleLabel].text;
    else
        itemName = [(VLCPlaylistTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPaths[0]] titleLabel].text;

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
    NSArray *indexPaths;
    if (!_usingTableViewToShowData)
        indexPaths = [self.collectionView indexPathsForSelectedItems];
    else
        indexPaths = [self.tableView indexPathsForSelectedRows];

    if (indexPaths.count < 1)
        return;

    id mediaObject = _foundMedia[[indexPaths[0] row]];

    if ([mediaObject isKindOfClass:[MLAlbum class]] || [mediaObject isKindOfClass:[MLShowEpisode class]] || [mediaObject isKindOfClass:[MLShow class]] || [mediaObject isKindOfClass:[MLLabel class]] )
        [mediaObject setName:newName];
    else
        [mediaObject setTitle:newName];

    if (!_usingTableViewToShowData)
        [self.collectionView deselectItemAtIndexPath:indexPaths[0] animated:YES];
    else
        [self.tableView deselectRowAtIndexPath:indexPaths[0] animated:YES];

    if (indexPaths.count > 1)
        [self renameSelection];
    else
        [self _endEditingWithHardReset:NO];
}

#pragma mark - Sharing

// We take the array of index paths (instead of a count) to actually examine if the content is shareable. Selecting a single folder should not enable the share button.
- (void)updateActionBarButtonItemStateWithSelectedIndexPaths:(NSArray *)indexPaths
{
    NSUInteger count = [indexPaths count];
    if (!indexPaths || count == 0) {
        _actionBarButtonItem.enabled = NO;
    } else {
        // Look for at least one MLFile
        for (NSUInteger x = 0; x < count; x++) {
            id mediaItem = _foundMedia[[indexPaths[x] row]];

            if ([mediaItem isKindOfClass:[MLFile class]] || [mediaItem isKindOfClass:[MLAlbumTrack class]] | [mediaItem isKindOfClass:[MLShowEpisode class]]) {
                _actionBarButtonItem.enabled = YES;
                return;
            }
        }
    }
}

- (void)actOnSelection:(UIBarButtonItem *)barButtonItem
{
    NSParameterAssert(barButtonItem);
    if (!barButtonItem) {
        APLog(@"Missing a UIBarButtonItem to present from");
        return;
    }

    NSArray *indexPaths;
    if (!_usingTableViewToShowData)
        indexPaths = [self.collectionView indexPathsForSelectedItems];
    else
        indexPaths = [self.tableView indexPathsForSelectedRows];

    NSUInteger count = indexPaths.count;
    if (count) {
        NSMutableArray /* NSURL */ *fileURLobjects = [[NSMutableArray alloc] initWithCapacity:count];

        for (NSUInteger x = 0; x < count; x++) {
            id mediaItem = _foundMedia[[indexPaths[x] row]];
            NSURL *fileURL;

            if ([mediaItem isKindOfClass:[MLFile class]])
                fileURL = [NSURL URLWithString:[(MLFile *)mediaItem url]];
            else if ([mediaItem isKindOfClass:[MLAlbumTrack class]])
                fileURL = [NSURL URLWithString:[(MLFile *)[[(MLAlbumTrack *)mediaItem files] anyObject] url]];
            else if ([mediaItem isKindOfClass:[MLShowEpisode class]])
                fileURL = [NSURL URLWithString:[(MLFile *)[[(MLShowEpisode *)mediaItem files] anyObject] url]];

            if ([fileURL isFileURL])
                [fileURLobjects addObject:fileURL];
        }

        if ([fileURLobjects count]) {
            // Provide some basic user feedback as UIActivityController lags in presentation sometimes (blocking the main thread).
            // iOS 6 has trouble re-enabling all the icons, so only disable the sharing one. Usage of the toolbar will be disabled by UIApplication in this case anyhow.
            if (SYSTEM_RUNS_IOS7_OR_LATER) {
                [self.navigationController.toolbar.items makeObjectsPerformSelector:@selector(setEnabled:) withObject:@(NO)];
            } else {
                _actionBarButtonItem.enabled = YES;
            }

            // Just in case, since we are facing a possible delay from code we do not control (UIActivityViewController), disable any possible changes to selection (or exit from this screen)
            [[UIApplication sharedApplication] beginIgnoringInteractionEvents];

            // The reason we do a dispatch_async to the main queue here even though we are already on the main queue is because UIActivityViewController blocks the main thread at some point (either during creation or presentation), which won't let UIKit draw our call to disable the toolbar items in time. On an actual device (where the lag can be seen when UIActivityViewController is presented for the first time during an applications lifetime) this makes for a much better user experience. If you have more items to share the lag may be greater.
            dispatch_async(dispatch_get_main_queue(), ^{
                _openInActivity = [[VLCOpenInActivity alloc] init];
                _openInActivity.presentingViewController = self;
                _openInActivity.presentingBarButtonItem = barButtonItem;

                dispatch_block_t enableInteractionBlock = ^{
                    if (SYSTEM_RUNS_IOS7_OR_LATER) {
                        // Strangely makeObjectsPerformSelector:withObject has trouble here (when called from presentViewController:animated:completion:)
                        // [self.navigationController.toolbar.items makeObjectsPerformSelector:@selector(setEnabled:) withObject:@(YES)];
                        for (UIBarButtonItem *item in self.navigationController.toolbar.items) {
                            item.enabled = YES;
                        }
                    } else {
                        _actionBarButtonItem.enabled = YES;
                    }

                    if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
                        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                    }
                };

                UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:fileURLobjects applicationActivities:@[_openInActivity]];
                if (SYSTEM_RUNS_IOS8_OR_LATER)
                    controller.popoverPresentationController.sourceView = self.navigationController.toolbar;

                controller.completionHandler = ^(NSString *activityType, BOOL completed) {
                    APLog(@"UIActivityViewController finished with activity type: %@, completed: %i", activityType, completed);

                    // Provide some feedback if saving media to the Camera Roll. Note that this could cause a false positive if the user chooses "Don't Allow" in the permissions dialog, and UIActivityViewController does not inform us of that, so check the authorization status.

                    // By the time this is called, the user has not had time to choose whether to allow access to the Photos library, so only display the message if we are truly sure we got authorization. The first time the user saves to the camera roll he won't see the confirmation because of this timing issue. This is better than showing a success message when the user had denied access. A timing workaround could be developed if needed through UIApplicationDidBecomeActiveNotification (to know when the security alert view was dismissed) or through other ALAssets APIs.
                    if (completed && [activityType isEqualToString:UIActivityTypeSaveToCameraRoll] && [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SHARING_SUCCESS_CAMERA_ROLL", nil)
                                                                            message:nil
                                                                           delegate:nil
                                                                  cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                                  otherButtonTitles:nil];
                        [alertView show];
                    }
                    _openInActivity = nil;

                    // Just in case, we could call enableInteractionBlock here. Since we are disabling touch interaction for the entire UI, to be safe that we return to the proper state: re-enable everything (if presentViewController:animated:completion: failed for some reason). But UIApplication gives us a warning even if we check isIgnoringInteractionEvents, so do not call it for now.
                    // enableInteractionBlock();
                };
                [self.navigationController presentViewController:controller animated:YES completion:enableInteractionBlock];
            });
            return;
        }
    }

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SHARING_ERROR_NO_FILES", nil)
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                              otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - coin coin

- (void)setLibraryMode:(VLCLibraryMode)mode
{
    _libraryMode = mode;
    [self updateViewContents];
}

#pragma mark - autorotation

// RootController is responsible for supporting interface orientation(iOS6.0+), i.e. navigation controller
// so this will not work as intended without "voodoo magic"(UINavigationController category, subclassing, etc)
/* introduced in iOS 6 */
- (NSUInteger)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;

    return (_foundMedia.count > 0)? UIInterfaceOrientationMaskAllButUpsideDown:
    UIInterfaceOrientationMaskPortrait;
}

/* introduced in iOS 6 */
- (BOOL)shouldAutorotate
{
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) || (_foundMedia.count > 0);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    if (!_usingTableViewToShowData)
        [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark - Search Display Controller Delegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSInteger listCount = _foundMedia.count;
    [_searchData removeAllObjects];
    NSManagedObject *item;
    NSRange nameRange;

    for (int i = 0; i < listCount; i++) {
        item = _foundMedia[i];

        if ([item isKindOfClass:[MLAlbum class]]) {
            nameRange = [[(MLAlbum*)item name] rangeOfString:searchString options:NSCaseInsensitiveSearch];

            if (nameRange.location == NSNotFound) {
                NSString *releaseYear = [(MLAlbum *)item releaseYear];
                if (releaseYear)
                    nameRange = [releaseYear rangeOfString:searchString options:NSCaseInsensitiveSearch];

                /* user didn't search for our album name or year, let's do a deeper search */
                if (nameRange.location == NSNotFound) {
                    NSArray *tracks = [(MLAlbum*)item sortedTracks];
                    NSUInteger trackCount = tracks.count;
                    for (NSUInteger x = 0; x < trackCount; x++) {
                        nameRange = [self _processItem:tracks[x] withString:searchString];
                        if (nameRange.location != NSNotFound)
                            break;
                    }
                }
            }
        } else if ([item isKindOfClass:[MLShow class]]) {
            nameRange = [[(MLShow*)item name] rangeOfString:searchString options:NSCaseInsensitiveSearch];

            /* user didn't search for our show name, let's do a deeper search */
            if (nameRange.location == NSNotFound) {
                NSArray *episodes = [(MLShow*)item sortedEpisodes];
                NSUInteger episodeCount = episodes.count;
                NSString *name;
                for (NSUInteger x = 0; x < episodeCount; x++) {
                    name = [(MLShowEpisode*)episodes[x] name];
                    if (name)
                        nameRange = [name rangeOfString:searchString options:NSCaseInsensitiveSearch];
                    if (nameRange.location != NSNotFound) {
                        break;
                    }
                }
            }
        } else if ([item isKindOfClass:[MLLabel class]]) {
            nameRange = [[(MLLabel*)item name] rangeOfString:searchString options:NSCaseInsensitiveSearch];

            /* user didn't search for our label name, let's do a deeper search */
            if (nameRange.location == NSNotFound) {
                NSArray *files = [(MLLabel*)item sortedFolderItems];
                NSUInteger fileCount = files.count;
                for (NSUInteger x = 0; x < fileCount; x++) {
                    nameRange = [self _processItem:files[x] withString:searchString];
                    if (nameRange.location != NSNotFound)
                        break;
                }
            }
        } else // simple file
            nameRange = [self _processItem:(MLFile*)item withString:searchString];

        if (nameRange.location != NSNotFound)
            [_searchData addObject:item];
    }

    return YES;
}

- (NSRange)_processItem:(NSManagedObject *)file withString:(NSString *)searchString
{
    NSRange nameRange;
    nameRange = [[(MLFile *)file title] rangeOfString:searchString options:NSCaseInsensitiveSearch];
    if (nameRange.location == NSNotFound) {
        NSString *artist = [(MLFile *)file artist];
        if (artist)
            nameRange = [artist rangeOfString:searchString options:NSCaseInsensitiveSearch];
        if (nameRange.location == NSNotFound && ![file isKindOfClass:[MLAlbumTrack class]]) {
            NSString *releaseYear = [(MLFile *)file releaseYear];
            if (releaseYear)
                nameRange = [releaseYear rangeOfString:searchString options:NSCaseInsensitiveSearch];
        }
    }

    return nameRange;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    tableView.rowHeight = 90.;
    tableView.backgroundColor = [UIColor blackColor];
}

@end
