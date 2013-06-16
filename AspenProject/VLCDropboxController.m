//
//  VLCDropboxController.m
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 23.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCDropboxController.h"
#import "NSString+SupportedMedia.h"
#import "VLCAppDelegate.h"

@interface VLCDropboxController ()
{
    DBRestClient *_restClient;
    NSArray *_currentFileList;

    NSMutableArray *_listOfDropboxFilesToDownload;
    BOOL _downloadInProgress;

    NSInteger _outstandingNetworkRequests;
}

@end

@implementation VLCDropboxController

#pragma mark - session handling

- (void)startSession
{
}

- (void)logout
{
    [[DBSession sharedSession] unlinkAll];
}

- (BOOL)sessionIsLinked
{
    return  [[DBSession sharedSession] isLinked];
}

- (DBRestClient *)restClient {
    if (!_restClient) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

#pragma mark - file management
- (void)requestDirectoryListingAtPath:(NSString *)path
{
    if (self.sessionIsLinked)
        [[self restClient] loadMetadata:path];
}

- (void)downloadFileToDocumentFolder:(DBMetadata *)file
{
    if (!file.isDirectory) {
        if (!_listOfDropboxFilesToDownload)
            _listOfDropboxFilesToDownload = [[NSMutableArray alloc] init];
        [_listOfDropboxFilesToDownload addObject:file];

        if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)])
            [self.delegate numberOfFilesWaitingToBeDownloadedChanged];

        [self _triggerNextDownload];
    }
}

- (void)_triggerNextDownload
{
    if (_listOfDropboxFilesToDownload.count > 0 && !_downloadInProgress) {
        [self _reallyDownloadFileToDocumentFolder:_listOfDropboxFilesToDownload[0]];
        [_listOfDropboxFilesToDownload removeObjectAtIndex:0];

        if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)])
            [self.delegate numberOfFilesWaitingToBeDownloadedChanged];
    }
}

- (void)_reallyDownloadFileToDocumentFolder:(DBMetadata *)file
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [searchPaths[0] stringByAppendingFormat:@"/%@", file.filename];

    [[self restClient] loadFile:file.path intoPath:filePath];

    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStarted)])
        [self.delegate operationWithProgressInformationStarted];

    _downloadInProgress = YES;
}

#pragma mark - restClient delegate
- (BOOL)_supportedFileExtension:(NSString *)filename
{
    if ([filename isSupportedMediaFormat] || [filename isSupportedSubtitleFormat])
        return YES;

    return NO;
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    NSMutableArray *listOfGoodFilesAndFolders = [[NSMutableArray alloc] init];

    if (metadata.isDirectory) {
        NSArray *contents = metadata.contents;
        NSUInteger metaDataCount = metadata.contents.count;
        for (NSUInteger x = 0; x < metaDataCount; x++) {
            DBMetadata *file = contents[x];
            if ([file isDirectory] || [self _supportedFileExtension:file.filename])
                [listOfGoodFilesAndFolders addObject:file];
        }
    }

    _currentFileList = [NSArray arrayWithArray:listOfGoodFilesAndFolders];

    APLog(@"found filtered metadata for %i files", _currentFileList.count);
    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
        [self.delegate mediaListUpdated];
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
    APLog(@"DBMetadata download failed with error %i", error.code);
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath
{
    /* update library now that we got a file */
    VLCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate updateMediaList];

    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStopped)])
        [self.delegate operationWithProgressInformationStopped];
    _downloadInProgress = NO;

    [self _triggerNextDownload];
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
    APLog(@"DBFile download failed with error %i", error.code);
    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStopped)])
        [self.delegate operationWithProgressInformationStopped];
    _downloadInProgress = NO;

    [self _triggerNextDownload];
}

- (void)restClient:(DBRestClient*)client loadProgress:(CGFloat)progress forFile:(NSString*)destPath
{
    if ([self.delegate respondsToSelector:@selector(currentProgressInformation:)])
        [self.delegate currentProgressInformation:progress];
}

#pragma mark - DBSession delegate

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId
{
    APLog(@"DBSession received authorization failure with user ID %@", userId);
}

#pragma mark - DBNetworkRequest delegate
- (void)networkRequestStarted
{
    _outstandingNetworkRequests++;
    if (_outstandingNetworkRequests == 1)
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)networkRequestStopped
{
    _outstandingNetworkRequests--;
    if (_outstandingNetworkRequests == 0)
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark - VLC internal communication and delegate

- (NSArray *)currentListFiles
{
    return _currentFileList;
}

- (NSInteger)numberOfFilesWaitingToBeDownloaded
{
    if (_listOfDropboxFilesToDownload)
        return _listOfDropboxFilesToDownload.count;

    return 0;
}

@end
