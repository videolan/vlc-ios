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
#import "VLCDownloadViewController.h"
#import "WhiteRaccoon.h"
#import "NSString+SupportedMedia.h"
#import "VLCStatusLabel.h"

#define kVLCUPNPFileServer 0
#define kVLCFTPServer 1

@interface VLCLocalServerFolderListViewController () <UITableViewDataSource, UITableViewDelegate, WRRequestDelegate, VLCLocalNetworkListCell>
{
    /* UI */
    UIBarButtonItem *_backButton;

    /* generic data storage */
    NSString *_listTitle;
    NSArray *_objectList;
    NSMutableArray *_mutableObjectList;
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
}

@end

@implementation VLCLocalServerFolderListViewController

- (void)loadView
{
    _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = [VLCLocalNetworkListCell heightOfCell];
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
        _mutableObjectList = [[NSMutableArray alloc] init];
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

    if (_serverType == kVLCUPNPFileServer) {
        NSMutableString *outResult = [[NSMutableString alloc] init];
        NSMutableString *outNumberReturned = [[NSMutableString alloc] init];
        NSMutableString *outTotalMatches = [[NSMutableString alloc] init];
        NSMutableString *outUpdateID = [[NSMutableString alloc] init];

        [[_UPNPdevice contentDirectory] BrowseWithObjectID:_UPNProotID BrowseFlag:@"BrowseDirectChildren" Filter:@"*" StartingIndex:@"0" RequestedCount:@"0" SortCriteria:@"+dc:title" OutResult:outResult OutNumberReturned:outNumberReturned OutTotalMatches:outTotalMatches OutUpdateID:outUpdateID];

        [_mutableObjectList removeAllObjects];
        NSData *didl = [outResult dataUsingEncoding:NSUTF8StringEncoding];
        MediaServerBasicObjectParser *parser = [[MediaServerBasicObjectParser alloc] initWithMediaObjectArray:_mutableObjectList itemsOnly:NO];
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
    if (_serverType == kVLCUPNPFileServer)
        return _mutableObjectList.count;

    return _objectList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LocalNetworkCellDetail";

    VLCLocalNetworkListCell *cell = (VLCLocalNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCLocalNetworkListCell cellWithReuseIdentifier:CellIdentifier];

    if (_serverType == kVLCUPNPFileServer) {
        MediaServer1BasicObject *item = _mutableObjectList[indexPath.row];
        if (![item isContainer]) {
            MediaServer1ItemObject *mediaItem = _mutableObjectList[indexPath.row];
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
            cell.isDownloadable = YES;
            cell.delegate = self;
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
        MediaServer1BasicObject *item = _mutableObjectList[indexPath.row];
        if ([item isContainer]) {
            MediaServer1ContainerObject *container = _mutableObjectList[indexPath.row];
            VLCLocalServerFolderListViewController *targetViewController = [[VLCLocalServerFolderListViewController alloc] initWithUPNPDevice:_UPNPdevice header:[container title] andRootID:[container objectID]];
            [[self navigationController] pushViewController:targetViewController animated:YES];
        } else {
            MediaServer1ItemObject *item = _mutableObjectList[indexPath.row];

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
            if (![objectName isSupportedFormat]) {
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", @"") message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", @""), objectName] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"") otherButtonTitles:nil];
                [alert show];
            } else
                [self _openURLStringAndDismiss:[_FTPListDirRequest.fullURLString stringByAppendingString:objectName]];
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

- (NSString *)_credentials
{
    NSString * cred;

    if (_ftpServerUserName.length > 0) {
        if (_ftpServerPassword.length > 0)
            cred = [NSString stringWithFormat:@"%@:%@@", _ftpServerUserName, _ftpServerPassword];
        else
            cred = [NSString stringWithFormat:@"%@@", _ftpServerPassword];
    } else
        cred = @"";

    return [cred stringByStandardizingPath];
}

- (void)_downloadFTPFile:(NSString *)fileName
{
    NSURL *URLToQueue = [NSURL URLWithString:[[@"ftp" stringByAppendingFormat:@"://%@%@/%@/%@", [self _credentials], _ftpServerAddress, _ftpServerPath, fileName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    [[(VLCAppDelegate*)[UIApplication sharedApplication].delegate downloadViewController] addURLToDownloadList:URLToQueue];
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
    } else
        APLog(@"unknown request %@ completed", request);
}

- (void)requestFailed:(WRRequest *)request
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"ERROR_NUMBER", @""), request.error.errorCode] message:request.error.message delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"") otherButtonTitles:nil];
    [alert show];

    APLog(@"request %@ failed with error %i", request, request.error.errorCode);
}

#pragma mark - VLCLocalNetworkListCell delegation
- (void)triggerDownloadForCell:(VLCLocalNetworkListCell *)cell
{
    if (_serverType == kVLCFTPServer) {
        NSString *objectName = [_objectList[[self.tableView indexPathForCell:cell].row] objectForKey:(id)kCFFTPResourceName];
        if (![objectName isSupportedFormat]) {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", @"") message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", @""), objectName] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"") otherButtonTitles:nil];
            [alert show];
        } else {
            [self _downloadFTPFile:objectName];
            [cell.statusLabel showStatusMessage:NSLocalizedString(@"DOWNLOADING", @"")];
        }
    }
}

#pragma mark - communication with playback engine
- (void)_openURLStringAndDismiss:(NSString *)url
{
    VLCAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate.menuViewController selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    [appDelegate.playlistViewController performSelector:@selector(openMovieFromURL:) withObject:[NSURL URLWithString:url] afterDelay:kGHRevealSidebarDefaultAnimationDuration];
}

@end
