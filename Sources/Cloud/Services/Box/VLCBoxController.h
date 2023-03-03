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
#import "VLCCloudStorageController.h"
#import "VLCBoxConstants.h"

#define VLCBoxControllerSessionUpdated @"VLCBoxControllerSessionUpdated"

@interface VLCBoxController : VLCCloudStorageController

- (void)stopSession;
- (BOOL)hasMoreFiles;
#if TARGET_OS_IOS
- (void)downloadFileToDocumentFolder:(BoxFile *)file;
#endif
- (void)getFolderInformation;

@end
