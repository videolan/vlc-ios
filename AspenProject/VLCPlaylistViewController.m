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
#import "VLCPlaylistGridView.h"
#import "VLCMenuViewController.h"
#import "UINavigationController+Theme.h"
#import "NSString+SupportedMedia.h"

@implementation EmptyLibraryView
@end

@interface VLCPlaylistViewController () <AQGridViewDataSource, AQGridViewDelegate,
                                         UITableViewDataSource, UITableViewDelegate> {
    NSMutableArray *_foundMedia;
}
@end

@implementation VLCPlaylistViewController

- (void)loadView {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        self.view = _tableView;
    } else {
        _gridView = [[AQGridView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _gridView.delegate = self;
        _gridView.dataSource = self;
        _gridView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"libraryBackground"]];
        self.view = _gridView;
    }

    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.emptyLibraryView = [[[NSBundle mainBundle] loadNibNamed:@"VLCEmptyLibraryView" owner:self options:nil] lastObject];
}

#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menuCone"] style:UIBarButtonItemStyleBordered target:self action:@selector(leftButtonAction:)];
    [addButton setBackgroundImage:[UIImage imageNamed:@"button"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [addButton setBackgroundImage:[UIImage imageNamed:@"buttonHighlight"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];

    /* After day 354 of the year, the usual VLC cone is replaced by another cone
     * wearing a Father Xmas hat.
     * Note: this icon doesn't represent an endorsement of The Coca-Cola Company
     * and should not be confused with the idea of religious statements or propagation there off
     */
    NSCalendar *gregorian =
    [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSUInteger dayOfYear = [gregorian ordinalityOfUnit:NSDayCalendarUnit inUnit:NSYearCalendarUnit forDate:[NSDate date]];
    if (dayOfYear >= 354)
        addButton.image = [UIImage imageNamed:@"vlc-xmas"];

    self.navigationItem.leftBarButtonItem = addButton;

    [self.editButtonItem setBackgroundImage:[UIImage imageNamed:@"button"]
                                   forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [self.editButtonItem setBackgroundImage:[UIImage imageNamed:@"buttonHighlight"]
                                   forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _gridView.separatorStyle = AQGridViewCellSeparatorStyleEmptySpace;
        _gridView.alwaysBounceVertical = YES;
        _gridView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    } else {
        _tableView.rowHeight = [VLCPlaylistTableViewCell heightOfCell];
        _tableView.separatorColor = [UIColor colorWithWhite:.122 alpha:1.];
    }
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"title"]];

    _emptyLibraryView.emptyLibraryLabel.text = NSLocalizedString(@"EMPTY_LIBRARY", @"");
    _emptyLibraryView.emptyLibraryLongDescriptionLabel.lineBreakMode = UILineBreakModeWordWrap;
    _emptyLibraryView.emptyLibraryLongDescriptionLabel.numberOfLines = 0;
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
    [self performSelector:@selector(updateViewContents) withObject:nil afterDelay:.0];
    [[MLMediaLibrary sharedMediaLibrary] performSelector:@selector(libraryDidAppear) withObject:nil afterDelay:1.];

    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[MLMediaLibrary sharedMediaLibrary] libraryDidDisappear];
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
    if (_foundMedia.count > 0) {
        if (self.emptyLibraryView.superview)
            [self.emptyLibraryView removeFromSuperview];

        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    } else {
        self.emptyLibraryView.frame = self.view.frame;
        [self.view addSubview:self.emptyLibraryView];
        self.navigationItem.rightBarButtonItem = nil;
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _tableView.separatorStyle = (_foundMedia.count > 0)? UITableViewCellSeparatorStyleSingleLine:
                                                             UITableViewCellSeparatorStyleNone;
    }
}

- (void)updateViewContents
{
    _foundMedia = [NSMutableArray arrayWithArray:[MLFile allFiles]];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [self.tableView reloadData];
    else {
        [self.gridView reloadData];
        [self.gridView setNeedsLayout];
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
    MLFile *mediaObject = _foundMedia[indexPath.row];
    if (!self.movieViewController)
        self.movieViewController = [[VLCMovieViewController alloc] initWithNibName:nil bundle:nil];

    self.movieViewController.mediaItem = mediaObject;
    [self.navigationController pushViewController:self.movieViewController animated:YES];
}

#pragma mark - AQGridView
- (NSUInteger)numberOfItemsInGridView:(AQGridView *)gridView
{
    return _foundMedia.count;
}

- (AQGridViewCell *)gridView:(AQGridView *)gridView cellForItemAtIndex:(NSUInteger)index
{
    static NSString *AQCellIdentifier = @"AQPlaylistCell";

    VLCPlaylistGridView *cell = (VLCPlaylistGridView *)[gridView dequeueReusableCellWithIdentifier:AQCellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"VLCPlaylistGridView" owner:self options:nil] lastObject];
        cell.selectionStyle = AQGridViewCellSelectionStyleNone;
        cell.gridView = gridView;
    }

    cell.mediaObject = _foundMedia[index];

    return cell;
}

- (CGSize)portraitGridCellSizeForGridView:(AQGridView *)gridView
{
    return [VLCPlaylistGridView preferredSize];
}

- (void)gridView:(AQGridView *)gridView didSelectItemAtIndex:(NSUInteger)index
{
    [self.gridView deselectItemAtIndex:index animated:YES];

    MLFile *mediaObject = _foundMedia[index];
    if (!self.movieViewController)
        self.movieViewController = [[VLCMovieViewController alloc] initWithNibName:nil bundle:nil];

    self.movieViewController.mediaItem = mediaObject;
    [self.navigationController pushViewController:self.movieViewController animated:YES];
}

- (void)gridView:(AQGridView *)aGridView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndex:(NSUInteger)index
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
        [self removeMediaObject: _foundMedia[index]];
}

#pragma mark - UI implementation
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    UIBarButtonItem *editButton = self.editButtonItem;
    NSString *editImage = editing? @"doneButton": @"button";
    NSString *editImageHighlight = editing? @"doneButtonHighlight": @"buttonHighlight";
    [editButton setBackgroundImage:[UIImage imageNamed:editImage] forState:UIControlStateNormal
                                 barMetrics:UIBarMetricsDefault];
    [editButton setBackgroundImage:[UIImage imageNamed:editImageHighlight]
                                   forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    [editButton setTitleTextAttributes: editing ? @{UITextAttributeTextShadowColor : [UIColor whiteColor], UITextAttributeTextColor : [UIColor blackColor]} : @{UITextAttributeTextShadowColor : [UIColor colorWithWhite:0. alpha:.37], UITextAttributeTextColor : [UIColor whiteColor]} forState:UIControlStateNormal];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [self.gridView setEditing:editing];
    else
        [self.tableView setEditing:editing animated:YES];
}

- (IBAction)leftButtonAction:(id)sender
{
    if (self.menuViewController == nil) {
        VLCMenuViewController *menuViewController = [[VLCMenuViewController alloc] initWithNibName:nil bundle:nil];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:menuViewController];
        [navigationController loadTheme];
        self.menuViewController = navigationController;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            navigationController.navigationBarHidden = YES;
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.menuViewController.contentSizeForViewInPopover = self.menuViewController.view.frame.size;
        if (self.addMediaPopoverController == nil) {
            self.addMediaPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.menuViewController];
            self.addMediaPopoverController.delegate = self;
        }

        if (self.addMediaPopoverController.popoverVisible)
            [self.addMediaPopoverController dismissPopoverAnimated:YES];
        else
            [self.addMediaPopoverController presentPopoverFromBarButtonItem:self.navigationItem.leftBarButtonItem
                                                   permittedArrowDirections:UIPopoverArrowDirectionUp
                                                                   animated:YES];
    } else
        [self.navigationController presentViewController:self.menuViewController animated:YES completion:NULL];
}

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

#pragma mark - coin coin

- (void)openMovieFromURL:(NSURL *)url
{
    if (!self.movieViewController)
        self.movieViewController = [[VLCMovieViewController alloc] initWithNibName:nil bundle:nil];

    self.movieViewController.url = url;
    [self.navigationController pushViewController:self.movieViewController animated:YES];
}


@end
