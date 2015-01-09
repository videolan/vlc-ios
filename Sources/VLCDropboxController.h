/*****************************************************************************
 * VLCDropboxController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <DropboxSDK/DropboxSDK.h>
#import "VLCCloudStorageController.h"

@interface VLCDropboxController : VLCCloudStorageController <DBRestClientDelegate, DBSessionDelegate, DBNetworkRequestDelegate>

@property (nonatomic, readonly) NSInteger numberOfFilesWaitingToBeDownloaded;

- (void)downloadFileToDocumentFolder:(DBMetadata *)file;
- (void)streamFile:(DBMetadata *)file;

@end
