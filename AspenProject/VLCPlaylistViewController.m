//
//  VLCMasterViewController.m
//  AspenProject
//
//  Created by Felix Paul Kühne on 27.02.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

#import "VLCPlaylistViewController.h"
#import "VLCMovieViewController.h"
#import "VLCPlaylistTableViewCell.h"
#import "VLCPlaylistGridView.h"
#import "VLCAboutViewController.h"

@interface VLCPlaylistViewController () {
    NSMutableArray *_foundMedia;
}
@end

@implementation VLCPlaylistViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
        self.title = @"Aspen";

    return self;
}

- (void)viewDidLoad
{
    self.tableView.rowHeight = [VLCPlaylistTableViewCell heightOfCell];
    self.tableView.separatorColor = [UIColor colorWithWhite:.2 alpha:1.];
    [super viewDidLoad];

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BUTTON_ABOUT",@"") style:UIBarButtonItemStyleBordered target:self action:@selector(showAboutView:)];
    self.navigationItem.leftBarButtonItem = addButton;

    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        _gridView.separatorStyle = AQGridViewCellSeparatorStyleEmptySpace;
        _gridView.alwaysBounceVertical = YES;
        _gridView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    }

    self.tabBar.selectedItem = self.localFilesBarItem;
    self.networkStreamsBarItem.title = NSLocalizedString(@"TABBAR_NETWORK",@"");

    self.emptyLibraryLabel.text = NSLocalizedString(@"EMPTY_LIBRARY", @"");
    self.emptyLibraryLongDescriptionLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.emptyLibraryLongDescriptionLabel.numberOfLines = 0;
    self.emptyLibraryLongDescriptionLabel.text = NSLocalizedString(@"EMPTY_LIBRARY_LONG", @"");
    [self.emptyLibraryLongDescriptionLabel sizeToFit];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.gridView deselectItemAtIndex:self.gridView.indexOfSelectedItem animated:animated];
    [super viewWillAppear:animated];

    [self _displayEmptyLibraryViewIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self performSelector:@selector(updateViewContents) withObject:nil afterDelay:.3];
    [[MLMediaLibrary sharedMediaLibrary] performSelector:@selector(libraryDidAppear) withObject:nil afterDelay:1.];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[MLMediaLibrary sharedMediaLibrary] libraryDidDisappear];
}

- (void)removeMediaObject:(MLFile *)mediaObject
{
    [[NSFileManager defaultManager] removeItemAtPath:[[NSURL URLWithString:mediaObject.url] path] error:nil];

    [self updateViewContents];
    [self _displayEmptyLibraryViewIfNeeded];
}

- (void)_displayEmptyLibraryViewIfNeeded
{
    if (_foundMedia.count > 0) {
        if (self.emptyLibraryView.superview)
            [self.emptyLibraryView removeFromSuperview];
    } else {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            self.emptyLibraryView.frame = self.tableView.frame;
        else
            self.emptyLibraryView.frame = self.gridView.frame;
        [self.view addSubview:self.emptyLibraryView];
    }
}

#pragma mark - Table View

- (void)updateViewContents
{
    [[MLMediaLibrary sharedMediaLibrary] updateMediaDatabase];

    _foundMedia = [NSMutableArray arrayWithArray:[MLFile allFiles]];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        [self.tableView reloadData];
    else
        [self.gridView reloadData];
}

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

    cell.mediaObject = _foundMedia[indexPath.row];

    return cell;
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
        self.movieViewController = [[VLCMovieViewController alloc] initWithNibName:@"VLCMovieViewController" bundle:nil];

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
        cell.selectionStyle = AQGridViewCellSelectionStyleGlow;
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
    MLFile *mediaObject = _foundMedia[index];
    if (!self.movieViewController)
        self.movieViewController = [[VLCMovieViewController alloc] initWithNibName:@"VLCMovieViewController" bundle:nil];

    self.movieViewController.mediaItem = mediaObject;
    [self.navigationController pushViewController:self.movieViewController animated:YES];
}

#pragma mark - UI implementation
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (_editMode != editing)
        _editMode = editing;
    else
        _editMode = !editing;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.gridView setEditing:_editMode];
    } else {
        [self.tableView setEditing:_editMode animated:YES];
    }

    if (_editMode) {
        self.editButtonItem.style = UIBarButtonItemStyleDone;
        self.editButtonItem.title = NSLocalizedString(@"BUTTON_DONE",@"");
    } else {
        self.editButtonItem.style = UIBarButtonItemStylePlain;
        self.editButtonItem.title = NSLocalizedString(@"BUTTON_EDIT",@"");
    }
}

- (void)showAboutView:(id)sender
{
    if (!self.aboutViewController)
        self.aboutViewController = [[VLCAboutViewController alloc] initWithNibName:@"VLCAboutViewController" bundle:nil];
    [self.navigationController pushViewController:self.aboutViewController animated:YES];
}

/* deprecated in iOS 6 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (_foundMedia.count > 0)
        return YES;
    else
        return NO;
}

/* introduced in iOS 6 */
- (NSUInteger)supportedInterfaceOrientations {
    if (_foundMedia.count > 0)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

/* introduced in iOS 6 */
- (BOOL)shouldAutorotate {
    if (_foundMedia.count > 0)
        return YES;
    else
        return NO;
}

#pragma mark - tab bar
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (item == self.networkStreamsBarItem) {
        if ([[UIPasteboard generalPasteboard] containsPasteboardTypes:[NSArray arrayWithObjects:@"public.url", @"public.text", nil]]) {
            _pasteURL = [[UIPasteboard generalPasteboard] valueForPasteboardType:@"public.url"];
            if (!_pasteURL || [[_pasteURL absoluteString] isEqualToString:@""]) {
                NSString * pasteString = [[UIPasteboard generalPasteboard] valueForPasteboardType:@"public.text"];
                _pasteURL = [NSURL URLWithString:pasteString];
            }

            if (_pasteURL && ![[_pasteURL scheme] isEqualToString:@""] && ![[_pasteURL absoluteString] isEqualToString:@""]) {
                NSString * messageString = [NSString stringWithFormat:@"Do you want to open %@?", [_pasteURL absoluteString]];
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"OPEN_URL", @"") message:messageString delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"") otherButtonTitles:NSLocalizedString(@"BUTTON_OPEN", @""), nil];
                [alert show];
            }
        }
    }

    self.tabBar.selectedItem = self.localFilesBarItem;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
        [self openMovieFromURL:_pasteURL];
}

- (void)openMovieFromURL:(NSURL *)url
{
    if (!self.movieViewController)
        self.movieViewController = [[VLCMovieViewController alloc] initWithNibName:@"VLCMovieViewController" bundle:nil];

    self.movieViewController.url = url;
    [self.navigationController pushViewController:self.movieViewController animated:YES];
}

@end
