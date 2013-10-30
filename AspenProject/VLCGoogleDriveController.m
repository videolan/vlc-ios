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
#import "VLCGoogleDriveConstants.h"

static NSString *const kKeychainItemName = @"Google Drive Quickstart #2";

@interface VLCGoogleDriveController ()
{
    GTLDriveFileList *_fileList;
    NSError *_fileListFetchError;
    GTLServiceTicket *_fileListTicket;
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

- (void)downloadFileToDocumentFolder:(DBMetadata *)file
{
    if (!file.isDirectory) {
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

    // maxResults specifies the number of results per page.  Since we earlier
    // specified shouldFetchNextPages=YES, all results should be fetched,
    // though specifying a larger maxResults will reduce the number of fetches
    // needed to retrieve all pages.
    query.maxResults = 150;

    // The Drive API's file entries are chock full of data that the app may not
    // care about. Specifying the fields we want here reduces the network
    // bandwidth and memory needed for the collection.
    //
    // For example, leave query.fields as nil during development.
    // When ready to test and optimize your app, specify just the fields needed.
    // For example, this sample app might use
    //
    // query.fields = @"kind,etag,items(id,downloadUrl,editable,etag,exportLinks,kind,labels,originalFilename,title)";
    //TODO:specify query.fields 

    _fileListTicket = [service executeQuery:query
                          completionHandler:^(GTLServiceTicket *ticket,
                                              GTLDriveFileList *fileList,
                                              NSError *error) {
                              // Callback
                              _fileList = fileList;
                              
                              _fileListFetchError = error;
                              _fileListTicket = nil;
                              [self listOfGoodFiles];
                          }];

  //  [self updateUI];
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

- (void)_reallyDownloadFileToDocumentFolder:(DBMetadata *)file
{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [searchPaths[0] stringByAppendingFormat:@"/%@", file.filename];

    //[[self restClient] loadFile:file.path intoPath:filePath];

    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStarted)])
        [self.delegate operationWithProgressInformationStarted];

    _downloadInProgress = YES;
}

#pragma mark - restClient delegate
- (BOOL)_supportedFileExtension:(NSString *)filename
{
    if ([filename isSupportedMediaFormat] || [filename isSupportedAudioMediaFormat] || [filename isSupportedSubtitleFormat])
        return YES;

    return NO;
}

- (void)listOfGoodFiles
{
    NSMutableArray *listOfGoodFilesAndFolders = [[NSMutableArray alloc] init];
    
    for (GTLDriveFile *driveFile in _fileList.items)
    {
        BOOL isDirectory = [driveFile.mimeType isEqualToString:@"application/vnd.google-apps.folder"];
        if (isDirectory || [self _supportedFileExtension:driveFile.fileExtension]) {
             [listOfGoodFilesAndFolders addObject:driveFile];
        }
    }

    _currentFileList = [NSArray arrayWithArray:listOfGoodFilesAndFolders];

    APLog(@"found filtered metadata for %i files", _currentFileList.count);
    if ([self.delegate respondsToSelector:@selector(mediaListUpdated)])
        [self.delegate mediaListUpdated];
}

//- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
//{
//    APLog(@"DBMetadata download failed with error %i", error.code);
//}
//
//- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath
//{
//    /* update library now that we got a file */
//    VLCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
//    [appDelegate updateMediaList];
//
//    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStopped)])
//        [self.delegate operationWithProgressInformationStopped];
//    _downloadInProgress = NO;
//
//    [self _triggerNextDownload];
//}
//
//- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
//{
//    APLog(@"DBFile download failed with error %i", error.code);
//    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStopped)])
//        [self.delegate operationWithProgressInformationStopped];
//    _downloadInProgress = NO;
//
//    [self _triggerNextDownload];
//}
//
//- (void)restClient:(DBRestClient*)client loadProgress:(CGFloat)progress forFile:(NSString*)destPath
//{
//    if ([self.delegate respondsToSelector:@selector(currentProgressInformation:)])
//        [self.delegate currentProgressInformation:progress];
//}
//
//#pragma mark - DBSession delegate
//
//- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId
//{
//    APLog(@"DriveSession received authorization failure with user ID %@", userId);
//}
//
//#pragma mark - DBNetworkRequest delegate
//- (void)networkRequestStarted
//{
//    _outstandingNetworkRequests++;
//    if (_outstandingNetworkRequests == 1) {
//        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
//        [(VLCAppDelegate*)[UIApplication sharedApplication].delegate disableIdleTimer];
//    }
//}

- (void)networkRequestStopped
{
    _outstandingNetworkRequests--;
    if (_outstandingNetworkRequests == 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [(VLCAppDelegate*)[UIApplication sharedApplication].delegate activateIdleTimer];
    }
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
