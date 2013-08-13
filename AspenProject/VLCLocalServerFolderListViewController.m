//
//  VLCLocalServerFolderListViewController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 10.08.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCLocalServerFolderListViewController.h"
#import "MediaServerBasicObjectParser.h"
#import "MediaServer1ItemObject.h"
#import "MediaServer1ContainerObject.h"
#import "MediaServer1Device.h"
#import "VLCLocalNetworkListCell.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"
#import "UINavigationController+Theme.h"
#import "WhiteRaccoon.h"
#import "NSString+SupportedMedia.h"

#define kVLCUPNPFileServer 0
#define kVLCFTPServer 1

@interface VLCLocalServerFolderListViewController () <UITableViewDataSource, UITableViewDelegate, WRRequestDelegate>
{
    /* UI */
    UIBarButtonItem *_backButton;

    /* generic data storage */
    NSString *_listTitle;
    NSMutableArray *_objectList;
    NSUInteger _serverType;

    /* UPNP specifics */
    MediaServer1Device *_UPNPdevice;
    NSString *_UPNProotID;

    /* FTP specifics */
    NSString *_ftpServerAddress;
    NSString *_ftpServerUserName;
    NSString *_ftpServerPassword;
    NSString *_ftpServerPath;
    WRRequestListDirectory *_FTPListDirRequest;
    WRRequestDownload *_FTPDownloadRequest;
}

@end

@implementation VLCLocalServerFolderListViewController

- (void)loadView
{
    _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    self.view = _tableView;
}

- (id)initWithUPNPDevice:(MediaServer1Device*)device header:(NSString*)header andRootID:(NSString*)rootID
{
    self = [super init];

    if (self) {
        _UPNPdevice = device;
        _listTitle = header;
        _UPNProotID = rootID;
        _serverType = kVLCUPNPFileServer;
    }

    return self;
}

- (id)initWithFTPServer:(NSString *)serverAddress userName:(NSString *)username andPassword:(NSString *)password atPath:(NSString *)path
{
    self = [super init];

    if (self) {
        _ftpServerAddress = serverAddress;
        _ftpServerUserName = username;
        _ftpServerPassword = password;
        _ftpServerPath = path;
        _serverType = kVLCFTPServer;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _objectList = [[NSMutableArray alloc] init];

    if (_serverType == kVLCUPNPFileServer) {
        NSMutableString *outResult = [[NSMutableString alloc] init];
        NSMutableString *outNumberReturned = [[NSMutableString alloc] init];
        NSMutableString *outTotalMatches = [[NSMutableString alloc] init];
        NSMutableString *outUpdateID = [[NSMutableString alloc] init];

        [[_UPNPdevice contentDirectory] BrowseWithObjectID:_UPNProotID BrowseFlag:@"BrowseDirectChildren" Filter:@"*" StartingIndex:@"0" RequestedCount:@"0" SortCriteria:@"+dc:title" OutResult:outResult OutNumberReturned:outNumberReturned OutTotalMatches:outTotalMatches OutUpdateID:outUpdateID];

        NSData *didl = [outResult dataUsingEncoding:NSUTF8StringEncoding];
        MediaServerBasicObjectParser *parser = [[MediaServerBasicObjectParser alloc] initWithMediaObjectArray:_objectList itemsOnly:NO];
        [parser parseFromData:didl];
    } else if (_serverType == kVLCFTPServer) {
        if ([_ftpServerPath isEqualToString:@"/"])
            _listTitle = _ftpServerAddress;
        else
            _listTitle = [_ftpServerPath lastPathComponent];
        [self _listFTPDirectory];
    }

    self.tableView.separatorColor = [UIColor colorWithWhite:.122 alpha:1.];
    self.view.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];

    self.title = _listTitle;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
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
    return _objectList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LocalNetworkCellDetail";

    VLCLocalNetworkListCell *cell = (VLCLocalNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCLocalNetworkListCell cellWithReuseIdentifier:CellIdentifier];

    if (_serverType == kVLCUPNPFileServer) {
        MediaServer1BasicObject *item = _objectList[indexPath.row];
        if (![item isContainer]) {
            MediaServer1ItemObject *mediaItem = _objectList[indexPath.row];
            [cell setSubtitle: [NSString stringWithFormat:@"%0.2f MB", (float)([mediaItem.size intValue] / 1e6)]];
            [cell setIsDirectory:NO];
            [cell setIcon:[UIImage imageNamed:@"blank"]];
        } else {
            [cell setIsDirectory:YES];
            [cell setIcon:[UIImage imageNamed:@"folder"]];
        }
        [cell setTitle:[item title]];
    } else if (_serverType == kVLCFTPServer) {
        cell.title = [_objectList[indexPath.row] objectForKey:(id)kCFFTPResourceName];
        if ([[_objectList[indexPath.row] objectForKey:(id)kCFFTPResourceType] intValue] == 4) {
            cell.isDirectory = YES;
            cell.icon = [UIImage imageNamed:@"folder"];
        } else {
            cell.isDirectory = NO;
            cell.icon = [UIImage imageNamed:@"blank"];
            cell.subtitle = [NSString stringWithFormat:@"%0.2f MB", (float)([[_objectList[indexPath.row] objectForKey:(id)kCFFTPResourceSize] intValue] / 1e6)];
        }
    }

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor colorWithWhite:.122 alpha:1.];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_serverType == kVLCUPNPFileServer) {
        MediaServer1BasicObject *item = _objectList[indexPath.row];
        if ([item isContainer]) {
            MediaServer1ContainerObject *container = _objectList[indexPath.row];
            VLCLocalServerFolderListViewController *targetViewController = [[VLCLocalServerFolderListViewController alloc] initWithUPNPDevice:_UPNPdevice header:[container title] andRootID:[container objectID]];
            [[self navigationController] pushViewController:targetViewController animated:YES];
        } else {
            MediaServer1ItemObject *item = _objectList[indexPath.row];

            MediaServer1ItemRes *resource = nil;
            NSEnumerator *e = [[item resources] objectEnumerator];
            NSURL *itemURL;
            while((resource = (MediaServer1ItemRes*)[e nextObject])){
                APLog(@"%@ - %d, %@, %d, %d, %d, %@ (%@)", [item title], [resource bitrate], [resource duration], [resource nrAudioChannels], [resource size],  [resource durationInSeconds],  [resource protocolInfo], [item uri]);
                itemURL = [NSURL URLWithString:[item uri]];
            }

            if (itemURL && ([itemURL.scheme isEqualToString:@"http"] || [itemURL.scheme isEqualToString:@"rtsp"] || [itemURL.scheme isEqualToString:@"rtp"] || [itemURL.scheme isEqualToString:@"mms"] || [itemURL.scheme isEqualToString:@"mmsh"])) {
                VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;

                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:appDelegate.playlistViewController];
                [navController loadTheme];

                appDelegate.revealController.contentViewController = navController;
                [appDelegate.revealController toggleSidebar:NO duration:kGHRevealSidebarDefaultAnimationDuration];

                [appDelegate.playlistViewController performSelector:@selector(openMovieFromURL:) withObject:itemURL afterDelay:kGHRevealSidebarDefaultAnimationDuration];
            }
        }
    } else if (_serverType == kVLCFTPServer) {
        if ([[_objectList[indexPath.row] objectForKey:(id)kCFFTPResourceType] intValue] == 4) {
            NSString *newPath = [NSString stringWithFormat:@"%@/%@", _ftpServerPath, [_objectList[indexPath.row] objectForKey:(id)kCFFTPResourceName]];

            VLCLocalServerFolderListViewController *targetViewController = [[VLCLocalServerFolderListViewController alloc] initWithFTPServer:_ftpServerAddress userName:_ftpServerUserName andPassword:_ftpServerPassword atPath:newPath];
            [self.navigationController pushViewController:targetViewController animated:YES];
        } else {
            NSString *objectName = [_objectList[indexPath.row] objectForKey:(id)kCFFTPResourceName];
            NSLog(@"user would like to fetch %@", objectName);
            if (![objectName isSupportedFormat]) {
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", @"") message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED", @""), objectName] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"") otherButtonTitles:nil];
                [alert show];
            } else
                [self _downloadFTPFile:objectName];
        }
    }
}

#pragma mark - FTP specifics
- (void)_listFTPDirectory
{
    if (_FTPListDirRequest)
        return;

    _FTPListDirRequest = [[WRRequestListDirectory alloc] init];
    _FTPListDirRequest.delegate = self;
    _FTPListDirRequest.hostname = _ftpServerAddress;
    _FTPListDirRequest.username = _ftpServerUserName;
    _FTPListDirRequest.password = _ftpServerPassword;
    _FTPListDirRequest.path = _ftpServerPath;
    _FTPListDirRequest.passive = YES;

    [_FTPListDirRequest start];
}

- (void)_downloadFTPFile:(NSString *)fileName
{
    if (_FTPDownloadRequest)
        return;

    _FTPDownloadRequest = [[WRRequestDownload alloc] init];
    _FTPDownloadRequest.delegate = self;
    _FTPDownloadRequest.hostname = _ftpServerAddress;
    _FTPDownloadRequest.username = _ftpServerUserName;
    _FTPDownloadRequest.password = _ftpServerPassword;
    _FTPDownloadRequest.path = [NSString stringWithFormat:@"%@/%@", _ftpServerPath, fileName];
    _FTPDownloadRequest.passive = YES;

    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = searchPaths[0];
    NSURL *destinationURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", directoryPath, fileName]];
    _FTPDownloadRequest.downloadLocation = destinationURL;

    [_FTPDownloadRequest start];
}

- (void)requestCompleted:(WRRequest *)request
{
    if (request == _FTPListDirRequest) {
        NSMutableArray *filteredList = [[NSMutableArray alloc] init];
        NSArray *rawList = [(WRRequestListDirectory*)request filesInfo];
        NSUInteger count = rawList.count;

        for (NSUInteger x = 0; x < count; x++) {
            if (![[rawList[x] objectForKey:(id)kCFFTPResourceName] hasPrefix:@"."])
                [filteredList addObject:rawList[x]];
        }

        _objectList = [NSArray arrayWithArray:filteredList];
        [self.tableView reloadData];
    } else if (request == _FTPDownloadRequest) {
        APLog(@"download complete!");
    } else
        APLog(@"unknown request %@ completed", request);
}

- (void)progressUpdatedTo:(NSUInteger)rawProgressData
{
    NSLog(@"progress update: %i", rawProgressData);
}

- (void)requestFailed:(WRRequest *)request
{
    APLog(@"request %@ failed with error %i message '%@'", request, request.error.errorCode, request.error.message);
}

@end
