/*****************************************************************************
 * VLCBoxController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <BoxSDK/BoxSDK.h>
#import "VLCBoxConstants.h"

@protocol VLCBoxController <NSObject>
@required
- (void)mediaListUpdated;

@optional
- (void)operationWithProgressInformationStarted;
- (void)currentProgressInformation:(CGFloat)progress;
- (void)updateRemainingTime:(NSString *)time;
- (void)operationWithProgressInformationStopped;
- (void)numberOfFilesWaitingToBeDownloadedChanged;
@end

@interface VLCBoxController : NSObject

@property (nonatomic, weak) id<VLCBoxController> delegate;
@property (nonatomic, readonly) NSArray *currentListFiles;
@property (nonatomic, readwrite) BOOL isAuthorized;

+ (VLCBoxController *)sharedInstance;
- (void)startSession;
- (void)stopSession;
- (void)logout;
- (void)requestDirectoryListingWithFolderId:(NSString *)folderId;
- (BOOL)hasMoreFiles;
- (void)streamFile:(BoxFile *)file;
- (void)downloadFileToDocumentFolder:(BoxFile *)file;

@end
