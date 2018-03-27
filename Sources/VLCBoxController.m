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
#import "VLCPlaybackController.h"
#import "VLCMediaFileDiscoverer.h"
#import <XKKeychain/XKKeychainGenericPasswordItem.h>

@interface VLCBoxController ()
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
        sharedInstance = [VLCBoxController new];
    });

    return sharedInstance;
}

- (void)startSession
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(boxApiTokenDidRefresh)
                          name:BoxOAuth2SessionDidRefreshTokensNotification
                        object:[BoxSDK sharedSDK].OAuth2Session];

    [defaultCenter addObserver:self
                      selector:@selector(boxApiTokenDidRefresh)
                          name:BoxOAuth2SessionDidBecomeAuthenticatedNotification
                        object:[BoxSDK sharedSDK].OAuth2Session];

    [BoxSDK sharedSDK].OAuth2Session.clientID = kVLCBoxClientID;
    [BoxSDK sharedSDK].OAuth2Session.clientSecret = kVLCBoxClientSecret;

    NSString *token = [XKKeychainGenericPasswordItem itemForService:kVLCBoxService account:kVLCBoxAccount error:nil].secret.stringValue;
    if (!token) {
        NSUbiquitousKeyValueStore *ubiquitousStore = [NSUbiquitousKeyValueStore defaultStore];
        [ubiquitousStore synchronize];
        token = [ubiquitousStore stringForKey:kVLCStoreBoxCredentials];
    }
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
    XKKeychainGenericPasswordItem *keychainItem = [[XKKeychainGenericPasswordItem alloc] init];
    keychainItem.service = kVLCBoxService;
    keychainItem.account = kVLCBoxAccount;
    [keychainItem deleteWithError:nil];

    [[BoxSDK sharedSDK].OAuth2Session logout];
    NSUbiquitousKeyValueStore *ubiquitousStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousStore setString:nil forKey:kVLCStoreBoxCredentials];
    [ubiquitousStore synchronize];
    [self stopSession];
    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
        [self.delegate mediaListUpdated];
}

- (void)boxApiTokenDidRefresh
{
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCBoxControllerSessionUpdated object:nil];
}

- (BOOL)isAuthorized
{
    return [[BoxSDK sharedSDK].OAuth2Session isAuthorized];
}

#pragma mark - file management

- (BOOL)canPlayAll
{
    return NO;
}

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
        APLog(@"there was an error getting the files but we don't show an error. this request is used to check if we need to refresh the token");
    };

    [_operation cancel];
    _operation = [[BoxSDK sharedSDK].foldersManager folderItemsWithID:_folderId requestBuilder:nil success:success failure:failure];
}

#if TARGET_OS_IOS

- (void)downloadFileToDocumentFolder:(BoxItem *)file
{
    if (file != nil) {
        if ([file.type isEqualToString:BoxAPIItemTypeFolder]) return;

        if (!_listOfBoxFilesToDownload)
            _listOfBoxFilesToDownload = [NSMutableArray new];

        [_listOfBoxFilesToDownload addObject:file];
    }

    if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)])
        [self.delegate numberOfFilesWaitingToBeDownloadedChanged];

    [self _triggerNextDownload];
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
#endif

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
            supportedFile = [[NSString stringWithFormat:@".%@",file.name.lastPathComponent] isSupportedFormat];
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

#if TARGET_OS_IOS
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

- (void)showAlert:(NSString *)title message:(NSString *)message
{
    VLCAlertView *alert = [[VLCAlertView alloc] initWithTitle:title
                                                      message:message
                                                     delegate:nil
                                            cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                            otherButtonTitles:nil];
    [alert show];
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
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"GDRIVE_DOWNLOAD_SUCCESSFUL", nil));
    [[VLCMediaFileDiscoverer sharedInstance] performSelectorOnMainThread:@selector(updateMediaList) withObject:nil waitUntilDone:NO];

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
#endif

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
