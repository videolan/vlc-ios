/*****************************************************************************
 * VLCNetworkServerBrowserViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *          Tobias Conradi <videolan # tobias-conradi.de>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCNetworkServerBrowserViewController.h"
#import "VLCNetworkListCell.h"
#import "VLCActivityManager.h"
#import "NSString+SupportedMedia.h"
#import "UIDevice+VLC.h"
#import "VLCStatusLabel.h"
#import "VLCPlaybackController.h"
#import "VLCDownloadViewController.h"

#import "WhiteRaccoon.h"
#import "VLCNetworkServerBrowser-Protocol.h"

@interface VLCNetworkServerBrowserViewController () <VLCNetworkServerBrowserDelegate,VLCNetworkListCellDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
    UIRefreshControl *_refreshControl;
}
@property (nonatomic) id<VLCNetworkServerBrowser> serverBrowser;
@property (nonatomic) NSByteCountFormatter *byteCounterFormatter;
@property (nonatomic) NSArray<id<VLCNetworkServerBrowserItem>> *searchArray;
@property (nonatomic, readonly) NSCache *imageCache;
@end

@implementation VLCNetworkServerBrowserViewController

- (instancetype)initWithServerBrowser:(id<VLCNetworkServerBrowser>)browser
{
    self = [super init];
    if (self) {
        _serverBrowser = browser;
        browser.delegate = self;

        _imageCache = [[NSCache alloc] init];
        [_imageCache setCountLimit:50];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _refreshControl = [[UIRefreshControl alloc] init];
    _refreshControl.backgroundColor = [UIColor VLCDarkBackgroundColor];
    _refreshControl.tintColor = [UIColor whiteColor];
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:_refreshControl];

    self.title = self.serverBrowser.title;
    [self update];
}

- (void)networkServerBrowserDidUpdate:(id<VLCNetworkServerBrowser>)networkBrowser {
    [self.tableView reloadData];
    [[VLCActivityManager defaultManager] networkActivityStopped];
    [_refreshControl endRefreshing];
}

- (void)networkServerBrowser:(id<VLCNetworkServerBrowser>)networkBrowser requestDidFailWithError:(NSError *)error {

    VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_TITLE", nil)
                                                      message:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_MESSAGE", nil)
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                            otherButtonTitles:nil];
    [alert show];
    
}

- (void)update
{
    [self.serverBrowser update];
    [[VLCActivityManager defaultManager] networkActivityStarted];
}

-(void)handleRefresh
{
    //set the title while refreshing
    _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"LOCAL_SERVER_REFRESH",nil)];
    //set the date and time of refreshing
    NSDateFormatter *formattedDate = [[NSDateFormatter alloc]init];
    [formattedDate setDateFormat:@"MMM d, h:mm a"];
    NSString *lastupdated = [NSString stringWithFormat:NSLocalizedString(@"LOCAL_SERVER_LAST_UPDATE",nil),[formattedDate stringFromDate:[NSDate date]]];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    _refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastupdated attributes:attrsDictionary];
    //end the refreshing

    [self update];
}

#pragma mark -
- (NSByteCountFormatter *)byteCounterFormatter {
    if (!_byteCounterFormatter) {
        _byteCounterFormatter = [[NSByteCountFormatter alloc] init];
    }
    return _byteCounterFormatter;
}

- (BOOL)isSupportedItem:(id<VLCNetworkServerBrowserItem>)item {
    NSString *properObjectName = item.name;
    NSString *itemURLName = item.URL.lastPathComponent;
    return [properObjectName isSupportedFormat] || [itemURLName isSupportedFormat];
}

- (void)showUnsupportedFileAlertForItem:(id<VLCNetworkServerBrowserItem>)item {
    VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil)
                                                      message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", nil), item.name]
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                            otherButtonTitles:nil];
    [alert show];
}

#pragma mark - server browser item specifics

- (void)_downloadItem:(id<VLCNetworkServerBrowserItem>)item
{
    NSString *filename = item.name;
    if (filename.pathExtension.length == 0) {
        /* there are few crappy UPnP servers who don't reveal the correct file extension, so we use a generic fake (#11123) */
        NSString *urlExtension = item.URL.pathExtension;
        NSString *extension = urlExtension.length!=0 ? urlExtension : @"vlc";
        filename = [filename stringByAppendingPathExtension:extension];
    }
    [[VLCDownloadViewController sharedInstance] addURLToDownloadList:item.URL
                                                     fileNameOfMedia:filename];
}

- (void)_streamMediaList:(VLCMediaList *)mediaList startingAtIndex:(NSInteger)startIndex
{
    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    [vpc playMediaList:mediaList firstIndex:startIndex];
}

- (void)_streamFileForItem:(id<VLCNetworkServerBrowserItem>)item
{
    NSString *URLofSubtitle = nil;
    NSURL *remoteSubtitleURL = nil;
    if ([item respondsToSelector:@selector(subtitleURL)]) {
        remoteSubtitleURL = [item subtitleURL];
    }
    if (!remoteSubtitleURL) {
        NSArray *SubtitlesList = [self _searchSubtitle:item.URL.lastPathComponent];
        remoteSubtitleURL = SubtitlesList.firstObject;
    }

    if(remoteSubtitleURL)
        URLofSubtitle = [self _getFileSubtitleFromServer:remoteSubtitleURL];

    NSURL *URLToPlay = item.URL;

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    [vpc playURL:URLToPlay subtitlesFilePath:URLofSubtitle];
}

- (NSArray<NSURL*> *)_searchSubtitle:(NSString *)url
{
    NSString *urlTemp = [[url lastPathComponent] stringByDeletingPathExtension];

    NSMutableArray<NSURL*> *urls = [NSMutableArray arrayWithArray:[self.serverBrowser.items valueForKey:@"URL"]];

    NSPredicate *namePredicate = [NSPredicate predicateWithFormat:@"SELF.path contains[c] %@", urlTemp];
    [urls filterUsingPredicate:namePredicate];

    NSPredicate *formatPrediate = [NSPredicate predicateWithBlock:^BOOL(NSURL *_Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject.path isSupportedSubtitleFormat];
    }];
    [urls filterUsingPredicate:formatPrediate];

    return [NSArray arrayWithArray:urls];
}

- (NSString *)_getFileSubtitleFromServer:(NSURL *)subtitleURL
{

    NSString *FileSubtitlePath = nil;
    NSData *receivedSub = [NSData dataWithContentsOfURL:subtitleURL]; // TODO: fix synchronous load

    if (receivedSub.length < [[UIDevice currentDevice] freeDiskspace].longLongValue) {
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *directoryPath = searchPaths[0];
        FileSubtitlePath = [directoryPath stringByAppendingPathComponent:[subtitleURL lastPathComponent]];

        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:FileSubtitlePath]) {
            //create local subtitle file
            [fileManager createFileAtPath:FileSubtitlePath contents:nil attributes:nil];
            if (![fileManager fileExistsAtPath:FileSubtitlePath])
                APLog(@"file creation failed, no data was saved");
        }
        [receivedSub writeToFile:FileSubtitlePath atomically:YES];
    } else {
        VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                          message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), [subtitleURL lastPathComponent], [[UIDevice currentDevice] model]]
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                otherButtonTitles:nil];
        [alert show];
    }

    return FileSubtitlePath;
}

- (UIImage *)getCachedImage:(NSURL *)url
{
    UIImage *image = [self.imageCache objectForKey:url];
    if ((image != nil) && [image isKindOfClass:[UIImage class]]) {
        return image;
    } else {
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
        if (imageData) {
            image = [[UIImage alloc] initWithData:imageData];
            [self.imageCache setObject:image forKey:url];
        }
        return image;
    }
}

#pragma mark - table view data source, for more see super

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return _searchArray.count;

    return self.serverBrowser.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCNetworkListCell *cell = (VLCNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:VLCNetworkListCellIdentifier];
    if (cell == nil)
        cell = [VLCNetworkListCell cellWithReuseIdentifier:VLCNetworkListCellIdentifier];


    id<VLCNetworkServerBrowserItem> item;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        item = _searchArray[indexPath.row];
    } else {
        item = self.serverBrowser.items[indexPath.row];
    }

    cell.title = item.name;

    if (item.isContainer) {
        cell.isDirectory = YES;
        cell.icon = [UIImage imageNamed:@"folder"];
    } else {
        cell.isDirectory = NO;
        cell.icon = [UIImage imageNamed:@"blank"];

        NSString *sizeString = item.fileSizeBytes ? [self.byteCounterFormatter stringFromByteCount:item.fileSizeBytes.longLongValue] : nil;

        NSString *duration = nil;
        if ([item respondsToSelector:@selector(duration)]) {
            duration = item.duration;
        }

        NSString *subtitle = nil;
        if (sizeString && duration) {
            subtitle = [NSString stringWithFormat:@"%@ (%@)",sizeString, duration];
        } else if (sizeString) {
            subtitle = sizeString;
        } else if (duration) {
            subtitle = duration;
        }
        cell.subtitle = sizeString;
        cell.isDownloadable = YES;
        cell.delegate = self;

        NSURL *thumbnailURL = nil;
        if ([item respondsToSelector:@selector(thumbnailURL)]) {
            thumbnailURL = item.thumbnailURL;
        }
        
        if (thumbnailURL) {
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
            dispatch_async(queue, ^{
                UIImage *img = [self getCachedImage:thumbnailURL];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (img) {
                        [cell setIcon:img];
                    }
                });
            });
        }

    }

    return cell;
}

#pragma mark - table view delegate, for more see super

- (void)tableView:(UITableView *)tableView willDisplayCell:(VLCNetworkListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];

    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row)
        [[VLCActivityManager defaultManager] networkActivityStopped];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<VLCNetworkServerBrowserItem> item;
    NSInteger row = indexPath.row;
    BOOL searchResult = NO;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        item = _searchArray[row];
        searchResult = YES;
    } else {
        item = self.serverBrowser.items[row];
    }

    if (item.isContainer) {
        VLCNetworkServerBrowserViewController *targetViewController = [[VLCNetworkServerBrowserViewController alloc] initWithServerBrowser:item.containerBrowser];
        [self.navigationController pushViewController:targetViewController animated:YES];
    } else {
        if (![self isSupportedItem:item]) {
            [self showUnsupportedFileAlertForItem:item];
        } else {
            if (searchResult) {
                [self _streamFileForItem:item];
            } else {
                [self _streamMediaList:self.serverBrowser.mediaList startingAtIndex:row];
            }
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - VLCNetworkListCell delegation
- (void)triggerDownloadForCell:(VLCNetworkListCell *)cell
{
    id<VLCNetworkServerBrowserItem> item;
    if ([self.searchDisplayController isActive])
        item = _searchArray[[self.searchDisplayController.searchResultsTableView indexPathForCell:cell].row];
    else
        item = self.serverBrowser.items[[self.tableView indexPathForCell:cell].row];


    if (![self isSupportedItem:item]) {
        [self showUnsupportedFileAlertForItem:item];
    } else {
        if (item.fileSizeBytes.longLongValue  < [[UIDevice currentDevice] freeDiskspace].longLongValue) {
            [self _downloadItem:item];
            [cell.statusLabel showStatusMessage:NSLocalizedString(@"DOWNLOADING", nil)];
        } else {
            VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                              message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), item.name, [[UIDevice currentDevice] model]]
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                    otherButtonTitles:nil];
            [alert show];
        }
    }
}


#pragma mark - search

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains[c] %@",searchString];
    self.searchArray = [self.serverBrowser.items filteredArrayUsingPredicate:predicate];
    return YES;
}

@end
