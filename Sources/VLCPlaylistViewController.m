/*****************************************************************************
 * VLCPlaylistViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2014 VideoLAN. All rights reserved.
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

@interface VLCPlaylistViewController () <VLCFolderCollectionViewDelegateFlowLayout, LXReorderableCollectionViewDataSource, LXReorderableCollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate, MLMediaLibrary> {
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];
        _tableView.rowHeight = [VLCPlaylistTableViewCell heightOfCell];
        _tableView.separatorColor = [UIColor colorWithWhite:.122 alpha:1.];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.opaque = YES;
        self.view = _tableView;

        if (SYSTEM_RUNS_IOS7_OR_LATER) {
            UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(tableViewLongTouchGestureAction:)];
            [self.view addGestureRecognizer:gestureRecognizer];
        }
    } else {
        _folderLayout = [[VLCFolderCollectionViewFlowLayout alloc] init];
        _collectionView = [[UICollectionView alloc] initWithFrame:[UIScreen mainScreen].bounds collectionViewLayout:_folderLayout];
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.opaque = YES;
        _collectionView.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];
        self.view = _collectionView;
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_collectionViewHandleLongPressGesture:)];
        [_collectionView addGestureRecognizer:_longPressGestureRecognizer];
        if (SYSTEM_RUNS_IOS7_OR_LATER)
            [_collectionView registerNib:[UINib nibWithNibName:@"VLCFuturePlaylistCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"PlaylistCell"];
        else
            [_collectionView registerNib:[UINib nibWithNibName:@"VLCPlaylistCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"PlaylistCell"];
        self.view.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];
    }

    _libraryMode = VLCLibraryModeAllFiles;

    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.emptyLibraryView = [[[NSBundle mainBundle] loadNibNamed:@"VLCEmptyLibraryView" owner:self options:nil] lastObject];
    _emptyLibraryView.emptyLibraryLongDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _emptyLibraryView.emptyLibraryLongDescriptionLabel.numberOfLines = 0;
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"LIBRARY_ALL_FILES", @"");
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

    _emptyLibraryView.emptyLibraryLabel.text = NSLocalizedString(@"EMPTY_LIBRARY", @"");
    _emptyLibraryView.emptyLibraryLongDescriptionLabel.text = NSLocalizedString(@"EMPTY_LIBRARY_LONG", @"");
    [_emptyLibraryView.emptyLibraryLongDescriptionLabel sizeToFit];
    [_emptyLibraryView.learnMoreButton setTitle:NSLocalizedString(@"BUTTON_LEARN_MORE", @"") forState:UIControlStateNormal];
    UIBarButtonItem *createFolderItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(createFolder)];
    [self setToolbarItems:@[createFolderItem, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], [UIBarButtonItem themedDarkToolbarButtonWithTitle:NSLocalizedString(@"BUTTON_RENAME", @"") target:self andSelector:@selector(renameSelection)], [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteSelection)]]];
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;

    if (SYSTEM_RUNS_IOS7_OR_LATER) {
        self.navigationController.toolbar.tintColor = [UIColor whiteColor];
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    } else
        [self.navigationController.toolbar setBackgroundImage:[UIImage imageNamed:@"bottomBlackBar"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
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
        self.emptyLibraryView.emptyLibraryLabel.text = NSLocalizedString(@"UPGRADING_LIBRARY", @"");
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
            self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"BUTTON_BACK", @"");
        else
            [self.navigationItem.leftBarButtonItem setTitle:NSLocalizedString(@"LIBRARY_MUSIC", @"")];
        self.title = [(MLAlbum*)mediaObject name];
        [self reloadViews];
    } else if ([mediaObject isKindOfClass:[MLShow class]]) {
        _foundMedia = [NSMutableArray arrayWithArray:[(MLShow *)mediaObject sortedEpisodes]];
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(backToAllItems:)];
        if (_libraryMode == VLCLibraryModeAllFiles)
            self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"BUTTON_BACK", @"");
        else
            [self.navigationItem.leftBarButtonItem setTitle:NSLocalizedString(@"LIBRARY_SERIES", @"")];
        self.title = [(MLShow*)mediaObject name];
        [self reloadViews];
    } else if ([mediaObject isKindOfClass:[MLLabel class]]) {
        MLLabel *folder = (MLLabel*) mediaObject;
        inFolder = YES;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers) {
                if (recognizer == _folderLayout.panGestureRecognizer || recognizer == _folderLayout.longPressGestureRecognizer || recognizer == _longPressGestureRecognizer)
                    [self.collectionView removeGestureRecognizer:recognizer];
            }
            _reorderLayout = [[LXReorderableCollectionViewFlowLayout alloc] init];
            [self.collectionView setCollectionViewLayout:_reorderLayout animated:NO];
            _folderLayout = nil;
        }
        _foundMedia = [NSMutableArray arrayWithArray:[folder sortedFolderItems]];
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(backToAllItems:)];
        self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"BUTTON_BACK", @"");
        self.title = [folder name];

        UIBarButtonItem *removeFromFolder = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(removeFromFolder)];
        NSMutableArray *toolbarItems = [self.toolbarItems mutableCopy];
        toolbarItems[0] = removeFromFolder;
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
        self.emptyLibraryView.emptyLibraryLabel.text = inFolder ? NSLocalizedString(@"FOLDER_EMPTY", @"") : NSLocalizedString(@"EMPTY_LIBRARY", @"");
        self.emptyLibraryView.emptyLibraryLongDescriptionLabel.text = inFolder ? NSLocalizedString(@"FOLDER_EMPTY_LONG", @"") : NSLocalizedString(@"EMPTY_LIBRARY_LONG", @"");
        self.emptyLibraryView.learnMoreButton.hidden = inFolder;
        self.emptyLibraryView.frame = self.view.bounds;
        [self.view addSubview:self.emptyLibraryView];
        self.navigationItem.rightBarButtonItem = nil;
    } else
        self.navigationItem.rightBarButtonItem = self.editButtonItem;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _tableView.separatorStyle = (_foundMedia.count > 0)? UITableViewCellSeparatorStyleSingleLine:
                                                             UITableViewCellSeparatorStyleNone;
    } else
        [self.collectionView.collectionViewLayout invalidateLayout];
}

- (void)libraryUpgradeComplete
{
    self.title = NSLocalizedString(@"LIBRARY_ALL_FILES", @"");
    self.navigationItem.leftBarButtonItem = _menuButton;
    self.emptyLibraryView.emptyLibraryLongDescriptionLabel.hidden = NO;
    self.emptyLibraryView.emptyLibraryLabel.text = NSLocalizedString(@"EMPTY_LIBRARY", @"");
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
        self.title = NSLocalizedString(@"LIBRARY_MUSIC", @"");
    else if( _libraryMode == VLCLibraryModeAllSeries)
        self.title = NSLocalizedString(@"LIBRARY_SERIES", @"");
    else
        self.title = NSLocalizedString(@"LIBRARY_ALL_FILES", @"");

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
                file.showEpisode.show.name = NSLocalizedString(@"UNTITLED_SHOW", @"");
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [self.tableView reloadData];
    else
        [self.collectionView reloadData];

    [self _displayEmptyLibraryViewIfNeeded];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _foundMedia.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PlaylistCell";

    VLCPlaylistTableViewCell *cell = (VLCPlaylistTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCPlaylistTableViewCell cellWithReuseIdentifier:CellIdentifier];

    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRightGestureAction:)];
    [swipeRight setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [cell addGestureRecognizer:swipeRight];

    NSInteger row = indexPath.row;
    cell.mediaObject = _foundMedia[row];

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor colorWithWhite:.122 alpha:1.];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.isEditing) {
        if (_libraryMode == VLCLibraryModeCreateFolder) {
            _folderObject = _foundMedia[indexPath.row];
            _libraryMode = _previousLibraryMode;
            [self updateViewContents];
            [self createFolderWithName:nil];
        }
        return;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSManagedObject *selectedObject = _foundMedia[indexPath.row];
    if ([selectedObject isKindOfClass:[MLAlbumTrack class]]) {
        VLCMediaList *list;
        NSArray *tracks = [[(MLAlbumTrack*)selectedObject album] sortedTracks];
        NSUInteger count = tracks.count;
        list = [[VLCMediaList alloc] init];

        MLFile *file;
        VLCMedia *media;
        for (NSInteger x = count - 1; x > -1; x--) {
            file = [(MLAlbumTrack*)tracks[x] files].anyObject;
            media = [VLCMedia mediaWithURL: [NSURL URLWithString:file.url]];
            [media parse];
            [list addMedia:media];
        }
        [(VLCAppDelegate*)[UIApplication sharedApplication].delegate openMediaList:list atIndex:(int)[tracks indexOfObject:selectedObject]];
    } else
        [self openMediaObject:selectedObject];
}

#pragma mark - table view gestures
- (void)tableViewLongTouchGestureAction:(UIGestureRecognizer *)recognizer
{
    NSIndexPath *path = [(UITableView *)self.view indexPathForRowAtPoint:[recognizer locationInView:self.view]];
    UITableViewCell *cell = [(UITableView *)self.view cellForRowAtIndexPath:path];

    CGRect frame = cell.frame;
    if (frame.size.height > 90.)
        frame.size.height = 90.;
    else if (recognizer.state == UIGestureRecognizerStateBegan)
        frame.size.height = 180;

    void (^animationBlock)() = ^() {
        cell.frame = frame;
    };

    void (^completionBlock)(BOOL finished) = ^(BOOL finished) {
        cell.frame = frame;
        [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionNone animated:YES];
    };

    NSTimeInterval animationDuration = .2;
    [UIView animateWithDuration:animationDuration animations:animationBlock completion:completionBlock];
 }

- (void)swipeRightGestureAction:(UIGestureRecognizer *)recognizer
{
    if ([[self.editButtonItem title] isEqualToString:NSLocalizedString(@"BUTTON_CANCEL",@"")])
        [self setEditing:NO animated:YES];
    else {
        [self setEditing:YES animated:YES];

        NSIndexPath *path = [(UITableView *)self.view indexPathForRowAtPoint:[recognizer locationInView:self.view]];
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:path.row inSection:path.section]
                                    animated:YES
                              scrollPosition:UITableViewScrollPositionNone];
    }
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
        return UIEdgeInsetsMake(0., 0., 0., 0.);
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
    if (self.editing) {
        if (_libraryMode == VLCLibraryModeCreateFolder) {
            _folderObject = _foundMedia[indexPath.item];
            _libraryMode = _previousLibraryMode;
            [self updateViewContents];
            [self createFolderWithName:nil];
        }
        [(VLCPlaylistCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath] selectionUpdate];
        return;
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
        NSArray *folderTracks = [folder.files allObjects];
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
    [(VLCPlaylistCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath] selectionUpdate];
}

- (void)collectionView:(UICollectionView *)collectionView removeItemFromFolderAtIndexPathIfNeeded:(NSIndexPath *)indexPath
{
    MLFile *mediaObject = (MLFile *)_foundMedia[indexPath.item];
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
    BOOL validFileTypeAtFolderPath = [_foundMedia[folderPath.item] isKindOfClass:[MLFile class]] || [_foundMedia[folderPath.item] isKindOfClass:[MLLabel class]];

    if (!(validFileTypeAtFolderPath && [_foundMedia[itemPath.item] isKindOfClass:[MLFile class]])) {
        VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"FOLDER_INVALID_TYPE_TITLE", @"") message:NSLocalizedString(@"FOLDER_INVALID_TYPE_MESSAGE", @"") cancelButtonTitle:nil otherButtonTitles:@[NSLocalizedString(@"BUTTON_OK", @"")]];

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

- (void)showCreateFolderAlert
{
    VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"FOLDER_CHOOSE_NAME_TITLE", @"") message:NSLocalizedString(@"FOLDER_CHOOSE_NAME_MESSAGE", @"") cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"") otherButtonTitles:@[NSLocalizedString(@"BUTTON_SAVE", @"")]];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[alert textFieldAtIndex:0] setText:NSLocalizedString(@"FOLDER_NAME_PLACEHOLDER", @"")];
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        _indexPaths = [NSMutableArray arrayWithArray:[self.collectionView indexPathsForSelectedItems]];
    else
        _indexPaths = [NSMutableArray arrayWithArray:[self.tableView indexPathsForSelectedRows]];

    for (NSIndexPath *path in _indexPaths) {
        id mediaObject;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            mediaObject = _foundMedia[path.item];
        else
            mediaObject = _foundMedia[path.row];
        if ([mediaObject isKindOfClass:[MLLabel class]])
            [_indexPaths removeObject:mediaObject];
    }

    if ([_indexPaths count] != 0) {
        NSArray *folder = [MLLabel allLabels];
        //if we already have folders display them
        if ([folder count] > 0) {
            _foundMedia = [NSMutableArray arrayWithArray:folder];
            self.title = NSLocalizedString(@"SELECT_FOLDER", @"");
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
    BOOL isPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    if (isPad)
        _indexPaths = [NSMutableArray arrayWithArray:[self.collectionView indexPathsForSelectedItems]];
    else
        _indexPaths = [NSMutableArray arrayWithArray:[self.tableView indexPathsForSelectedRows]];

    [_indexPaths sortUsingSelector:@selector(compare:)];

    for (int i = [_indexPaths count] - 1; i >= 0; i--) {
        NSIndexPath *path = _indexPaths[i];
        MLFile *file = (MLFile *)_foundMedia[isPad ? path.item : path.row];

        MLLabel *folder = [file.labels anyObject];
        file.labels = nil;
        file.folderTrackNumber = nil;
        [_foundMedia removeObject:file];

        if ([folder.files count] == 0) {
            [self removeMediaObject:folder updateDatabase:YES];
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
            VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"FOLDER_NAME_DUPLICATE_TITLE", @"") message:NSLocalizedString(@"FOLDER_NAME_DUPLICATE_MESSAGE", @"") cancelButtonTitle:nil otherButtonTitles:@[NSLocalizedString(@"BUTTON_OK", @"")]];

            alert.completion = ^(BOOL cancelled, NSInteger buttonIndex) {
                [self updateViewContents];
            };
            [alert show];
            return;
        }
    }

    if (_folderObject != nil) {
        int folderIndex = [_foundMedia indexOfObject:_folderObject];
        //item got dragged onto item
        if ([_foundMedia[folderIndex] isKindOfClass:[MLFile class]]) {
            MLFile *file = _foundMedia[folderIndex];
            MLLabel *label = [[MLMediaLibrary sharedMediaLibrary] createObjectForEntity:@"Label"];
            label.name = folderName;
            file.labels = [NSSet setWithObjects:label,nil];
            NSNumber *folderTrackNumber = [NSNumber numberWithInt:[label files].count - 1];
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

            for (int i = [_indexPaths count] - 1; i >= 0; i--) {
                NSIndexPath *path = _indexPaths[i];
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

            for (int i = [_indexPaths count] - 1; i >= 0; i--) {
                NSIndexPath *path = _indexPaths[i];
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
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
        [editButton setTitleTextAttributes: editing ? @{UITextAttributeTextShadowColor : [UIColor whiteColor], UITextAttributeTextColor : [UIColor blackColor]} : @{UITextAttributeTextShadowColor : [UIColor colorWithWhite:0. alpha:.37], UITextAttributeTextColor : [UIColor whiteColor]} forState:UIControlStateNormal];
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
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
        [self.editButtonItem setTitle:editing ? NSLocalizedString(@"BUTTON_CANCEL",@"") : NSLocalizedString(@"BUTTON_EDIT", @"")];
    }

    if (_libraryMode == VLCLibraryModeCreateFolder) {
        _libraryMode = _previousLibraryMode;
        _indexPaths = nil;
        [self updateViewContents];
    }

    self.navigationController.toolbarHidden = !editing;
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        //for some reason the Gesturerecognizer block themselves if not removed manually
        for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers) {
            if (recognizer == _reorderLayout.panGestureRecognizer || recognizer == _reorderLayout.longPressGestureRecognizer)
                [self.collectionView removeGestureRecognizer:recognizer];
        }
        _folderLayout = [[VLCFolderCollectionViewFlowLayout alloc] init];
        [self.collectionView setCollectionViewLayout:_folderLayout animated:NO];
        _reorderLayout = nil;
        [_collectionView addGestureRecognizer:_longPressGestureRecognizer];
    }
    inFolder = NO;
    UIBarButtonItem *createFolderItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(createFolder)];
    NSMutableArray *toolbarItems = [self.toolbarItems mutableCopy];
    toolbarItems[0] = createFolderItem;
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        indexPaths = [self.collectionView indexPathsForSelectedItems];
    else
        indexPaths = [self.tableView indexPathsForSelectedRows];

    if (indexPaths.count < 1) {
        [self _endEditingWithHardReset:NO];
        return;
    }

    NSString *itemName;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        itemName = [(VLCPlaylistCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPaths[0]] titleLabel].text;
    else
        itemName = [(VLCPlaylistTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPaths[0]] titleLabel].text;

    VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"RENAME_MEDIA_TO", @""), itemName] message:nil cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"") otherButtonTitles:@[NSLocalizedString(@"BUTTON_RENAME", @"")]];
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
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
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

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [self.collectionView deselectItemAtIndexPath:indexPaths[0] animated:YES];
    else
        [self.tableView deselectRowAtIndexPath:indexPaths[0] animated:YES];

    if (indexPaths.count > 1)
        [self renameSelection];
    else
        [self _endEditingWithHardReset:NO];
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

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [self.collectionView.collectionViewLayout invalidateLayout];
}

@end
