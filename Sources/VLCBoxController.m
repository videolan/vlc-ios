/*****************************************************************************
 * VLCBoxController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCBoxController.h"
#import "NSString+SupportedMedia.h"
#import "VLCAppDelegate.h"
#import <SSKeychain/SSKeychain.h>

@interface VLCBoxController () <NSURLConnectionDataDelegate>
{
    BoxCollection *_fileList;
    BoxAPIJSONOperation *_operation;

    NSArray *_currentFileList;

    NSMutableArray *_listOfBoxFilesToDownload;
    BOOL _downloadInProgress;

    int _maxOffset;
    int _offset;
    NSString *_folderId;

    CGFloat _averageSpeed;
    NSTimeInterval _startDL;
    NSTimeInterval _lastStatsUpdate;
}

@end

@implementation VLCBoxController

#pragma mark - session handling

+ (VLCCloudStorageController *)sharedInstance
{
    static VLCBoxController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (void)startSession
{
    [BoxSDK sharedSDK].OAuth2Session.clientID = kVLCBoxClientID;
    [BoxSDK sharedSDK].OAuth2Session.clientSecret = kVLCBoxClientSecret;
    NSString *token = [SSKeychain passwordForService:kVLCBoxService account:kVLCBoxAccount];
    if (token != nil) {
        [BoxSDK sharedSDK].OAuth2Session.refreshToken = token;
    }
}

- (void)stopSession
{
    [_operation cancel];
    _offset = 0;
    _currentFileList = nil;
}

- (void)logout
{
    [SSKeychain deletePasswordForService:kVLCBoxService account:kVLCBoxAccount];
    [[BoxSDK sharedSDK].OAuth2Session logout];
    [self stopSession];
    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
        [self.delegate mediaListUpdated];
}

- (BOOL)isAuthorized
{
    return [[BoxSDK sharedSDK].OAuth2Session isAuthorized];
}

- (void)showAlert:(NSString *)title message:(NSString *)message
{
    UIAlertView *alert;
    alert = [[UIAlertView alloc] initWithTitle: title
                                       message: message
                                      delegate: nil
                             cancelButtonTitle: NSLocalizedString(@"BUTTON_OK", nil)
                             otherButtonTitles: nil];
    [alert show];
}

#pragma mark - file management
- (void)requestDirectoryListingAtPath:(NSString *)path
{
    //we entered a different folder so discard all current files
    if (![path isEqualToString:_folderId])
        _currentFileList = nil;
    [self listFilesWithID:path];
}

- (BOOL)hasMoreFiles
{
    return _offset < _maxOffset;
}

- (void)downloadFileToDocumentFolder:(BoxItem *)file
{
    if ([file.type isEqualToString:BoxAPIItemTypeFolder]) return;

    if (!_listOfBoxFilesToDownload)
        _listOfBoxFilesToDownload = [NSMutableArray new];

    [_listOfBoxFilesToDownload addObject:file];

    if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)])
        [self.delegate numberOfFilesWaitingToBeDownloadedChanged];

    [self _triggerNextDownload];
}

- (void)listFilesWithID:(NSString *)folderId
{
    _fileList = nil;
    _folderId = folderId;
    if (_folderId == nil || [_folderId isEqualToString:@""]) {
        _folderId = BoxAPIFolderIDRoot;
    }

    BoxCollectionBlock success = ^(BoxCollection *collection)
    {
        _fileList = collection;
        [self _listOfGoodFilesAndFolders];
    };

    BoxAPIJSONFailureBlock failure = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSDictionary *JSONDictionary)
    {
        NSLog(@"there was an error getting the files but we don't show an error. this request is used to check if we need to refresh the token");
    };

    [_operation cancel];
    _operation = [[BoxSDK sharedSDK].foldersManager folderItemsWithID:_folderId requestBuilder:nil success:success failure:failure];
}

- (void)streamFile:(BoxFile *)file
{
    /* the Box API requires us to set an HTTP header to get the actual URL:
     * curl -L https://api.box.com/2.0/files/FILE_ID/content -H "Authorization: Bearer ACCESS_TOKEN"
     *
     * ... however, libvlc does not support setting custom HTTP headers, so we are resolving the redirect ourselves with a NSURLConnection
     * and pass the final location to libvlc, which does not require a custom HTTP header */

    NSURL *baseURL = [[[BoxSDK sharedSDK] filesManager] URLWithResource:@"files"
                                        ID:file.modelID
                               subresource:@"content"
                                     subID:nil];

    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:baseURL
                                                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                          timeoutInterval:60];

    [urlRequest setValue:[NSString stringWithFormat:@"Bearer %@", [BoxSDK sharedSDK].OAuth2Session.accessToken] forHTTPHeaderField:@"Authorization"];

    NSURLConnection *theTestConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    [theTestConnection start];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if (response != nil) {
        /* we have 1 redirect from the original URL, so as soon as we'd do that,
         * we grab the URL and cancel the connection */
        NSURL *theActualURL = request.URL;

        [connection cancel];

        /* now ask VLC to stream the URL we were just passed */
        VLCAppDelegate *appDelegate = (VLCAppDelegate *)[UIApplication sharedApplication].delegate;
        [appDelegate openMovieFromURL:theActualURL];
    }

    return request;
}

- (void)_triggerNextDownload
{
    if (_listOfBoxFilesToDownload.count > 0 && !_downloadInProgress) {
        [self _reallyDownloadFileToDocumentFolder:_listOfBoxFilesToDownload[0]];
        [_listOfBoxFilesToDownload removeObjectAtIndex:0];

        if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)])
            [self.delegate numberOfFilesWaitingToBeDownloadedChanged];
    }
}

- (void)_reallyDownloadFileToDocumentFolder:(BoxFile *)file
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [searchPaths[0] stringByAppendingFormat:@"/%@", file.name];

    [self loadFile:file intoPath:filePath];

    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStarted)])
        [self.delegate operationWithProgressInformationStarted];

    _downloadInProgress = YES;
}

- (BOOL)_supportedFileExtension:(NSString *)filename
{
    if ([filename isSupportedMediaFormat] || [filename isSupportedAudioMediaFormat] || [filename isSupportedSubtitleFormat])
        return YES;

    return NO;
}

//just pick out Directories and supported formats.
//if the resulting list contains less than 10 items try to get more

- (void)_listOfGoodFilesAndFolders
{
    NSMutableArray *listOfGoodFilesAndFolders = [NSMutableArray new];
    _maxOffset = _fileList.totalCount.intValue;
    _offset += _fileList.numberOfEntries;
    NSUInteger numberOfEntries = _fileList.numberOfEntries;
    for (int i = 0; i < numberOfEntries; i++)
    {
        BoxModel *boxFile = [_fileList modelAtIndex:i];
        BOOL isDirectory = [boxFile.type isEqualToString:BoxAPIItemTypeFolder];
        BOOL supportedFile = NO;
        if (!isDirectory) {
            BoxFile * file = (BoxFile *)boxFile;
            supportedFile = [self _supportedFileExtension:[NSString stringWithFormat:@".%@",file.name.lastPathComponent]];
        }

       if (isDirectory || supportedFile)
            [listOfGoodFilesAndFolders addObject:boxFile];
    }
    _currentFileList = [_currentFileList count] ? [_currentFileList arrayByAddingObjectsFromArray:listOfGoodFilesAndFolders] : [NSArray arrayWithArray:listOfGoodFilesAndFolders];

    if ([_currentFileList count] <= 10 && [self hasMoreFiles]) {
        [self listFilesWithID:_folderId];
        return;
    }

    APLog(@"found filtered metadata for %lu files", (unsigned long)_currentFileList.count);

    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
        [self.delegate mediaListUpdated];
}

- (void)loadFile:(BoxFile *)file intoPath:(NSString*)destinationPath
{
    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:destinationPath append:NO];
    _startDL = [NSDate timeIntervalSinceReferenceDate];
    BoxDownloadSuccessBlock successBlock = ^(NSString *downloadedFileID, long long expectedContentLength)
    {
        [self downloadSuccessful];
    };

    BoxDownloadFailureBlock failureBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)
    {
        [self showAlert:NSLocalizedString(@"GDRIVE_ERROR_DOWNLOADING_FILE_TITLE",nil) message:NSLocalizedString(@"GDRIVE_ERROR_DOWNLOADING_FILE",nil)];
        [self downloadFailedWithError:error];
    };

    BoxAPIDataProgressBlock progressBlock = ^(long long expectedTotalBytes, unsigned long long bytesReceived)
    {
        if ((_lastStatsUpdate > 0 && ([NSDate timeIntervalSinceReferenceDate] - _lastStatsUpdate > .5)) || _lastStatsUpdate <= 0) {
            [self calculateRemainingTime:(CGFloat)bytesReceived expectedDownloadSize:(CGFloat)expectedTotalBytes];
            _lastStatsUpdate = [NSDate timeIntervalSinceReferenceDate];
        }

        CGFloat progress = (CGFloat)bytesReceived / (CGFloat)expectedTotalBytes;
        if ([self.delegate respondsToSelector:@selector(currentProgressInformation:)])
            [self.delegate currentProgressInformation:progress];
    };

    [[BoxSDK sharedSDK].filesManager downloadFileWithID:file.modelID outputStream:outputStream requestBuilder:nil success:successBlock failure:failureBlock progress:progressBlock];
}

- (void)calculateRemainingTime:(CGFloat)receivedDataSize expectedDownloadSize:(CGFloat)expectedDownloadSize
{
    CGFloat lastSpeed = receivedDataSize / ([NSDate timeIntervalSinceReferenceDate] - _startDL);
    CGFloat smoothingFactor = 0.005;
    _averageSpeed = isnan(_averageSpeed) ? lastSpeed : smoothingFactor * lastSpeed + (1 - smoothingFactor) * _averageSpeed;

    CGFloat remainingInSeconds = (expectedDownloadSize - receivedDataSize) / _averageSpeed;

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:remainingInSeconds];
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    NSString *remainingTime = [formatter stringFromDate:date];
    if ([self.delegate respondsToSelector:@selector(updateRemainingTime:)])
        [self.delegate updateRemainingTime:remainingTime];
}

- (void)downloadSuccessful
{
    /* update library now that we got a file */
    APLog(@"BoxFile download was successful");
    VLCAppDelegate *appDelegate = (VLCAppDelegate *) [UIApplication sharedApplication].delegate;
    [appDelegate performSelectorOnMainThread:@selector(updateMediaList) withObject:nil waitUntilDone:NO];

    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStopped)])
        [self.delegate operationWithProgressInformationStopped];
    _downloadInProgress = NO;

    [self _triggerNextDownload];
}

- (void)downloadFailedWithError:(NSError*)error
{
    APLog(@"BoxFile download failed with error %li", (long)error.code);
    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStopped)])
        [self.delegate operationWithProgressInformationStopped];
    _downloadInProgress = NO;

    [self _triggerNextDownload];
}

#pragma mark - VLC internal communication and delegate

- (NSArray *)currentListFiles
{
    return _currentFileList;
}

- (NSInteger)numberOfFilesWaitingToBeDownloaded
{
    if (_listOfBoxFilesToDownload)
        return _listOfBoxFilesToDownload.count;

    return 0;
}

@end
