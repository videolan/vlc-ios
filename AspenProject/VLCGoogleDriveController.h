//
//  VLCGoogleDriveController.h
//  VLC for iOS
//
//  Created by Carola Nitz on 21.09.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//
//  Refer to the COPYING file of the official project for license.
//
#import "GTLDrive.h"

@protocol VLCGoogleDriveController
@required
- (void)mediaListUpdated;

@optional
- (void)operationWithProgressInformationStarted;
- (void)currentProgressInformation:(float)progress;
- (void)operationWithProgressInformationStopped;
- (void)numberOfFilesWaitingToBeDownloadedChanged;
@end

@interface VLCGoogleDriveController : NSObject

@property (nonatomic, retain) id delegate;
@property (nonatomic, readonly) NSArray *currentListFiles;
@property (nonatomic, readwrite) BOOL isAuthorized;
@property (nonatomic, readonly) NSInteger numberOfFilesWaitingToBeDownloaded;
@property (nonatomic, retain) GTLServiceDrive *driveService;

- (void)startSession;
- (void)logout;
- (void)requestDirectoryListingAtPath:(NSString *)path;
//- (void)downloadFileToDocumentFolder:(DBMetadata *)file;

@end
