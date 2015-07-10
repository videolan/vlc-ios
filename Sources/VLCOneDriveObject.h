/*****************************************************************************
 * VLCOneDriveObject.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "LiveConnectClient.h"

@class VLCOneDriveObject;

@protocol VLCOneDriveObjectDelegate <NSObject>

- (void)folderContentLoaded:(VLCOneDriveObject *)sender;

- (void)fullFolderTreeLoaded:(VLCOneDriveObject *)sender;

- (void)folderContentLoadingFailed:(NSError *)error
                            sender:(VLCOneDriveObject *) sender;
@end

@protocol VLCOneDriveObjectDownloadDelegate <NSObject>

- (void)downloadStarted:(VLCOneDriveObject *)object;
- (void)downloadEnded:(VLCOneDriveObject *)object;
- (void)progressUpdated:(CGFloat)progress;
- (void)calculateRemainingTime:(CGFloat)receivedDataSize expectedDownloadSize:(CGFloat)expectedDownloadSize;
@end

@interface VLCOneDriveObject : NSObject <LiveOperationDelegate, LiveDownloadOperationDelegate, VLCOneDriveObjectDelegate>

@property (strong, nonatomic) VLCOneDriveObject *parent;
@property (strong, nonatomic) NSString *objectId;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSNumber *size;
@property (strong, nonatomic) NSNumber *duration;
@property (strong, nonatomic) NSString *thumbnailURL;
@property (readonly, nonatomic) BOOL isFolder;
@property (readonly, nonatomic) BOOL isVideo;
@property (readonly, nonatomic) BOOL isAudio;

@property (strong, nonatomic) NSArray *folders;
@property (strong, nonatomic) NSArray *files;
@property (strong, nonatomic) NSArray *items;

@property (readonly, nonatomic) NSString *filesPath;
@property (strong, nonatomic) NSString *downloadPath;
@property (readonly, nonatomic) BOOL hasFullFolderTree;

@property (strong, nonatomic) LiveConnectClient *liveClient;
@property (strong, nonatomic) id<VLCOneDriveObjectDelegate>delegate;
@property (strong, nonatomic) id<VLCOneDriveObjectDownloadDelegate>downloadDelegate;

- (void)loadFolderContent;
- (void)saveObjectToDocuments;

@end
