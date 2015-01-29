/*****************************************************************************
 * VLCSharedLibraryListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCSharedLibraryListViewController.h"
#import "VLCSharedLibraryParser.h"
#import "VLCLocalNetworkListCell.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"
#import "UINavigationController+Theme.h"
#import "VLCDownloadViewController.h"
#import "NSString+SupportedMedia.h"
#import "VLCStatusLabel.h"
#import "VLCAlertView.h"
#import "UIDevice+VLC.h"

@interface VLCSharedLibraryListViewController () <UITableViewDataSource, UITableViewDelegate, VLCLocalNetworkListCell, UISearchBarDelegate, UISearchDisplayDelegate>
{
    NSMutableArray *_mutableObjectList;
    NSCache *_imageCache;

    NSString *_httpServerName;
    NSString *_httpServerAddress;
    NSString *_httpServerPort;
    VLCSharedLibraryParser *_httpParser;

    NSMutableArray *_searchData;
    UISearchBar *_searchBar;
    UISearchDisplayController *_searchDisplayController;
    UIRefreshControl *_refreshControl;
    UIBarButtonItem *_menuButton;
}
@end

@implementation VLCSharedLibraryListViewController

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

- (id)initWithHttpServer:(NSString *)serverName serverAddress:(NSString *)serverAddress portNumber:(NSString *)portNumber
{
    self = [super init];
    if (self) {
        _httpServerName = serverName;
        _httpServerAddress = serverAddress;
        _httpServerPort = portNumber;

        _mutableObjectList = [[NSMutableArray alloc] init];
        _imageCache = [[NSCache alloc] init];
        [_imageCache setCountLimit:50];

        _httpParser = [[VLCSharedLibraryParser alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [_mutableObjectList removeAllObjects];
    _mutableObjectList = [_httpParser VLCLibraryServerParser:_httpServerAddress port:_httpServerPort];

    self.tableView.separatorColor = [UIColor VLCDarkBackgroundColor];
    self.view.backgroundColor = [UIColor VLCDarkBackgroundColor];

    NSString *titleValue;
    if (_mutableObjectList.count == 0)
        titleValue = _httpServerAddress;
    else
        titleValue = [_mutableObjectList[0] objectForKey:@"libTitle"];

    self.title = titleValue;

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

    _searchData = [[NSMutableArray alloc] init];
    [_searchData removeAllObjects];
}

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
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
        return _mutableObjectList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"libraryVLCCellDetail";

    VLCLocalNetworkListCell *cell = (VLCLocalNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
        cell = [VLCLocalNetworkListCell cellWithReuseIdentifier:CellIdentifier];

    NSMutableArray *ObjList = [[NSMutableArray alloc] init];
    [ObjList removeAllObjects];

    if (tableView == self.searchDisplayController.searchResultsTableView)
        [ObjList addObjectsFromArray:_searchData];
    else
        [ObjList addObjectsFromArray:_mutableObjectList];

    [cell setTitle:[[ObjList objectAtIndex:indexPath.row] objectForKey:@"title"]];
    [cell setIcon:[UIImage imageNamed:@"blank"]];

    NSString *thumbPath = [[ObjList objectAtIndex:indexPath.row] objectForKey:@"thumb"];
    if (thumbPath) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_async(queue, ^{
            UIImage *img = [self getCachedImage:thumbPath];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!img)
                    [cell setIcon:[UIImage imageNamed:@"blank"]];
                else
                    [cell setIcon:img];
            });
        });
    }

    NSInteger size = [[[ObjList objectAtIndex:indexPath.row] objectForKey:@"size"] integerValue];
    NSString *mediaSize = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
    NSString *duration = [[ObjList objectAtIndex:indexPath.row] objectForKey:@"duration"];
    [cell setIsDirectory:NO];
    [cell setSubtitle:[NSString stringWithFormat:@"%@ (%@)", mediaSize, duration]];
    [cell setIsDownloadable:YES];
    [cell setDelegate:self];
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
    NSMutableArray *ObjList = [[NSMutableArray alloc] init];
    [ObjList removeAllObjects];

    if (tableView == self.searchDisplayController.searchResultsTableView)
        [ObjList addObjectsFromArray:_searchData];
    else
        [ObjList addObjectsFromArray:_mutableObjectList];

    NSString *URLofSubtitle = nil;
    if (![[[ObjList objectAtIndex:indexPath.row] objectForKey:@"pathSubtitle"] isEqualToString:@""]) {
        NSURL *url = [NSURL URLWithString:[[[ObjList objectAtIndex:indexPath.row] objectForKey:@"pathSubtitle"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        URLofSubtitle = [self _getFileSubtitleFromServer:url modeStream:YES];
    }

    NSURL *itemURL = [NSURL URLWithString:[[ObjList objectAtIndex:indexPath.row] objectForKey:@"pathfile"]];
    if (itemURL) {
            VLCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
            [appDelegate openMovieWithExternalSubtitleFromURL:itemURL externalSubURL:URLofSubtitle];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Specifics

- (void)_downloadFileFromMediaItem:(NSURL *)itemURL
{
    if (![[itemURL absoluteString] isSupportedFormat]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil) message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", nil), [itemURL absoluteString]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil) otherButtonTitles:nil];
        [alert show];
    } else if (itemURL) {
        [[(VLCAppDelegate *)[UIApplication sharedApplication].delegate downloadViewController] addURLToDownloadList:itemURL fileNameOfMedia:nil];
    }
}

- (void)reloadSharedLibrary
{
    [_mutableObjectList removeAllObjects];
    _mutableObjectList = [_httpParser VLCLibraryServerParser:_httpServerAddress port:_httpServerPort];
    [self.tableView reloadData];
}

- (NSString *)_getFileSubtitleFromServer:(NSURL *)url modeStream:(BOOL)modeStream
{
    NSData *receivedSub = [NSData dataWithContentsOfURL:url];
    NSArray *searchPaths =  nil;
    if (modeStream)
        searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    else
        searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    NSString *directoryPath = [searchPaths objectAtIndex:0];
    NSString *FileSubtitlePath = [directoryPath stringByAppendingPathComponent:[[url path] lastPathComponent]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:FileSubtitlePath]) {
        [fileManager createFileAtPath:FileSubtitlePath contents:nil attributes:nil];
        if (![fileManager fileExistsAtPath:FileSubtitlePath])
            APLog(@"file creation failed, no data was saved");
    }
    [receivedSub writeToFile:FileSubtitlePath atomically:YES];
    return FileSubtitlePath;
}

#pragma mark - VLCLocalNetworkListCell delegation

- (void)triggerDownloadForCell:(VLCLocalNetworkListCell *)cell
{
    NSMutableArray *ObjList = [[NSMutableArray alloc] init];
    [ObjList removeAllObjects];

    if ([self.searchDisplayController isActive])
        [ObjList addObject:_searchData[[self.searchDisplayController.searchResultsTableView indexPathForCell:cell].row]];
    else
        [ObjList addObject:_mutableObjectList[[self.tableView indexPathForCell:cell].row]];

    NSURL *itemURL = [NSURL URLWithString:[ObjList[0] objectForKey:@"pathfile"]];

    NSInteger size = [[[ObjList objectAtIndex:0] objectForKey:@"size"] integerValue];
    if (size  < [[UIDevice currentDevice] freeDiskspace].longLongValue) {
        NSString *URLofSubtitle = nil;
        if (![[[ObjList objectAtIndex:0] objectForKey:@"pathSubtitle"] isEqualToString:@""]) {
            NSURL *url = [NSURL URLWithString:[[[ObjList objectAtIndex:0] objectForKey:@"pathSubtitle"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            URLofSubtitle = [self _getFileSubtitleFromServer:url modeStream:NO];
        }

        [self _downloadFileFromMediaItem:itemURL];
        [cell.statusLabel showStatusMessage:NSLocalizedString(@"DOWNLOADING", nil)];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil) message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), [[ObjList objectAtIndex:0] objectForKey:@"title"], [[UIDevice currentDevice] model]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil) otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - Search Display Controller Delegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [_searchData removeAllObjects];

    for (int i = 0; i < [_mutableObjectList count]; i++) {
        NSRange nameRange;
        nameRange = [[[_mutableObjectList objectAtIndex:i] objectForKey:@"title"] rangeOfString:searchString options:NSCaseInsensitiveSearch];
        if (nameRange.location != NSNotFound)
            [_searchData addObject:_mutableObjectList[i]];
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
    [self performSelector:@selector(reloadSharedLibrary) withObject:nil];
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

@end
