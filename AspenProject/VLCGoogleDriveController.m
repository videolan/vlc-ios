//
//  VLCGoogleDriveController.m
//  VLC for iOS
//
//  Created by Carola Nitz on 21.09.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import "VLCGoogleDriveController.h"
#import "NSString+SupportedMedia.h"
#import "VLCAppDelegate.h"
#import "HTTPMessage.h"

@interface VLCGoogleDriveController ()
{
    GTLDriveFileList *_fileList;
    GTLServiceTicket *_fileListTicket;
    NSError *_fileListFetchError;

    NSArray *_currentFileList;

    NSMutableArray *_listOfGoogleDriveFilesToDownload;
    BOOL _downloadInProgress;

    NSInteger _outstandingNetworkRequests;
}

@end

@implementation VLCGoogleDriveController

#pragma mark - session handling

- (void)startSession
{
    self.driveService = [[GTLServiceDrive alloc] init];
    self.driveService.authorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName clientID:kVLCGoogleDriveClientID clientSecret:kVLCGoogleDriveClientSecret];
}

- (void)logout
{
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
    self.driveService.authorizer = nil;
}

- (BOOL)isAuthorized
{
    return [((GTMOAuth2Authentication *)self.driveService.authorizer) canAuthorize];;
}

- (void)showAlert:(NSString *)title message:(NSString *)message
{
    UIAlertView *alert;
    alert = [[UIAlertView alloc] initWithTitle: title
                                       message: message
                                      delegate: nil
                             cancelButtonTitle: @"OK"
                             otherButtonTitles: nil];
    [alert show];
}

#pragma mark - file management
- (void)requestDirectoryListingAtPath:(NSString *)path
{
    if (self.isAuthorized)
        [self listFiles];
}

- (void)downloadFileToDocumentFolder:(GTLDriveFile *)file
{
    if (![file.mimeType isEqualToString:@"application/vnd.google-apps.folder"]) {
        if (!_listOfGoogleDriveFilesToDownload)
            _listOfGoogleDriveFilesToDownload = [[NSMutableArray alloc] init];
        [_listOfGoogleDriveFilesToDownload addObject:file];

        if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)])
            [self.delegate numberOfFilesWaitingToBeDownloadedChanged];

        [self _triggerNextDownload];
    }
}

- (void)listFiles
{
    _fileList = nil;
    _fileListFetchError = nil;

    GTLServiceDrive *service = self.driveService;

    GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];
    query.maxResults = 150;

    query.fields = @"items(originalFilename,title,mimeType,fileExtension,fileSize,iconLink)";
    //+ (id)queryForChildrenListWithFolderId:(NSString *)folderId;

    _fileListTicket = [service executeQuery:query
                          completionHandler:^(GTLServiceTicket *ticket,
                                              GTLDriveFileList *fileList,
                                              NSError *error) {
                              // Callback
                              _fileList = fileList;
                              
                              _fileListFetchError = error;
                              _fileListTicket = nil;
                              [self listOfGoodFilesAndFolders];
                          }];
}

- (void)_triggerNextDownload
{
    if (_listOfGoogleDriveFilesToDownload.count > 0 && !_downloadInProgress) {
        [self _reallyDownloadFileToDocumentFolder:_listOfGoogleDriveFilesToDownload[0]];
        [_listOfGoogleDriveFilesToDownload removeObjectAtIndex:0];

        if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)])
            [self.delegate numberOfFilesWaitingToBeDownloadedChanged];
    }
}

- (void)_reallyDownloadFileToDocumentFolder:(GTLDriveFile *)file
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [searchPaths[0] stringByAppendingFormat:@"/%@", file.originalFilename];

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

- (void)listOfGoodFilesAndFolders
{
    NSMutableArray *listOfGoodFilesAndFolders = [[NSMutableArray alloc] init];
    
    for (GTLDriveFile *driveFile in _fileList.items)
    {
        BOOL isDirectory = [driveFile.mimeType isEqualToString:@"application/vnd.google-apps.folder"];
        if (isDirectory || [self _supportedFileExtension:[NSString stringWithFormat:@".%@",driveFile.fileExtension ]]) {
            [listOfGoodFilesAndFolders addObject:driveFile];
        }
    }

    _currentFileList = [NSArray arrayWithArray:listOfGoodFilesAndFolders];

    APLog(@"found filtered metadata for %i files", _currentFileList.count);
    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
        [self.delegate mediaListUpdated];
}

- (void)loadFile:(GTLDriveFile*)file intoPath:(NSString*)destinationPath
{

    NSString *exportURLStr = file.downloadUrl;

    if ([exportURLStr length] > 0) {
        NSString *suggestedName = file.originalFilename;
        if ([suggestedName length] == 0) {
            suggestedName = file.title;
        }

        NSURL *url = [NSURL URLWithString:exportURLStr];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];

        // Requests of user data from Google services must be authorized.
        fetcher.authorizer = self.driveService.authorizer;

        // The fetcher can save data directly to a file.
        fetcher.downloadPath = destinationPath;

        // Fetcher logging can include comments.
        [fetcher setCommentWithFormat:@"Downloading \"%@\"", file.title];

        __weak GTMHTTPFetcher *weakFetcher = fetcher;

        fetcher.receivedDataBlock = ^(NSData *receivedData) {
            float progress = (float)weakFetcher.downloadedLength / (float)[file.fileSize longLongValue];

            if ([self.delegate respondsToSelector:@selector(currentProgressInformation:)])
                [self.delegate currentProgressInformation:progress];
        };

        [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
            // Callback
            //TODO:localize Strings
            if (error == nil) {
                UIAlertView *alert;
                alert = [[UIAlertView alloc] initWithTitle: @"Downloaded"
                                                   message: @"your file has been sucessfully downloaded"
                                                  delegate: nil
                                         cancelButtonTitle: @"OK"
                                         otherButtonTitles: nil];
                [alert show];
                [self downloadSucessfull];
            } else {
                UIAlertView *alert;
                alert = [[UIAlertView alloc] initWithTitle: @"Error"
                                                   message: @"AN Error occured while downloading"
                                                  delegate: nil
                                         cancelButtonTitle: @"OK"
                                         otherButtonTitles: nil];
                [alert show];
                [self downloadFailedWithError:error];
            }
        }];
    }
}

- (void)downloadSucessfull
{
    /* update library now that we got a file */
    APLog(@"DriveFile download was sucessful");
    VLCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate updateMediaList];

    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStopped)])
        [self.delegate operationWithProgressInformationStopped];
    _downloadInProgress = NO;

    [self _triggerNextDownload];
}

- (void)downloadFailedWithError:(NSError*)error
{
    APLog(@"DriveFile download failed with error %i", error.code);
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
    if (_listOfGoogleDriveFilesToDownload)
        return _listOfGoogleDriveFilesToDownload.count;

    return 0;
}

@end
