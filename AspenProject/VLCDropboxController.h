//
//  VLCDropboxController.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 23.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//

#import <DropboxSDK/DropboxSDK.h>

@protocol VLCDropboxController
@required
- (void)mediaListUpdated;

@optional
- (void)operationWithProgressInformationStarted;
- (void)currentProgressInformation:(float)progress;
- (void)operationWithProgressInformationStopped;

- (void)numberOfFilesWaitingToBeDownloadedChanged;
@end

@interface VLCDropboxController : NSObject <DBRestClientDelegate, DBSessionDelegate, DBNetworkRequestDelegate>

@property (nonatomic, retain) id delegate;
@property (nonatomic, readonly) NSArray *currentListFiles;
@property (nonatomic, readonly) BOOL sessionIsLinked;
@property (nonatomic, readonly) NSInteger numberOfFilesWaitingToBeDownloaded;

- (void)startSession;
- (void)logout;

- (void)requestDirectoryListingAtPath:(NSString *)path;
- (void)downloadFileToDocumentFolder:(DBMetadata *)file;

@end
