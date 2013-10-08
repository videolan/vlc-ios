//
//  VLCMasterViewController.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCPlaylistViewController.h"
#import "VLCMovieViewController.h"
#import "VLCPlaylistTableViewCell.h"
#import "VLCPlaylistCollectionViewCell.h"
#import "UINavigationController+Theme.h"
#import "NSString+SupportedMedia.h"
#import "VLCBugreporter.h"
#import "VLCAppDelegate.h"
#import "UIBarButtonItem+Theme.h"

#ifndef UIStatusBarStyleLightContent
#define UIStatusBarStyleLightContent 1
#endif

@implementation EmptyLibraryView
@end

@interface VLCPlaylistViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate, MLMediaLibrary> {
    NSMutableArray *_foundMedia;
    VLCLibraryMode _libraryMode;
    UIBarButtonItem *_menuButton;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) EmptyLibraryView *emptyLibraryView;

@end

@implementation VLCPlaylistViewController

- (void)loadView {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];
        _tableView.rowHeight = [VLCPlaylistTableViewCell heightOfCell];
        _tableView.separatorColor = [UIColor colorWithWhite:.122 alpha:1.];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        self.view = _tableView;
    } else {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];

        _collectionView = [[UICollectionView alloc] initWithFrame:[UIScreen mainScreen].bounds collectionViewLayout:flowLayout];
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        self.view = _collectionView;

        if (SYSTEM_RUNS_IN_THE_FUTURE)
            [_collectionView registerNib:[UINib nibWithNibName:@"VLCFuturePlaylistCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"PlaylistCell"];
        else
            [_collectionView registerNib:[UINib nibWithNibName:@"VLCPlaylistCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"PlaylistCell"];


        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"libraryBackground"]];
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

    /* After day 354 of the year, the usual VLC cone is replaced by another cone
     * wearing a Father Xmas hat.
     * Note: this icon doesn't represent an endorsement of The Coca-Cola Company
     * and should not be confused with the idea of religious statements or propagation there off
     */
    NSCalendar *gregorian =
    [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSUInteger dayOfYear = [gregorian ordinalityOfUnit:NSDayCalendarUnit inUnit:NSYearCalendarUnit forDate:[NSDate date]];
    if (dayOfYear >= 354)
        _menuButton.image = [UIImage imageNamed:@"vlc-xmas"];

    self.navigationItem.leftBarButtonItem = _menuButton;

    if (SYSTEM_RUNS_IN_THE_FUTURE)
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _displayEmptyLibraryViewIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

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

    if (SYSTEM_RUNS_IN_THE_FUTURE)
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
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
        _foundMedia = [NSMutableArray arrayWithArray:[[(MLAlbum *)mediaObject tracks] allObjects]];
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(backToAllItems:)];
        [self.navigationItem.leftBarButtonItem setTitle:NSLocalizedString(@"LIBRARY_MUSIC", @"")];
        self.title = [(MLAlbum*)mediaObject name];
        [self reloadViews];
    } else if ([mediaObject isKindOfClass:[MLShow class]]) {
        _foundMedia = [NSMutableArray arrayWithArray:[[(MLShow *)mediaObject episodes] allObjects]];
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem themedBackButtonWithTarget:self andSelector:@selector(backToAllItems:)];
        [self.navigationItem.leftBarButtonItem setTitle:NSLocalizedString(@"LIBRARY_SERIES", @"")];
        self.title = [(MLShow*)mediaObject name];
        [self reloadViews];
    } else {
        if (!self.movieViewController)
            self.movieViewController = [[VLCMovieViewController alloc] initWithNibName:nil bundle:nil];

        if ([mediaObject isKindOfClass:[MLFile class]])
            self.movieViewController.mediaItem = (MLFile *)mediaObject;
        else if ([mediaObject isKindOfClass:[MLAlbumTrack class]])
            self.movieViewController.mediaItem = [(MLAlbumTrack*)mediaObject files].anyObject;
        else if ([mediaObject isKindOfClass:[MLShowEpisode class]])
            self.movieViewController.mediaItem = [(MLShowEpisode*)mediaObject files].anyObject;

        [self.navigationController pushViewController:self.movieViewController animated:YES];
    }
}

- (void)removeMediaObject:(MLFile *)mediaObject
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folderLocation = [[[NSURL URLWithString:mediaObject.url] path] stringByDeletingLastPathComponent];
    NSArray *allfiles = [fileManager contentsOfDirectoryAtPath:folderLocation error:nil];
    NSString *fileName = [[[[NSURL URLWithString:mediaObject.url] path] lastPathComponent] stringByDeletingPathExtension];
    NSIndexSet *indexSet = [allfiles indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
       return ([obj rangeOfString:fileName].location != NSNotFound);
    }];
    unsigned int count = indexSet.count;
    NSString *additionalFilePath;
    NSUInteger currentIndex = [indexSet firstIndex];
    for (unsigned int x = 0; x < count; x++) {
        additionalFilePath = allfiles[currentIndex];
        if ([additionalFilePath isSupportedSubtitleFormat])
            [fileManager removeItemAtPath:[folderLocation stringByAppendingPathComponent:additionalFilePath] error:nil];
        currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
    [fileManager removeItemAtPath:[[NSURL URLWithString:mediaObject.url] path] error:nil];
    [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];
    [self updateViewContents];
}

- (void)_displayEmptyLibraryViewIfNeeded
{
    if (self.emptyLibraryView.superview)
        [self.emptyLibraryView removeFromSuperview];

    if (_foundMedia.count == 0) {
        self.emptyLibraryView.frame = self.view.bounds;
        [self.view addSubview:self.emptyLibraryView];
    }
    if (_libraryMode == VLCLibraryModeAllFiles && _foundMedia.count > 0)
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    else
        self.navigationItem.rightBarButtonItem = nil;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _tableView.separatorStyle = (_foundMedia.count > 0)? UITableViewCellSeparatorStyleSingleLine:
                                                             UITableViewCellSeparatorStyleNone;
    }
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
    NSLog(@"libraryWasUpdated");
    [self updateViewContents];
}

- (void)updateViewContents
{
    if (_libraryMode == VLCLibraryModeAllAlbums) {
        NSArray *rawAlbums = [MLAlbum allAlbums];
        _foundMedia = [[NSMutableArray alloc] init];
        for (MLAlbum *album in rawAlbums) {
            if (album.name.length > 0 && album.tracks.count > 0)
                [_foundMedia addObject:album];
        }

    } else if (_libraryMode == VLCLibraryModeAllSeries) {
        NSArray *rawShows = [MLShow allShows];
        _foundMedia = [[NSMutableArray alloc] init];
        for (MLShow *show in rawShows) {
            if (show.name.length > 0 && show.episodes.count > 0)
                [_foundMedia addObject:show];
        }
    } else
        _foundMedia = [NSMutableArray arrayWithArray:[MLFile allFiles]];

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

    NSInteger row = indexPath.row;
    cell.mediaObject = _foundMedia[row];

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor colorWithWhite:.122 alpha:1.];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
        [self removeMediaObject: _foundMedia[indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSManagedObject *selectedObject = _foundMedia[indexPath.row];
    [self openMediaObject:selectedObject];
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
    if (SYSTEM_RUNS_IN_THE_FUTURE)
        return CGSizeMake(334.0, 191.0);

    return CGSizeMake(298.0, 220.0);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    if (SYSTEM_RUNS_IN_THE_FUTURE)
        return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    return UIEdgeInsetsMake(0.0, 34.0, 0.0, 34.0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    if (SYSTEM_RUNS_IN_THE_FUTURE)
        return 0.0;
    return 10.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    if (SYSTEM_RUNS_IN_THE_FUTURE)
        return 0.0;
    return 10.0;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *selectedObject = _foundMedia[indexPath.row];
    [self openMediaObject:selectedObject];
}

#pragma mark - UI implementation
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (_libraryMode != VLCLibraryModeAllFiles)
        return;

    [super setEditing:editing animated:animated];

    UIBarButtonItem *editButton = self.editButtonItem;
    NSString *editImage = editing? @"doneButton": @"button";
    NSString *editImageHighlight = editing? @"doneButtonHighlight": @"buttonHighlight";
    if (SYSTEM_RUNS_IN_THE_FUTURE)
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
    } else
        [self.tableView setEditing:editing animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_libraryMode != VLCLibraryModeAllFiles)
        return UITableViewCellEditingStyleNone;

    return UITableViewCellEditingStyleDelete;
}

- (IBAction)leftButtonAction:(id)sender
{
    [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController] toggleSidebar:![(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController].sidebarShowing duration:kGHRevealSidebarDefaultAnimationDuration];
}

- (IBAction)backToAllItems:(id)sender
{
    self.navigationItem.leftBarButtonItem = _menuButton;
    [self setLibraryMode:_libraryMode];
}

#pragma mark - coin coin

- (void)openMovieFromURL:(NSURL *)url
{
    if (!self.movieViewController)
        self.movieViewController = [[VLCMovieViewController alloc] initWithNibName:nil bundle:nil];

    if (self.navigationController.topViewController != self.movieViewController)
        [self.navigationController pushViewController:self.movieViewController animated:YES];

    self.movieViewController.url = url;
}

- (void)setLibraryMode:(VLCLibraryMode)mode
{
    _libraryMode = mode;

    if (_libraryMode == VLCLibraryModeAllAlbums)
        self.title = NSLocalizedString(@"LIBRARY_MUSIC", @"");
    else if( _libraryMode == VLCLibraryModeAllSeries)
        self.title = NSLocalizedString(@"LIBRARY_SERIES", @"");
    else
        self.title = NSLocalizedString(@"LIBRARY_ALL_FILES", @"");

    [self updateViewContents];
}

#pragma mark - autorotation
/* deprecated in iOS 6 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;

    return (_foundMedia.count > 0) || toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

// RootController is responsible for supporting interface orientation(iOS6.0+), i.e. navigation controller
// so this will not work as intended without "voodoo magic"(UINavigationController category, subclassing, etc)
/* introduced in iOS 6 */
- (NSUInteger)supportedInterfaceOrientations {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;

    return (_foundMedia.count > 0)? UIInterfaceOrientationMaskAllButUpsideDown:
    UIInterfaceOrientationMaskPortrait;
}

/* introduced in iOS 6 */
- (BOOL)shouldAutorotate {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) || (_foundMedia.count > 0);
}

@end
