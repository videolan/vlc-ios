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

#if TARGET_OS_IOS
#import <DropboxSDK/DropboxSDK.h>
#else
#import <DropboxTVSDK/DropboxSDK.h>
#endif
#import "VLCCloudStorageController.h"

@interface VLCDropboxController : VLCCloudStorageController <DBRestClientDelegate, DBSessionDelegate, DBNetworkRequestDelegate>

@property (nonatomic, readonly) NSInteger numberOfFilesWaitingToBeDownloaded;

+ (instancetype)sharedInstance;

- (void)shareCredentials;
- (BOOL)restoreFromSharedCredentials;

- (void)downloadFileToDocumentFolder:(DBMetadata *)file;
- (void)streamFile:(DBMetadata *)file currentNavigationController:(UINavigationController *)navigationController;

- (void)reset;

@end
