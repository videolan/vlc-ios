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
#import "VLCPlaylistGridViewCell.h"
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

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About",@"") style:UIBarButtonItemStyleBordered target:self action:@selector(showAboutView:)];
    self.navigationItem.leftBarButtonItem = addButton;

    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        _gridView.separatorStyle = AQGridViewCellSeparatorStyleEmptySpace;
        _gridView.alwaysBounceVertical = YES;
        _gridView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    } else {
        self.tabBar.selectedItem = self.localFilesBarItem;
        self.networkStreamsBarItem.title = NSLocalizedString(@"Network",@"");
    }
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
    static NSString *CellIdentifier = @"Cell";

    VLCPlaylistTableViewCell *cell = (VLCPlaylistTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCPlaylistTableViewCell cellWithReuseIdentifier:CellIdentifier];

    MLFile *object = _foundMedia[indexPath.row];
    cell.titleLabel.text = object.title;
    cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ — %.2f MB", [VLCTime timeWithNumber:[object duration]], [object fileSizeInBytes] / 2e6];
    cell.thumbnailView.image = object.computedThumbnail;
    cell.progressIndicator.progress = object.lastPosition.floatValue;
    if (cell.progressIndicator.progress < 0.1f)
        cell.progressIndicator.hidden = YES;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSUInteger row = indexPath.row;
        MLFile *mediaObject = _foundMedia[row];
        [[NSFileManager defaultManager] removeItemAtPath:[[NSURL URLWithString:mediaObject.url] path] error:nil];
        [_foundMedia removeObjectAtIndex:row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.gridView deleteItemsAtIndices:[NSIndexSet indexSetWithIndex:row] withAnimation:AQGridViewItemAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MLFile *mediaObject = _foundMedia[indexPath.row];
    if (!self.movieViewController) {
        self.movieViewController = [[VLCMovieViewController alloc] initWithNibName:@"VLCMovieViewController" bundle:nil];
    }
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
    static NSString *AQCellIdentifier = @"AQCell";

    VLCPlaylistGridViewCell *cell = (VLCPlaylistGridViewCell *)[gridView dequeueReusableCellWithIdentifier:AQCellIdentifier];
    if (cell == nil) {
        cell = [[VLCPlaylistGridViewCell alloc] initWithFrame:CGRectMake(0.0, 0.0, 384.,216.) reuseIdentifier:AQCellIdentifier];
        cell.selectionStyle = AQGridViewCellSelectionStyleBlueGray;
    }

    MLFile *object = _foundMedia[index];
    cell.title = object.title;
    cell.subtitle = [NSString stringWithFormat:@"%@ — %.2f MB", [VLCTime timeWithNumber:[object duration]], [object fileSizeInBytes] / 2e6];
    cell.thumbnail = object.computedThumbnail;

    return cell;
}

- (CGSize)portraitGridCellSizeForGridView:(AQGridView *)gridView
{
    static CGSize cellSize = { 384., 216. };
    return cellSize;
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
    if (self.tableView.editing) {
        self.editButtonItem.style = UIBarButtonItemStylePlain;
        self.editButtonItem.title = NSLocalizedString(@"Edit",@"");
        [self.tableView setEditing:NO animated:YES];
    } else {
        self.editButtonItem.style = UIBarButtonItemStyleDone;
        self.editButtonItem.title = NSLocalizedString(@"Done",@"");
        [self.tableView setEditing:YES animated:YES];
    }
}

- (void)showAboutView:(id)sender
{
    if (!self.aboutViewController)
        self.aboutViewController = [[VLCAboutViewController alloc] initWithNibName:@"VLCAboutViewController" bundle:nil];
    [self.navigationController pushViewController:self.aboutViewController animated:YES];
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
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Open URL?" message:messageString delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open", nil];
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
