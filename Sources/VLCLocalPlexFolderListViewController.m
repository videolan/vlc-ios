/*****************************************************************************
 * VLCLocalPlexFolderListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalPlexFolderListViewController.h"
#import "VLCPlexMediaInformationViewController.h"
#import "VLCPlexParser.h"
#import "VLCPlexWebAPI.h"
#import "VLCLocalNetworkListCell.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"
#import "VLCDownloadViewController.h"
#import "NSString+SupportedMedia.h"
#import "VLCStatusLabel.h"
#import "UIDevice+VLC.h"

@interface VLCLocalPlexFolderListViewController () <UITableViewDataSource, UITableViewDelegate, VLCLocalNetworkListCell, UISearchBarDelegate, UISearchDisplayDelegate>
{
    NSArray *_globalObjectList;
    NSCache *_imageCache;

    NSString *_PlexServerName;
    NSString *_PlexServerAddress;
    NSString *_PlexServerPort;
    NSString *_PlexServerPath;
    NSString *_PlexAuthentification;

    VLCPlexParser *_PlexParser;
    VLCPlexWebAPI *_PlexWebAPI;

    NSMutableArray *_searchData;
    UISearchBar *_searchBar;
    UISearchDisplayController *_searchDisplayController;
    UIRefreshControl *_refreshControl;
    UIBarButtonItem *_menuButton;
}
@end

@implementation VLCLocalPlexFolderListViewController

- (void)loadView
{
    _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor VLCDarkBackgroundColor];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = [VLCLocalNetworkListCell heightOfCell];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    self.view = _tableView;
}

- (id)initWithPlexServer:(NSString *)serverName serverAddress:(NSString *)serverAddress portNumber:(NSString *)portNumber atPath:(NSString *)path authentification:(NSString *)auth
{
    self = [super init];
    if (self) {
        _PlexServerName = serverName;
        _PlexServerAddress = serverAddress;
        _PlexServerPort = portNumber;
        _PlexServerPath = path;

        _PlexAuthentification = auth;

        _globalObjectList = [[NSArray alloc] init];
        _imageCache = [[NSCache alloc] init];
        [_imageCache setCountLimit:50];

        _PlexParser = [[VLCPlexParser alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorColor = [UIColor VLCDarkBackgroundColor];
    self.view.backgroundColor = [UIColor VLCDarkBackgroundColor];

    _PlexWebAPI = [[VLCPlexWebAPI alloc] init];

    self.title = _PlexServerName;

    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    UINavigationBar *navBar = self.navigationController.navigationBar;
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        _searchBar.barTintColor = navBar.barTintColor;
    _searchBar.tintColor = navBar.tintColor;
    _searchBar.translucent = navBar.translucent;
    _searchBar.opaque = navBar.opaque;
    _searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
    _searchDisplayController.delegate = self;
    _searchDisplayController.searchResultsDataSource = self;
    _searchDisplayController.searchResultsDelegate = self;
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        _searchDisplayController.searchBar.searchBarStyle = UIBarStyleBlack;
    _searchDisplayController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _searchDisplayController.searchResultsTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    _searchBar.delegate = self;
    _searchBar.hidden = YES;
    //self.tableView.tableHeaderView = _searchBar;
    //self.tableView.contentOffset = CGPointMake(0, CGRectGetHeight(_searchBar.frame)); // -> hide search bar to load

    UITapGestureRecognizer *tapTwiceGesture = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(tapTwiceGestureAction:)];
    [tapTwiceGesture setNumberOfTapsRequired:2];
    [self.navigationController.navigationBar addGestureRecognizer:tapTwiceGesture];

    // Active le Pull down to refresh
    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.backgroundColor = [UIColor VLCDarkBackgroundColor];
    _refreshControl.tintColor = [UIColor whiteColor];
    // Call the refresh function
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:_refreshControl];

    _menuButton = [UIBarButtonItem themedRevealMenuButtonWithTarget:self andSelector:@selector(menuButtonAction:)];
    self.navigationItem.rightBarButtonItem = _menuButton;

    _globalObjectList = [[NSArray alloc] init];
    _searchData = [[NSMutableArray alloc] init];

    [self performSelectorInBackground:@selector(loadContents) withObject:nil];
}

- (void)loadContents
{
    _globalObjectList = [_PlexParser PlexMediaServerParser:_PlexServerAddress port:_PlexServerPort navigationPath:_PlexServerPath authentification:_PlexAuthentification];
    NSDictionary *firstObject = [_globalObjectList firstObject];

    if (_globalObjectList.count == 0 || firstObject == nil)
        _PlexAuthentification = @"";
    else
        _PlexAuthentification = [firstObject objectForKey:@"authentification"];

    NSString *titleValue;
    if ([_PlexServerPath isEqualToString:@""] || _globalObjectList.count == 0 || firstObject == nil)
        titleValue = _PlexServerName;
    else
        titleValue = [firstObject objectForKey:@"libTitle"];
    self.title = titleValue;

    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}

- (IBAction)menuButtonAction:(id)sender
{
    [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController] toggleSidebar:![(VLCAppDelegate*)[UIApplication sharedApplication].delegate revealController].sidebarShowing duration:kGHRevealSidebarDefaultAnimationDuration];

    if (self.isEditing)
        [self setEditing:NO animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return _searchData.count;
    else
        return _globalObjectList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PlexCellDetail";

    VLCLocalNetworkListCell *cell = (VLCLocalNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
        cell = [VLCLocalNetworkListCell cellWithReuseIdentifier:CellIdentifier];

    NSDictionary *cellObject;

    if (tableView == self.searchDisplayController.searchResultsTableView)
        cellObject = _searchData[indexPath.row];
    else
        cellObject = _globalObjectList[indexPath.row];

    [cell setTitle:cellObject[@"title"]];
    [cell setIcon:[UIImage imageNamed:@"blank"]];

    NSString *thumbPath = cellObject[@"thumb"];
    if (thumbPath) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_async(queue, ^{
            UIImage *img = [self getCachedImage:[self _urlAuth:thumbPath]];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!img)
                    [cell setIcon:[UIImage imageNamed:@"blank"]];
                else
                    [cell setIcon:img];
            });
        });
    }

    if ([cellObject[@"container"] isEqualToString:@"item"]) {
        UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRightGestureAction:)];
        [swipeRight setDirection:(UISwipeGestureRecognizerDirectionRight)];
        [cell addGestureRecognizer:swipeRight];
        if (SYSTEM_RUNS_IOS7_OR_LATER) {
            UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTouchGestureAction:)];
            [cell addGestureRecognizer:longPressGestureRecognizer];
        }
        NSInteger size = [cellObject[@"size"] integerValue];
        NSString *mediaSize = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
        NSString *durationInSeconds = cellObject[@"duration"];
        [cell setIsDirectory:NO];
        [cell setSubtitle:[NSString stringWithFormat:@"%@ (%@)", mediaSize, durationInSeconds]];
        [cell setIsDownloadable:YES];
        [cell setDelegate:self];
    } else {
        [cell setIsDirectory:YES];
        if (!thumbPath)
            [cell setIcon:[UIImage imageNamed:@"folder"]];
    }
    return cell;
}

- (UIImage *)getCachedImage:(NSString *)url
{
    UIImage *image = [_imageCache objectForKey:url];
    if ((image != nil) && [image isKindOfClass:[UIImage class]]) {
        return image;
    } else {
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
        if (imageData) {
            image = [[UIImage alloc] initWithData:imageData];
            [_imageCache setObject:image forKey:url];
        }
        return image;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(VLCLocalNetworkListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIColor *color = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor VLCDarkBackgroundColor];
    cell.contentView.backgroundColor = cell.titleLabel.backgroundColor = cell.folderTitleLabel.backgroundColor = cell.subtitleLabel.backgroundColor =  color;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *objectList;
    NSString *newPath = nil;

    if (tableView == self.searchDisplayController.searchResultsTableView)
        objectList = [_searchData copy];
    else
        objectList = _globalObjectList;

    NSDictionary *rowObject = objectList[indexPath.row];

    NSString *keyValue = [rowObject objectForKey:@"key"];

    if ([keyValue rangeOfString:@"library"].location == NSNotFound)
        newPath = [_PlexServerPath stringByAppendingPathComponent:keyValue];
    else
        newPath = keyValue;

    if ([rowObject[@"container"] isEqualToString:@"item"]) {
        objectList = [_PlexParser PlexMediaServerParser:_PlexServerAddress port:_PlexServerPort navigationPath:newPath authentification:_PlexAuthentification];
        NSString *URLofSubtitle = nil;

        NSDictionary *firstObject = [objectList firstObject];
        if (!firstObject)
            return;

        if ([firstObject objectForKey:@"keySubtitle"])
            URLofSubtitle = [_PlexWebAPI getFileSubtitleFromPlexServer:firstObject modeStream:YES];

        NSURL *itemURL = [NSURL URLWithString:[self _urlAuth:firstObject[@"keyMedia"]]];
        if (itemURL) {
            VLCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
            [appDelegate openMovieWithExternalSubtitleFromURL:itemURL externalSubURL:URLofSubtitle];
        }
    } else {
        VLCLocalPlexFolderListViewController *targetViewController = [[VLCLocalPlexFolderListViewController alloc] initWithPlexServer:_PlexServerName serverAddress:_PlexServerAddress portNumber:_PlexServerPort atPath:newPath authentification:_PlexAuthentification];
        [[self navigationController] pushViewController:targetViewController animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Specifics

- (NSString *)_urlAuth:(NSString *)url
{
    return [_PlexWebAPI urlAuth:url autentification:_PlexAuthentification];
}

- (void)_playMediaItem:(NSDictionary *)mediaObject
{
    NSString *newPath = nil;
    NSString *keyValue = [mediaObject objectForKey:@"key"];

    if ([keyValue rangeOfString:@"library"].location == NSNotFound)
        newPath = [_PlexServerPath stringByAppendingPathComponent:keyValue];
    else
        newPath = keyValue;

    if ([[mediaObject objectForKey:@"container"] isEqualToString:@"item"]) {
        NSArray *mediaList = [_PlexParser PlexMediaServerParser:_PlexServerAddress port:_PlexServerPort navigationPath:newPath authentification:_PlexAuthentification];
        NSString *URLofSubtitle = nil;
        NSDictionary *firstObject = [mediaList firstObject];
        if (!firstObject)
            return;

        if ([firstObject objectForKey:@"keySubtitle"])
            URLofSubtitle = [_PlexWebAPI getFileSubtitleFromPlexServer:firstObject modeStream:YES];

        NSURL *itemURL = [NSURL URLWithString:[self _urlAuth:[firstObject objectForKey:@"keyMedia"]]];
        if (itemURL) {
            VLCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
            [appDelegate openMovieWithExternalSubtitleFromURL:itemURL externalSubURL:URLofSubtitle];
        }
    }
}

- (void)_downloadFileFromMediaItem:(NSDictionary *)mediaObject
{
    if (!mediaObject)
        return;

    NSURL *itemURL = [NSURL URLWithString:[mediaObject objectForKey:@"keyMedia"]];

    if (![[itemURL absoluteString] isSupportedFormat]) {
        VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil)
                                                         message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", nil), [itemURL absoluteString]]
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                otherButtonTitles:nil];
        [alert show];
    } else if (itemURL) {
        NSString *fileName = [mediaObject objectForKey:@"namefile"];
        [[(VLCAppDelegate *)[UIApplication sharedApplication].delegate downloadViewController] addURLToDownloadList:itemURL fileNameOfMedia:fileName];
    }
}

- (void)swipeRightGestureAction:(UIGestureRecognizer *)recognizer
{
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:[recognizer locationInView:self.tableView]];
    UITableViewCell *swipedCell = [self.tableView cellForRowAtIndexPath:swipedIndexPath];

    VLCLocalNetworkListCell *cell = (VLCLocalNetworkListCell *)[[self tableView] cellForRowAtIndexPath:swipedIndexPath];

    NSDictionary *cellObject = _globalObjectList[[self.tableView indexPathForCell:swipedCell].row];

    NSString *ratingKey = cellObject[@"ratingKey"];
    NSString *tag = cellObject[@"state"];
    NSString *cellStatusLbl = nil;

    NSInteger status = [_PlexWebAPI MarkWatchedUnwatchedMedia:_PlexServerAddress port:_PlexServerPort videoRatingKey:ratingKey state:tag authentification:_PlexAuthentification];

    if (status == 200) {
        if ([tag isEqualToString:@"watched"]) {
            tag = @"unwatched";
            cellStatusLbl = NSLocalizedString(@"PLEX_UNWATCHED", nil);
        } else if ([tag isEqualToString:@"unwatched"]) {
            tag = @"watched";
            cellStatusLbl = NSLocalizedString(@"PLEX_WATCHED", nil);
        }
    } else
        cellStatusLbl = NSLocalizedString(@"PLEX_ERROR_MARK", nil);

    [cell.statusLabel showStatusMessage:cellStatusLbl];

    [_globalObjectList[[self.tableView indexPathForCell:swipedCell].row] setObject:tag forKey:@"state"];
}

- (void)reloadTableViewPlex
{
    _globalObjectList = [_PlexParser PlexMediaServerParser:_PlexServerAddress port:_PlexServerPort navigationPath:_PlexServerPath authentification:_PlexAuthentification];
    [self.tableView reloadData];
}

#pragma mark - VLCLocalNetworkListCell delegation

- (void)triggerDownloadForCell:(VLCLocalNetworkListCell *)cell
{
    NSDictionary *cellObject;

    if ([self.searchDisplayController isActive])
        cellObject = _searchData[[self.searchDisplayController.searchResultsTableView indexPathForCell:cell].row];
    else
        cellObject = _globalObjectList[[self.tableView indexPathForCell:cell].row];

    NSString *path = cellObject[@"key"];

    NSArray *mediaList = [_PlexParser PlexMediaServerParser:_PlexServerAddress port:_PlexServerPort navigationPath:path authentification:_PlexAuthentification];
    NSDictionary *firstObject = [mediaList firstObject];

    NSInteger size = [[firstObject objectForKey:@"size"] integerValue];
    if (size  < [[UIDevice currentDevice] freeDiskspace].longLongValue) {
        if ([firstObject objectForKey:@"keySubtitle"])
            [_PlexWebAPI getFileSubtitleFromPlexServer:firstObject modeStream:NO];

        [self _downloadFileFromMediaItem:firstObject];
        [cell.statusLabel showStatusMessage:NSLocalizedString(@"DOWNLOADING", nil)];
    } else {
        VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                          message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), [firstObject objectForKey:@"title"], [[UIDevice currentDevice] model]]
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - Search Display Controller Delegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [_searchData removeAllObjects];

    NSUInteger count = _globalObjectList.count;
    for (NSUInteger i = 0; i < count; i++) {
        NSRange nameRange;
        nameRange = [[_globalObjectList[i] objectForKey:@"title"] rangeOfString:searchString options:NSCaseInsensitiveSearch];
        if (nameRange.location != NSNotFound)
            [_searchData addObject:_globalObjectList[i]];
    }
    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        tableView.rowHeight = 80.0f;
    else
        tableView.rowHeight = 68.0f;

    tableView.backgroundColor = [UIColor blackColor];
}

#pragma mark - Refresh

-(void)handleRefresh
{
    //set the title while refreshing
    _refreshControl.attributedTitle = [[NSAttributedString alloc]initWithString:NSLocalizedString(@"LOCAL_SERVER_REFRESH", nil)];
    //set the date and time of refreshing
    NSDateFormatter *formattedDate = [[NSDateFormatter alloc]init];
    [formattedDate setDateFormat:@"MMM d, h:mm a"];
    NSString *lastupdated = [NSString stringWithFormat:NSLocalizedString(@"LOCAL_SERVER_LAST_UPDATE", nil),[formattedDate stringFromDate:[NSDate date]]];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastupdated attributes:attrsDictionary];
    //end the refreshing
    [_refreshControl endRefreshing];
    [self performSelector:@selector(reloadTableViewPlex) withObject:nil];
}

#pragma mark - Gesture Action

- (void)tapTwiceGestureAction:(UIGestureRecognizer *)recognizer
{
    _searchBar.hidden = !_searchBar.hidden;
    if (_searchBar.hidden)
        self.tableView.tableHeaderView = nil;
    else
        self.tableView.tableHeaderView = _searchBar;

    [self.tableView setContentOffset:CGPointMake(0.0f, -self.tableView.contentInset.top) animated:NO];
}

- (void)longTouchGestureAction:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:[recognizer locationInView:self.tableView]];
        UITableViewCell *swipedCell = [self.tableView cellForRowAtIndexPath:swipedIndexPath];
        VLCLocalNetworkListCell *cell = (VLCLocalNetworkListCell *)[[self tableView] cellForRowAtIndexPath:swipedIndexPath];

        NSDictionary *cellObject = _globalObjectList[[self.tableView indexPathForCell:swipedCell].row];

        if (SYSTEM_RUNS_IOS7_OR_LATER) {
            VLCPlexMediaInformationViewController *targetViewController = [[VLCPlexMediaInformationViewController alloc] initPlexMediaInformation:cellObject serverAddress:_PlexServerAddress portNumber:_PlexServerPort atPath:_PlexServerPath authentification:_PlexAuthentification];
            [[self navigationController] pushViewController:targetViewController animated:YES];
        } else {
            NSString *title = cellObject[@"title"];
            NSInteger size = [cellObject[@"size"] integerValue];
            NSString *mediaSize = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
            NSString *durationInSeconds = cellObject[@"duration"];
            NSString *audioCodec = cellObject[@"audioCodec"];
            if (!audioCodec)
                audioCodec = @"no track";

            NSString *videoCodec = cellObject[@"videoCodec"];
            if (!videoCodec)
                videoCodec = @"no track";

            NSString *message = [NSString stringWithFormat:@"%@ (%@)\naudio(%@) video(%@)", mediaSize, durationInSeconds, audioCodec, videoCodec];
            NSString *summary = [NSString stringWithFormat:@"%@", cellObject[@"summary"]];

            VLCAlertView *alertView = [[VLCAlertView alloc] initWithTitle:title message:message cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:@[NSLocalizedString(@"PLAY_BUTTON", nil), NSLocalizedString(@"BUTTON_DOWNLOAD", nil)]];
            if (![summary isEqualToString:@""]) {
                UITextView *textView = [[UITextView alloc] initWithFrame:alertView.bounds];
                textView.text = summary;
                textView.editable = NO;
                [alertView setValue:textView forKey:@"accessoryView"];
            }
            alertView.completion = ^(BOOL cancelled, NSInteger buttonIndex) {
                if (!cancelled) {
                    if (buttonIndex == 2)
                        [self triggerDownloadForCell:cell];
                    else
                        [self _playMediaItem:cellObject];
                }
            };
            [alertView show];
        }
    }
}

@end