/*****************************************************************************
 * VLCFTPServerListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCFTPServerListViewController.h"
#import "VLCNetworkListCell.h"
#import "VLCActivityManager.h"
#import "NSString+SupportedMedia.h"
#import "UIDevice+VLC.h"
#import "VLCStatusLabel.h"
#import "VLCPlaybackController.h"
#import "VLCDownloadViewController.h"

#import "WhiteRaccoon.h"

@interface VLCFTPServerListViewController () <WRRequestDelegate, VLCNetworkListCellDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
{
    NSString *_ftpServerAddress;
    NSString *_ftpServerUserName;
    NSString *_ftpServerPassword;
    NSString *_ftpServerPath;
    WRRequestListDirectory *_FTPListDirRequest;

    NSArray *_objectList;
    NSMutableArray *_searchData;
}

@end

@implementation VLCFTPServerListViewController

- (id)initWithFTPServer:(NSString *)serverAddress userName:(NSString *)username andPassword:(NSString *)password atPath:(NSString *)path
{
    self = [super init];

    if (self) {
        _ftpServerAddress = serverAddress;
        _ftpServerUserName = username;
        _ftpServerPassword = password;
        _ftpServerPath = path;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([_ftpServerPath isEqualToString:@"/"])
        self.title = _ftpServerAddress;
    else
        self.title = [_ftpServerPath lastPathComponent];
    [self _listFTPDirectory];
}

#pragma mark - ftp specifics


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

    [[VLCActivityManager defaultManager] networkActivityStarted];
    [_FTPListDirRequest start];
}

- (NSString *)_credentials
{
    NSString *cred;

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

    [[VLCDownloadViewController sharedInstance] addURLToDownloadList:URLToQueue fileNameOfMedia:nil];
}

- (void)_streamFTPFile:(NSString *)fileName
{
    NSString *URLofSubtitle = nil;
    NSArray *SubtitlesList = [self _searchSubtitle:fileName];

    if(SubtitlesList.count > 0)
        URLofSubtitle = [self _getFileSubtitleFromFtpServer:SubtitlesList[0]];

    NSURL *URLToPlay = [NSURL URLWithString:[[@"ftp" stringByAppendingFormat:@"://%@%@/%@/%@", [self _credentials], _ftpServerAddress, _ftpServerPath, fileName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    [vpc playURL:URLToPlay subtitlesFilePath:URLofSubtitle];
}

- (NSArray *)_searchSubtitle:(NSString *)url
{
    NSString *urlTemp = [[url lastPathComponent] stringByDeletingPathExtension];
    NSMutableArray *ObjList = [[NSMutableArray alloc] init];
    NSUInteger count = _objectList.count;

    for (NSUInteger i = 0; i < count; i++)
        [ObjList addObject:[_objectList[i] objectForKey:(id)kCFFTPResourceName]];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", urlTemp];
    NSArray *results = [ObjList filteredArrayUsingPredicate:predicate];

    [ObjList removeAllObjects];

    count = results.count;

    for (NSUInteger i = 0; i < count; i++) {
        if ([results[i] isSupportedSubtitleFormat])
            [ObjList addObject:results[i]];
    }
    return [NSArray arrayWithArray:ObjList];
}

- (NSString *)_getFileSubtitleFromFtpServer:(NSString *)fileName
{
    NSURL *url = [NSURL URLWithString:[[@"ftp" stringByAppendingFormat:@"://%@%@/%@/%@", [self _credentials], _ftpServerAddress, _ftpServerPath, fileName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *FileSubtitlePath = nil;
    NSData *receivedSub = [NSData dataWithContentsOfURL:url];

    if (receivedSub.length < [[UIDevice currentDevice] freeDiskspace].longLongValue) {
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *directoryPath = searchPaths[0];
        FileSubtitlePath = [directoryPath stringByAppendingPathComponent:[fileName lastPathComponent]];

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
                                                          message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), [fileName lastPathComponent], [[UIDevice currentDevice] model]]
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                otherButtonTitles:nil];
        [alert show];
    }

    return FileSubtitlePath;
}

#pragma mark - table view data source, for more see super

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return _searchData.count;

    return _objectList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCNetworkListCell *cell = (VLCNetworkListCell *)[tableView dequeueReusableCellWithIdentifier:VLCNetworkListCellIdentifier];
    if (cell == nil)
        cell = [VLCNetworkListCell cellWithReuseIdentifier:VLCNetworkListCellIdentifier];

    NSDictionary *cellObject;
    if (tableView == self.searchDisplayController.searchResultsTableView)
        cellObject = _searchData[indexPath.row];
    else
        cellObject = _objectList[indexPath.row];

    NSString *rawFileName = [cellObject objectForKey:(id)kCFFTPResourceName];
    NSData *flippedData = [rawFileName dataUsingEncoding:[[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingFTPTextEncoding] intValue] allowLossyConversion:YES];
    cell.title = [[NSString alloc] initWithData:flippedData encoding:NSUTF8StringEncoding];

    if ([cellObject[(id)kCFFTPResourceType] intValue] == 4) {
        cell.isDirectory = YES;
        cell.icon = [UIImage imageNamed:@"folder"];
    } else {
        cell.isDirectory = NO;
        cell.icon = [UIImage imageNamed:@"blank"];
        cell.subtitle = [NSString stringWithFormat:@"%0.2f MB", (float)([cellObject[(id)kCFFTPResourceSize] intValue] / 1e6)];
        cell.isDownloadable = YES;
        cell.delegate = self;
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
    NSDictionary *cellObject;

    if (tableView == self.searchDisplayController.searchResultsTableView)
        cellObject = _searchData[indexPath.row];
    else
        cellObject = _objectList[indexPath.row];

    if ([cellObject[(id)kCFFTPResourceType] intValue] == 4) {
        NSString *newPath = [NSString stringWithFormat:@"%@/%@", _ftpServerPath, cellObject[(id)kCFFTPResourceName]];

        VLCFTPServerListViewController *targetViewController = [[VLCFTPServerListViewController alloc] initWithFTPServer:_ftpServerAddress userName:_ftpServerUserName andPassword:_ftpServerPassword atPath:newPath];
        [self.navigationController pushViewController:targetViewController animated:YES];
    } else {
        NSString *rawObjectName = cellObject[(id)kCFFTPResourceName];
        NSData *flippedData = [rawObjectName dataUsingEncoding:[[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingFTPTextEncoding] intValue] allowLossyConversion:YES];
        NSString *properObjectName = [[NSString alloc] initWithData:flippedData encoding:NSUTF8StringEncoding];
        if (![properObjectName isSupportedFormat]) {
            VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil)
                                                              message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", nil), properObjectName]
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                    otherButtonTitles:nil];
            [alert show];
        } else
            [self _streamFTPFile:properObjectName];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - VLCNetworkListCell delegation
- (void)triggerDownloadForCell:(VLCNetworkListCell *)cell
{
    NSString *rawObjectName;
    NSInteger size;

    NSDictionary *cellObject;

    if ([self.searchDisplayController isActive])
        cellObject = _searchData[[self.searchDisplayController.searchResultsTableView indexPathForCell:cell].row];
    else
        cellObject = _objectList[[self.tableView indexPathForCell:cell].row];

    rawObjectName = cellObject[(id)kCFFTPResourceName];
    size = [cellObject[(id)kCFFTPResourceSize] intValue];

    NSData *flippedData = [rawObjectName dataUsingEncoding:[[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingFTPTextEncoding] intValue] allowLossyConversion:YES];
    NSString *properObjectName = [[NSString alloc] initWithData:flippedData encoding:NSUTF8StringEncoding];
    if (![properObjectName isSupportedFormat]) {
        VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", nil)
                                                          message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", nil), properObjectName]
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                otherButtonTitles:nil];
        [alert show];
    } else {
        if (size  < [[UIDevice currentDevice] freeDiskspace].longLongValue) {
            [self _downloadFTPFile:properObjectName];
            [cell.statusLabel showStatusMessage:NSLocalizedString(@"DOWNLOADING", nil)];
        } else {
            VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                              message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), properObjectName, [[UIDevice currentDevice] model]]
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                    otherButtonTitles:nil];
            [alert show];
        }
    }
}

#pragma mark - white raccoon delegation

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
    VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_TITLE", nil)
                                                      message:NSLocalizedString(@"LOCAL_SERVER_CONNECTION_FAILED_MESSAGE", nil)
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                            otherButtonTitles:nil];
    [alert show];

    APLog(@"request %@ failed with error %i", request, request.error.errorCode);
}

#pragma mark - search

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSInteger listCount = 0;
    [_searchData removeAllObjects];

    listCount = _objectList.count;

    for (int i = 0; i < listCount; i++) {
        NSRange nameRange;

        NSString *rawObjectName = [_objectList[i] objectForKey:(id)kCFFTPResourceName];
        NSData *flippedData = [rawObjectName dataUsingEncoding:[[[NSUserDefaults standardUserDefaults] objectForKey:kVLCSettingFTPTextEncoding] intValue] allowLossyConversion:YES];
        NSString *properObjectName = [[NSString alloc] initWithData:flippedData encoding:NSUTF8StringEncoding];
        nameRange = [properObjectName rangeOfString:searchString options:NSCaseInsensitiveSearch];

        if (nameRange.location != NSNotFound)
            [_searchData addObject:_objectList[i]];
    }

    return YES;
}

@end
