/*****************************************************************************
 * VLCDropboxController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCCloudStorageController.h"
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

NS_ASSUME_NONNULL_BEGIN

@interface VLCDropboxController : VLCCloudStorageController

@property (nonatomic, readonly) NSInteger numberOfFilesWaitingToBeDownloaded;

+ (instancetype)sharedInstance;

- (void)shareCredentials;
- (BOOL)restoreFromSharedCredentials;

- (void)downloadFileToDocumentFolder:(DBFILESMetadata *)file;
- (void)downloadFolderFiles:(DBFILESFolderMetadata *)folder;
- (void)streamFile:(DBFILESMetadata *)file currentNavigationController:(UINavigationController *)navigationController;

- (void)loadThumbnailForFile:(DBFILESFileMetadata *)file completion:(void (^)(UIImage * _Nullable image))completion;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
